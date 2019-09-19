local audio = require 'audio'
local input = require 'input'
local ecs = require 'ecs/ecs'
require 'ecs/utils'
local buff = require 'mech/buff'
local fsm = require 'fsm'

local PLAYER_VEL = 96
local PLAYER_BULLET_VEL = 160
local PLAYER_ACCEL = 768
local PLAYER_DECEL = 384

local keys = function (a, b)
    local result = 0
    if a then result = result + 1 end
    if b then result = result - 1 end
    return result
end

local updateVel = function (orig, tx, ty)
    local DV = (tx == 0 and ty == 0 and PLAYER_DECEL or PLAYER_ACCEL) * DT
    local dx, dy = tx - orig[1], ty - orig[2]
    local dsq = dx * dx + dy * dy
    if dsq <= DV * DV then
        orig[1], orig[2] = tx, ty
    else
        local dinv = DV / math.sqrt(dsq)
        orig[1] = orig[1] + dx * dinv
        orig[2] = orig[2] + dy * dinv
    end
end

local nearest = function (e, v, es)
    local K = 0.3   -- 'Compression' factor
    local R = 128   -- Visibile range
    local cx, cy =
        e.dim[1] + e.dim[3] * 0.5,
        e.dim[2] + e.dim[4] * 0.5
    local vx, vy = e.vel[1], e.vel[2]
    local still
    local vsq = vx * vx + vy * vy
    if vsq <= 1e-5 then
        vx, vy = v[1], v[2]
        still = true
    else
        local vinv = 1 / math.sqrt(vsq)
        vx, vy = vx * vinv, vy * vinv
        v[1], v[2] = vx, vy
    end
    -- Find the closest enemy biased towards ones that the player is facing
    local best, ret = R * R, nil
    for _, t in ipairs(es) do
        local tx, ty =
            t.dim[1] + t.dim[3] * 0.5,
            t.dim[2] + t.dim[4] * 0.5
        local dx, dy = tx - cx, ty - cy
        -- Project d onto v
        local p = dx * vx + dy * vy
        if p > 1e-5 then
            local psq = p * p
            local d2sq = dx * dx + dy * dy + (K * K - 1) * psq
            if d2sq < best then best, ret = d2sq, t end
        end
    end
    -- Reorient onto the nearest enemy and update the facing direction,
    -- if the player stands still and does not find an enemy in range
    if still and ret == nil then
        for _, t in ipairs(es) do
            local tx, ty =
                t.dim[1] + t.dim[3] * 0.5,
                t.dim[2] + t.dim[4] * 0.5
            local dx, dy = tx - cx, ty - cy
            local dsq = dx * dx + dy * dy
            if dsq < best then
                best, ret = dsq, t
                vx, vy = dx, dy
            end
        end
        if best ~= nil then
            local factor = 1 / math.sqrt(vx * vx + vy * vy)
            v[1], v[2] = vx * factor, vy * factor
        end
    end
    return ret
end

