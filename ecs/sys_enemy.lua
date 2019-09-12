local ecs = require 'ecs/ecs'
require 'ecs/utils'

return function () return {

update = function (self, cs)
    local ePlayer = cs.player[1]
    if ePlayer == nil then return end

    for _, e in pairs(cs.enemy) do
        local dx, dy = targetVec(e.dim, ePlayer.dim, 16)
        e.vel[1], e.vel[2] = dx, dy

        e.enemy.countdown = (e.enemy.countdown or e.enemy.interval) - 1
        if e.enemy.countdown <= 0 then
            -- Generate a bullet
            local bullet = {
                dim = {
                    e.dim[1] + e.dim[3] * 0.5 + dx * 0.25,
                    e.dim[2] + e.dim[4] * 0.5 + dy * 0.25,
                    4, 4
                },
                vel = { dx * 10, dy * 10 },
                sprite = { name = 'quq7' },
                bullet = { source = e },
            }
            if math.random(2) == 1 then
                bullet.follow = { target = ePlayer, vel = 120, accel = 16 }
            else bullet.sprite.name = 'quq8'
            end
            ecs.addEntity(bullet)
            e.enemy.countdown = e.enemy.interval
        end
    end
end

} end
