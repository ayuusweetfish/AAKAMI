local ecs = require 'ecs/ecs'
require 'ecs/utils'

local PERIOD = 360
local BULLET_VEL = 120
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
        sprite = { name = (colour == 0 and 'quq7' or 'quq8') },
        bullet = { mask = 3, colour = colour },
    }
    ecs.addEntity(bullet)
    --if math.random(2) == 1 then
    --    bullet.follow = { target = ePlayer, vel = BULLET_VEL, accel = BULLET_ACCEL * DT }
    --else bullet.sprite.name = 'quq8'
    --end
end

patternUpdate.triplet = function (e, ePlayer, phase, dx, dy)
    e.enemy._nextShoot = (e.enemy._nextShoot or 180)
    e.enemy._curWaveColour = (e.enemy._curWaveColour or 0)
    if phase == e.enemy._nextShoot then
        if phase == 180 then
            e.enemy._curWaveColour = (e.enemy._curWaveColour + 1) % 2
        end
        -- Generate a bullet
        addBullet(e, dx * BULLET_VEL, dy * BULLET_VEL, e.enemy._curWaveColour)
        -- 180, 210, 240
        e.enemy._nextShoot = (e.enemy._nextShoot - 150) % 90 + 180
    end
end

patternUpdate.triad = function (e, ePlayer, phase, dx, dy)
    e.enemy._curWaveColour = (e.enemy._curWaveColour or 0)
    if phase == 180 then
        e.enemy._curWaveColour = (e.enemy._curWaveColour + 1) % 2
        addBullet(e, dx * BULLET_VEL, dy * BULLET_VEL, e.enemy._curWaveColour)
        local alpha = math.atan2(dy, dx)
        addBullet(e,
            BULLET_VEL * math.cos(alpha + math.pi / 6), BULLET_VEL * math.sin(alpha + math.pi / 6),
            e.enemy._curWaveColour)
        addBullet(e,
            BULLET_VEL * math.cos(alpha - math.pi / 6), BULLET_VEL * math.sin(alpha - math.pi / 6),
            e.enemy._curWaveColour)
    end
end

patternUpdate.penta = function (e, ePlayer, phase, dx, dy)
    e.enemy._nextShoot = (e.enemy._nextShoot or 180)
    e.enemy._curColour = (e.enemy._curColour or 0)
    if phase == e.enemy._nextShoot then
        e.enemy._curColour = (e.enemy._curColour + 1) % 2
        addBullet(e, dx * BULLET_VEL, dy * BULLET_VEL, e.enemy._curColour)
        -- 180, 195, 210, 225, 240
        e.enemy._nextShoot = (e.enemy._nextShoot - 165) % 75 + 180
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

return function () return {

update = function (self, cs)
    local ePlayer = cs.player[1]
    if ePlayer == nil then return end

    for _, e in pairs(cs.enemy) do
        -- Follow player and repel other enemies
        local dx, dy = targetVecAround(e.dim, ePlayer.dim, 16, 16)

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
        e.vel[1], e.vel[2] = dx2, dy2

        -- Bullets
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

        local frame = ((e.enemy.frame or -1) + 1) % 60
        e.enemy.frame = frame
        e.sprite.name = 'colaeli_attacking' .. tostring(math.floor(frame / 15) + 1)
        e.sprite.ox = 12
        e.sprite.oy = 13

    end
end

} end
