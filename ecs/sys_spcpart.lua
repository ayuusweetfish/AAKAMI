require 'ecs/utils'

local BLOCK = 7     -- 128
local STRIDE = 6    -- 64

local rsh, lsh = bit.rshift, bit.lshift

local colliding = function (self, e, cb)
    local p = self.partition
    local x1, x2, y1, y2 =
        rsh(e.dim[1], BLOCK), rsh(e.dim[1] + e.dim[3], BLOCK),
        rsh(e.dim[2], BLOCK), rsh(e.dim[2] + e.dim[4], BLOCK)
    local x, y
    for x = x1, x2 do
    for y = y1, y2 do
        local block = p[lsh(x, STRIDE) + y]
        if block then
            for _, t in pairs(block) do
                if e ~= t and rectIntsc(e.dim, t.dim) then
                    if cb(t) then goto fin end
                end
            end
        end
    end
    end
::fin::
end

return function () return {

update = function (self, cs)
    if cs.dim.colliding == nil then
        cs.dim.colliding = colliding
    end
    local p = {}
    for _, e in pairs(cs.colli) do
        local x1, x2, y1, y2 =
            rsh(e.dim[1], BLOCK), rsh(e.dim[1] + e.dim[3], BLOCK),
            rsh(e.dim[2], BLOCK), rsh(e.dim[2] + e.dim[4], BLOCK)
        local x, y
        for x = x1, x2 do
        for y = y1, y2 do
            local i = lsh(x, STRIDE) + y
            local t = p[i]
            if t == nil then p[i] = { e }
            else t[#t + 1] = e end
        end
        end
    end
    cs.dim.partition = p
end

} end
