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
    if love.keyboard.isDown(a) then result = result + 1 end
    if love.keyboard.isDown(b) then result = result - 1 end
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

lastUDown = false,
lastJDown = false,
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

        local horz = keys('right', 'left')
        local vert = keys('down', 'up')
        if horz ~= 0 and vert ~= 0 then
            horz = horz / 1.414213562
            vert = vert / 1.414213562
        end
        updateVel(e.vel, horz * PLAYER_VEL, vert * PLAYER_VEL)

        local UDown = love.keyboard.isDown('u')
        local target = nearest(e, self.lastValidVel, cs.enemy)
        local dx, dy    -- Aiming direction
        if target ~= nil then
            dx, dy = targetVec(e.dim, target.dim, 1)
        else
            dx, dy = self.lastValidVel[1] * 1, self.lastValidVel[2] * 1
        end
        -- TODO: Support charging
        if UDown and not self.lastUDown then
            -- Turn
            self.shootDir[1], self.shootDir[2] = dx, dy
            -- Try to shoot
            if p.energy >= 10 then
                p.energy = p.energy - 10
                local bullet = {
                    dim = {
                        e.dim[1] + e.dim[3] * 0.5 + dx * 4,
                        e.dim[2] + e.dim[4] * 0.5 + dy * 4,
                        4, 4
                    },
                    vel = { dx * PLAYER_BULLET_VEL, dy * PLAYER_BULLET_VEL },
                    sprite = { name = 'quq9' },
                    bullet = { mask = 5 }
                }
                ecs.addEntity(bullet)
                p.fsm:trans(
                    p.fsm.curState == 1 and 'akaShoot' or 'ookamiShoot',
                    true
                )
            end
        end
        self.lastUDown = UDown

        local JDown = love.keyboard.isDown('j')
        if JDown and not self.lastJDown then
            -- SHIFT!
            p.fsm:trans(
                p.fsm.curState == 1 and 'akaShift' or 'ookamiShift'
            )
        end
        self.lastJDown = JDown

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
