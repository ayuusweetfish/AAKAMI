local draw = function (self, e)
    self.spritesheet.draw(
        e.sprite.name,
        math.floor(e.dim[1] + 0.5) - math.floor(self.cam[1]),
        math.floor(e.dim[2] + e.dim[4] + 0.5) - math.floor(self.cam[2]),
        true
    )
end

return function (spritesheet) return {

component = 'sprite',
spritesheet = spritesheet,
cam = {0, 0},
update = function (self, es)
    local es_z0, es_zp = {}, {}

    for _, e in pairs(es) do
        if e.sprite.z == nil then es_z0[#es_z0 + 1] = e
        elseif e.sprite.z < 0 then draw(self, e)
        else es_zp[#es_zp + 1] = e end
    end

    table.sort(es_z0, function (lhs, rhs)
        if math.abs(lhs.dim[2] - rhs.dim[2]) <= 1e-6 then
            return lhs.dim[1] < rhs.dim[1]
        end
        return lhs.dim[2] < rhs.dim[2]
    end)

    for _, e in pairs(es_z0) do draw(self, e) end
    for _, e in pairs(es_zp) do draw(self, e) end
end

} end
