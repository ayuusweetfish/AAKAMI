local ecs = require 'ecs/ecs'
require 'ecs/utils'
local buff = require 'mech/buff'

local keys = function (a, b)
    local result = 0
    if love.keyboard.isDown(a) then result = result + 1 end
    if love.keyboard.isDown(b) then result = result - 1 end
    return result
end

local updateVel = function (orig, tx, ty)
    local A = 768   -- Acceleration
    if tx == 0 and ty == 0 then A = 256 end
    local DV = A * DT
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
    local R = 96    -- Visibile range
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
update = function (self, cs)
    for _, e in pairs(cs.player) do
        local horz = keys('right', 'left')
        local vert = keys('down', 'up')
        if horz ~= 0 and vert ~= 0 then
            horz = horz / 1.414213562
            vert = vert / 1.414213562
        end
        updateVel(e.vel, horz * 96, vert * 96)

        local UDown = love.keyboard.isDown('u')
        local target = nearest(e, self.lastValidVel, cs.enemy)
        local dx, dy
        if target ~= nil then
            dx, dy = targetVec(e.dim, target.dim, 16)
        else
            dx, dy = self.lastValidVel[1] * 16, self.lastValidVel[2] * 16
        end
        -- TODO: Support charging
        if UDown and not self.lastUDown and e.player.energy >= 10 then
            e.player.energy = e.player.energy - 10
            local bullet = {
                dim = {
                    e.dim[1] + e.dim[3] * 0.5 + dx * 0.25,
                    e.dim[2] + e.dim[4] * 0.5 + dy * 0.25,
                    4, 4
                },
                vel = { dx * 10, dy * 10 },
                sprite = { name = 'quq9' },
                bullet = { mask = 5 }
            }
            ecs.addEntity(bullet)
        end
        self.lastUDown = UDown

        local JDown = love.keyboard.isDown('j')
        if JDown and not self.lastJDown then
            -- SHIFT!
            e.player.colour = 1 - e.player.colour
            e.sprite.name = (e.player.colour == 0 and 'quq6' or 'quq5')
        end
        self.lastJDown = JDown
    end
end

} end
