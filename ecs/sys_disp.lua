local draw = function (self, e)
    local s = e.sprite
    local o = s.overlay
::redraw::
    local fx = s.flipX
    local fy = s.flipY
    local ox = (s.ox or 0)
    local oy = (s.oy or 0)
    ox = (fx and e.dim[3] + ox or -ox)
    oy = (fy and e.dim[4] + oy or -oy)
    self.spritesheet.draw(
        s.name,
        math.floor(e.dim[1] + 0.5) - math.floor(self.cam[1]) + ox,
        math.floor(e.dim[2] + 0.5) - math.floor(self.cam[2]) + oy,
        fx, fy
    )
    if o and s ~= o then
        s = o
        goto redraw
    end
end

return function (spritesheet) return {

spritesheet = spritesheet,
cam = {0, 0},
update = function (self, cs)
    local es_z0, es_zp = {}, {}

    local cx, cy = self.cam[1], self.cam[2]

    for _, e in ipairs(cs.sprite) do
        local s = e.sprite
        local d = e.dim
        if s.visible ~= false and
            d[1] >= cx - d[3] and
            d[1] <= cx + W + d[3] and
            d[2] >= cy - d[4] and
            d[2] <= cy + H + d[4]
        then
            local z = s.z
            if z == nil then es_z0[#es_z0 + 1] = e
            elseif z < 0 then draw(self, e)
            else es_zp[#es_zp + 1] = e end
        end
    end

    table.sort(es_z0, function (lhs, rhs)
        return lhs.dim[2] < rhs.dim[2]
    end)

    for _, e in ipairs(es_z0) do draw(self, e) end
    for _, e in ipairs(es_zp) do draw(self, e) end
end

} end
