local ecs = require 'ecs/ecs'

return function () return {

update = function (self, cs)
    local ePlayer = cs.player[1]
    if ePlayer == nil then return end
    local px, py =
        ePlayer.dim[1] + ePlayer.dim[3] * 0.5,
        ePlayer.dim[2] + ePlayer.dim[4] * 0.5
    for _, e in pairs(cs.enemy) do
        local dx, dy =
            px - (e.dim[1] + e.dim[3] * 0.5),
            py - (e.dim[2] + e.dim[4] * 0.5)
        -- FPE will not happen as long as enemies are blocking colliders
        local factor = 16 / math.sqrt(dx * dx + dy * dy)
        dx = dx * factor
        dy = dy * factor
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
                vel = { dx * 2, dy * 2 },
                sprite = { name = 'quq7' },
                bullet = { source = e }
            }
            ecs.addEntity(bullet)
            e.enemy.countdown = e.enemy.interval
        end
    end
end

} end
