local ecs = require 'ecs/ecs'
require 'ecs/utils'
local fsm = require 'fsm'

local PERIOD = 600
local BULLET_VEL = 60
local BULLET_ACCEL = 960

local patternUpdate = {}

local addBullet = function (e, vx, vy, colour)
    local bullet = {
        dim = {
            e.dim[1] + e.dim[3] * 0.5 + vx * 0.025,
            e.dim[2] + e.dim[4] * 0.5 + vy * 0.025,
            4, 4
        },
        vel = { vx, vy },
        sprite = { name = (colour == 0 and 'quq7' or 'quq8'), z = 1 },
        bullet = { mask = 3, colour = colour },
    }
    ecs.addEntity(bullet)
    --if math.random(2) == 1 then
    --    bullet.follow = { target = ePlayer, vel = BULLET_VEL, accel = BULLET_ACCEL * DT }
    --else bullet.sprite.name = 'quq8'
    --end

    -- Play animation
    if e.enemy.boss and (e.vel[1] * e.vel[1] + e.vel[2] * e.vel[2] >= 10 * 10) then
        e.enemy.fsm:trans('runattack')
    else
        e.enemy.fsm:trans('attack')
    end
end

patternUpdate.none = function (e, ePlayer, phase, dx, dy)
end

patternUpdate.triplet = function (e, ePlayer, phase, dx, dy)
    e.enemy._nextShoot = (e.enemy._nextShoot or 180)
    e.enemy._curWaveColour = (e.enemy._curWaveColour or 0)
    if phase == e.enemy._nextShoot then
        if phase == 180 then
            e.enemy._curWaveColour = (e.enemy._curWaveColour + 1) % 2
        end
        -- Generate a bullet
        addBullet(e, dx * BULLET_VEL, dy * BULLET_VEL, e.enemy.colour or e.enemy._curWaveColour)
        -- 180, 210, 240
        local INTERVAL = 40
        e.enemy._nextShoot = (e.enemy._nextShoot - 180 + INTERVAL) % (INTERVAL * 3) + 180
    end
end

patternUpdate.triad = function (e, ePlayer, phase, dx, dy)
    e.enemy._curWaveColour = (e.enemy._curWaveColour or 0)
    if phase == 180 then
        e.enemy._curWaveColour = (e.enemy._curWaveColour + 1) % 2
        addBullet(e, dx * BULLET_VEL, dy * BULLET_VEL, e.enemy.colour or e.enemy._curWaveColour)
        local alpha = math.atan2(dy, dx)
        addBullet(e,
            BULLET_VEL * math.cos(alpha + math.pi / 6), BULLET_VEL * math.sin(alpha + math.pi / 6),
            e.enemy.colour or e.enemy._curWaveColour)
        addBullet(e,
            BULLET_VEL * math.cos(alpha - math.pi / 6), BULLET_VEL * math.sin(alpha - math.pi / 6),
            e.enemy.colour or e.enemy._curWaveColour)
    end
end

patternUpdate.penta = function (e, ePlayer, phase, dx, dy)
    e.enemy._nextShoot = (e.enemy._nextShoot or 180)
    e.enemy._curColour = (e.enemy._curColour or 0)
    if phase == e.enemy._nextShoot then
        e.enemy._curColour = (e.enemy._curColour + 1) % 2
        addBullet(e, dx * BULLET_VEL, dy * BULLET_VEL, e.enemy.colour or e.enemy._curColour)
        -- 180, 195, 210, 225, 240
        local INTERVAL = 40
        e.enemy._nextShoot = (e.enemy._nextShoot - 180 + INTERVAL) % (INTERVAL * 5) + 180
    end
end

patternUpdate.arp = function (e, ePlayer, phase, dx, dy)
    e.enemy._nextShoot = (e.enemy._nextShoot or 60)
    e.enemy._curWaveColour = (e.enemy._curWaveColour or 0)
    if phase == e.enemy._nextShoot then
        if phase == 0 then
            e.enemy._curWaveColour = (e.enemy._curWaveColour + 1) % 2
        end
        local alpha = -phase * math.pi / 180
        addBullet(e,
            math.sin(alpha) * BULLET_VEL, math.cos(alpha) * BULLET_VEL,
            e.enemy._curWaveColour)
        e.enemy._nextShoot = (e.enemy._nextShoot + 20) % 360
    end
end

patternUpdate.donut = function (e, ePlayer, phase, dx, dy)
    e.enemy._nextShoot = (e.enemy._nextShoot or 180)
    e.enemy._curColour = (e.enemy._curColour or 0)
    if phase == e.enemy._nextShoot then
        if phase == 240 then
            e.enemy._curColour = (e.enemy._curColour + 1) % 2
        end
        for i = 0, 340, 20 do
            local alpha = (i + (phase == 240 and 10 or 0)) * math.pi / 180
            addBullet(e,
                math.sin(alpha) * BULLET_VEL, math.cos(alpha) * BULLET_VEL,
                e.enemy._curColour)
        end
        e.enemy._nextShoot = (e.enemy._nextShoot == 180 and 240 or 180)
    end
end

-- Idle, hit, attack, death, run, runattack
local animations = {
    cola = {4, 2, 0, 2},
    pepsi = {4, 2, 0, 2},
    yeshu = {8, 2, 0, 7},
    colaeli = {7, 2, 7, 4},
    starcoco = {8, 2, 6, 4},
    boss = {8, 2, 8, 6, 6, 6}
}

