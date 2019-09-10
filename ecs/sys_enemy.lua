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
        e.vel[1], e.vel[2] = dx * factor, dy * factor
    end
end

} end
