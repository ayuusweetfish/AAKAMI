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
    local es_z = {
        [-2] = {},
        [-1] = {},
        [0] = {},
        [1] = {},
        [2] = {}
    }

    for _, e in ipairs(cs.sprite) do if e.sprite.visible ~= false then
        local z = e.sprite.z or 0
        local es = es_z[z]
        es[#es + 1] = e
    end end

    for z = -2, 2 do
        for _, e in ipairs(es_z[z]) do draw(self, e) end
    end
end

} end
