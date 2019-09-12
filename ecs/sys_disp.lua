local debouncer = function (size)
    local ret = {}
    local hist, ptr = {}, 1
    local med = nil
    ret.add = function (x)
        hist[ptr] = x
        ptr = ptr % size + 1
        if #hist < size then return 0 end
        -- Try to find one element that occurs more than half of the time
        local val, count = nil, 0
        for _, v in ipairs(hist) do
            if count == 0 then val, count = v, 1
            else count = count + (v == val and 1 or -1) end
        end
        -- Count occurrences
        count = 0
        for _, v in ipairs(hist) do count = count + (v == val and 1 or 0) end
        -- Update median
        if med then
            if count * 4 > size * 3 then med = val
            elseif count * 2 <= size then med = nil end
        else
            if count * 2 > size then med = val end
        end
        -- Return appropriate adjustment values
        if med then return (math.abs(med - x) <= 3 and med - x or 0)
        else return 0 end
    end
    ret.reset = function () hist = {} end
    return ret
end

local draw = function (self, e, ax, ay)
    self.spritesheet.draw(
        e.sprite.name,
        math.floor(e.dim[1] + 0.5) - math.floor(self.cam[1]) + ax,
        math.floor(e.dim[2] + e.dim[4] + 0.5) - math.floor(self.cam[2]) + ay,
        true
    )
end

return function (spritesheet) return {

spritesheet = spritesheet,
cam = {0, 0},
debouncerX = debouncer(30),
debouncerY = debouncer(30),
update = function (self, cs)
    local p = cs.player[1]
    local ax = self.debouncerX.add(math.floor(p.dim[1] + 0.5) - math.floor(self.cam[1]))
    local ay = self.debouncerY.add(math.floor(p.dim[2] + p.dim[4] + 0.5) - math.floor(self.cam[2]))

    local es_z0, es_zp = {}, {}

    for _, e in pairs(cs.sprite) do
        if e.sprite.z == nil then es_z0[#es_z0 + 1] = e
        elseif e.sprite.z < 0 then draw(self, e, ax, ay)
        else es_zp[#es_zp + 1] = e end
    end

    table.sort(es_z0, function (lhs, rhs)
        if math.abs(lhs.dim[2] - rhs.dim[2]) <= 1e-6 then
            return lhs.dim[1] < rhs.dim[1]
        end
        return lhs.dim[2] < rhs.dim[2]
    end)

    for _, e in pairs(es_z0) do draw(self, e, ax, ay) end
    for _, e in pairs(es_zp) do draw(self, e, ax, ay) end
end

} end
