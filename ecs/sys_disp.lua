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

local drawTile = function (self, sprite, x, y)
    self.spritesheet.draw(
        sprite,
        x * 16 - math.floor(self.cam[1]),
        y * 16 - math.floor(self.cam[2])
    )
end

return function (spritesheet) return {

spritesheet = spritesheet,
cam = {0, 0},
update = function (self, cs)
    local es_z0, es_zp = {}, {}

    local cx, cy = self.cam[1], self.cam[2]

    -- Floor
    local f = cs.floor
    local g = f._grid
    local w = f._width

    if g == nil then
        -- Preprocess once
        -- Assume that the floor terrain does not change
        g = {}
        f._grid = g

        -- Width = maximum X coordinate
        w = 0
        for _, e in ipairs(cs.floor) do w = math.max(w, e.floor.x) end
        f._width = w

        for _, e in ipairs(cs.floor) do
            local i = (e.floor.y - 1) * w + e.floor.x
            g[i] = e.floor
        end
    end

    local x1 = math.floor((self.cam[1]) / 16)
    local y1 = math.ceil((self.cam[2]) / 16) - 2
    local x2 = math.floor((self.cam[1] + W) / 16)
    local y2 = math.ceil((self.cam[2] + H) / 16) - 2
    for x = x1, x2 do
    for y = y1, y2 do
        local tile = g[y * w + x]
        if tile then
            drawTile(self, tile.sprite, tile.x, tile.y)
        end
    end
    end

    -- Objects with sprite component
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