return function () return {

update = function (self, cs)
    local ePlayer = cs.player[1]
    if ePlayer == nil then return end

    for _, e in pairs(cs.enemy or {}) do
        local n = e.enemy
        local a = animations[n.name]

        if n.fsm == nil then
            -- 1: normal
            -- 2: death
            n.fsm = fsm.create({
                hit = {1, 15 * a[2]},
                attack = {1, 10 * a[3]},
                death = {2, 15 * a[4]},
                runattack = (n.boss and {1, 10 * a[6]} or nil)
            })
        end

        if n.fsm.curState == 2 then
            if n.fsm.curTrans == nil then ecs.removeEntity(e) end
        end

        -- Follow player and repel other enemies
        local dx, dy = targetVecAround(e.dim, ePlayer.dim, 16, 16)
        local vx0, vy0 = e.vel[1], e.vel[2]

        local rx, ry = 0, 0
        cs.dim:colliding(e, function (e2) if e2.enemy then
            local drx, dry = targetVec(e.dim, e2.dim, 6)
            rx, ry = rx + drx, ry + dry
        end end)
        local rsq = rx * rx + ry * ry
        if rsq > 36 then
            local factor = 6 / math.sqrt(rsq)
            rx, ry = rx * factor, ry * factor
        end
        local dx2, dy2 = dx - rx, dy - ry

        -- Bullets
        -- Done before velocity update to take actual (blocked) velocity into account
        local ph = (e.enemy.phase or 0)
        ph = (ph + 1) % PERIOD
        e.enemy.phase = ph
        local dsq = dx * dx + dy * dy
        if dsq <= 1e-5 then
            dx, dy = 1, 0
        else
            local factor = 1 / math.sqrt(dsq)
            dx, dy = dx * factor, dy * factor
        end
        patternUpdate[e.enemy.pattern](e, ePlayer, ph, dx, dy)

        -- Velocity update
        if n.fsm.curState ~= 2 then
            e.vel[1], e.vel[2] = dx2, dy2
        else
            e.vel[1], e.vel[2] = 0, 0
        end

        n.fsm:step()
        n.lastFlipDur = (n.lastFlipDur or 400) + 1
        n.lastDirDur = (n.lastDirDur or 400) + 1

        local sprite, spriteFace
        local t = n.fsm.curTrans
        local frame = math.floor(
            t and n.fsm.curTransStep / ((t == 'attack' or t == 'runattack') and 10 or 15)
              or n.fsm.age / 15
        )

        local isMinion = (n.name == 'cola' or n.name == 'pepsi')
        local isRightward = (e.vel[1] > 0)
        local flipSprite = not isMinion

        if t == 'hit' then
            sprite = n.name .. '_beattacked' .. tostring(frame % a[2] + 1)
            flipSprite = true
        elseif t == 'death' then
            sprite = n.name .. '_dead' .. tostring(frame % a[4] + 1)
        elseif t == 'attack' then
            if n.boss then
                local dir = (math.abs(dx2) < math.abs(dy2) * 0.3 and 'front' or 'left')
                if dir ~= n.lastDir and (n.lastDirDur >= 60 or n.lastDir == 'right') then
                    n.lastDir = dir
                    n.lastDirDur = 0
                end
                sprite = n.name .. '_attacking_' .. n.lastDir .. tostring(frame % a[3] + 1)
            else
                sprite = n.name .. '_attacking' .. tostring(frame % a[3] + 1)
            end
        elseif t == 'runattack' then
            -- Boss exclusive
            local y = math.abs(dy2) * 0.3
            -- XXX: Duplication!!!
            local dir = (dx2 < -y and 'left' or (dx2 > y and 'right' or 'front'))
            if dir ~= n.lastDir and n.lastDirDur >= 60 then
                n.lastDir = dir
                n.lastDirDur = 0
            end
            sprite = n.name .. '_runattack_' .. n.lastDir .. tostring(frame % a[6] + 1)
            -- Do not flip the sprite in case of rightward movement
            if dx2 > y then isRightward = false end
        else
            if n.boss and vx0 * vx0 + vy0 * vy0 > 4 * 4 then
                local y = math.abs(dy2) * 0.3
                local dir = (dx2 < -y and 'left' or (dx2 > y and 'right' or 'front'))
                if dir ~= n.lastDir and n.lastDirDur >= 60 then
                    n.lastDir = dir
                    n.lastDirDur = 0
                end
                sprite = n.name .. '_running_' .. n.lastDir .. tostring(frame % a[5] + 1)
                if dx2 > y then isRightward = false end
            else
                sprite = n.name .. '_waiting' .. tostring(frame % a[1] + 1)
            end
        end

        if isMinion then
            spriteFace = sprite:sub(1, -2) .. '_face' .. sprite:sub(-1)
            local o = e.sprite.overlay
            if o == nil then
                o = {}
                e.sprite.overlay = o
            end
            o.name = spriteFace
            o.flipX = isRightward
        end

        local f = (isRightward and flipSprite)
        if f ~= n.lastFlip and n.lastFlipDur >= 40 then
            n.lastFlip = f
            n.lastFlipDur = 0
        end
        e.sprite.flipX = n.lastFlip

        e.sprite.name = sprite

    end
end

} end