return function () return {

lastDownX = false,
lastDownA = false,
lastValidVel = {1, 0},
shootDir = {1, 0},
update = function (self, cs)
    for _, e in pairs(cs.player) do
        local p = e.player

        -- State machine
        if p.fsm == nil then
            -- 1: aka
            -- 2: ookami
            -- 3: death
            p.fsm = fsm.create({
                akaShoot = {1, 40},
                akaHit = {1, 40},
                akaShift = {2, 40},
                ookamiShoot = {2, 40},
                ookamiHit = {2, 40},
                ookamiShift = {1, 40}
            })
        end

        -- Invincibility update
        p.invincibility = math.max(0, (p.invincibility or 0) - 1)

        -- Magazine?
        local hasMagazine = p.buff.magazine and p.buff.magazine.equipped
        p.energyMax = (hasMagazine and 150 or 100)
        p.energy = math.min(p.energy, p.energyMax)

        local horz = keys(input.R(), input.L())
        local vert = keys(input.D(), input.U())
        if horz ~= 0 and vert ~= 0 then
            horz = horz / 1.414213562
            vert = vert / 1.414213562
        end
        updateVel(e.vel, horz * PLAYER_VEL, vert * PLAYER_VEL)

        local downX = input.X()
        local sinceLastShoot
        local hasMachGun = (p.buff.machgun and p.buff.machgun.equipped)
        if hasMachGun then
            sinceLastShoot = (p.sinceLastShoot or 0) + 1
        end

        local target = nearest(e, self.lastValidVel, cs.enemy or {})
        local dx, dy    -- Aiming direction
        if target ~= nil then
            dx, dy = targetVec(e.dim, target.dim, 1)
        else
            dx, dy = self.lastValidVel[1] * 1, self.lastValidVel[2] * 1
        end

        local addBullet = function (dx, dy, damage)
            local bullet = {
                dim = {
                    e.dim[1] + e.dim[3] * 0.5 + dx * 4,
                    e.dim[2] + e.dim[4] * 0.5 + dy * 4,
                    4, 4
                },
                vel = { dx * PLAYER_BULLET_VEL, dy * PLAYER_BULLET_VEL },
                sprite = { name = 'quq9' },
                bullet = {
                    mask = 5,
                    age = ((p.buff.incise and p.buff.incise.equipped) and 0 or nil),
                    penetrate = ((p.buff.penetrate and p.buff.penetrate.equipped) and true or nil),
                    damage = damage
                }
            }
            ecs.addEntity(bullet)
        end

        -- Charging
        if p.buff.stockpile and p.buff.stockpile.equipped then
            local s = audio.get('charge')
            if downX then
                local cost = 0.25
                if p.energy >= cost then
                    p.energy = p.energy - cost
                    p.charge = (p.charge or 0) + 1
                end
                if not s:isPlaying() then s:play()
                elseif s:tell() >= 5 then s:seek(2) end
            elseif self.lastDownX then
                -- Release
                addBullet(dx, dy, p.charge * 0.25 * 0.1)
                p.charge = 0
                s:stop()
                audio.play('gunshot' .. tostring(math.random(4)))
            end

        -- Normal attack
        elseif downX and (not self.lastDownX or (hasMachGun and sinceLastShoot >= 30)) then
            -- Turn
            self.shootDir[1], self.shootDir[2] = dx, dy
            -- Try to shoot
            local damage = 1
            local cost = 10
            -- Note: enemies slayed without the buff is also kept
            if p.buff.rage and p.buff.rage.equipped and p.slayed then
                p.slayed = false
                damage = 2
            end
            if hasMachGun then
                damage = damage * 0.5
                cost = cost * 0.5
                sinceLastShoot = 0
            end
            if p.energy >= cost then
                p.energy = p.energy - cost

                addBullet(dx, dy, damage)
                if p.buff.fork and p.buff.fork.equipped then
                    local alpha = math.atan2(dy, dx)
                    addBullet(math.cos(alpha + math.pi / 6), math.sin(alpha + math.pi / 6), damage)
                    addBullet(math.cos(alpha - math.pi / 6), math.sin(alpha - math.pi / 6), damage)
                end

                p.fsm:trans(
                    p.fsm.curState == 1 and 'akaShoot' or 'ookamiShoot',
                    true
                )
                audio.play('gunshot' .. tostring(math.random(4)))
            end
        end
        self.lastDownX = downX
        if hasMachGun then
            p.sinceLastShoot = sinceLastShoot
        end

        local downA = input.A()
        if downA and not self.lastDownA then
            -- SHIFT!
            p.fsm:trans(
                p.fsm.curState == 1 and 'akaShift' or 'ookamiShift'
            )
        end
        self.lastDownA = downA

        p.fsm:step()

        p.colour = p.fsm.curState - 1

        local still = (e.vel[1] * e.vel[1] + e.vel[2] * e.vel[2] <= 1e-5)
        if not still then
            self.shootDir[1], self.shootDir[2] = e.vel[1], e.vel[2]
        end

        -- Animation

        local sprite
        local t = p.fsm.curTrans
        local frame = math.floor((t and p.fsm.curTransStep / 10 or p.fsm.age / 15))

        local char = (p.fsm.curState == 1 and 'aka' or 'ookami')
        local isBack = (self.shootDir[2] < 0)

        if t == 'akaShift' then
            sprite = 'aka2ookami' .. tostring(frame % 4 + 1)
        elseif t == 'ookamiShift' then
            sprite = 'ookami2aka' .. tostring(frame % 4 + 1)
        elseif t == 'akaShoot' or t == 'ookamiShoot' then
            local state, dir
            if still then
                state = 'attacking'
                local x = math.abs(self.shootDir[1]) * 0.3
                dir = (self.shootDir[2] < -x and 'up' or
                    (self.shootDir[2] > x and 'down' or 'left'))
            else
                state = 'runattack'
                dir = (self.shootDir[2] < 0 and 'up' or 'down')
            end
            local len = (not still and dir == 'left') and 8 or 4
            -- Hack!
            sprite = char .. (isBack and '_back_' or '_')
                ..  state .. '_' .. dir .. tostring(frame % len + 1)
        elseif t == 'akaHit' or t == 'ookamiHit' then
            sprite = char .. (isBack and '_back' or '')
                .. '_beattacked' .. tostring(math.floor(frame % 4 / 2) + 1)
        else
            local state = (still and 'waiting' or 'running')

            -- Hack!
            if char == 'ookami' and state == 'waiting' then state = '' end

            sprite = char .. (isBack and '_back' or '')
                .. (state == '' and '' or '_')
                .. state .. tostring(frame % 4 + 1)
        end

        e.sprite.flipX = (self.shootDir[1] >= 0)

        e.sprite.name = sprite
        e.sprite.ox = 11
        e.sprite.oy = 14
    end
end

} end
