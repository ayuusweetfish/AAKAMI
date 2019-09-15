local draw = function (self, e)
    local f = e.sprite.trim and self.spritesheet.drawTrimmed or self.spritesheet.draw
    f(
        e.sprite.name,
        math.floor(e.dim[1] + 0.5) - math.floor(self.cam[1]),
        math.floor(e.dim[2] + e.dim[4] + 0.5) - math.floor(self.cam[2]),
        true,
        e.sprite.flipX,
        e.sprite.flipY
    )
end

return function (spritesheet) return {

spritesheet = spritesheet,
cam = {0, 0},
update = function (self, cs)
    local es_z0, es_zp = {}, {}

    for _, e in pairs(cs.sprite) do if e.sprite.visible ~= false then
        local z = e.sprite.z
        if z == nil then es_z0[#es_z0 + 1] = e
        elseif z < 0 then draw(self, e)
        else es_zp[#es_zp + 1] = e end
    end end

    table.sort(es_z0, function (lhs, rhs)
        return lhs.dim[2] < rhs.dim[2]
    end)

    for _, e in pairs(es_z0) do draw(self, e) end
    for _, e in pairs(es_zp) do draw(self, e) end
end

} end
