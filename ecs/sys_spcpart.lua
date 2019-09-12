require 'ecs/utils'

local BLOCK = 96
local STRIDE = 32768

local colliding = function (self, e, cb)
    local p = self.partition
    local x1, x2, y1, y2 =
        e.dim[1], e.dim[1] + e.dim[3],
        e.dim[2], e.dim[2] + e.dim[4]
    local x, y
    for x = math.floor(x1 / BLOCK), math.floor(x2 / BLOCK) do
    for y = math.floor(y1 / BLOCK), math.floor(y2 / BLOCK) do
        if p[x * STRIDE + y] then
            for _, t in pairs(p[x * STRIDE + y]) do
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
            e.dim[1], e.dim[1] + e.dim[3],
            e.dim[2], e.dim[2] + e.dim[4]
        local x, y
        for x = math.floor(x1 / BLOCK), math.floor(x2 / BLOCK) do
        for y = math.floor(y1 / BLOCK), math.floor(y2 / BLOCK) do
            local t = p[x * STRIDE + y] or {}
            t[#t + 1] = e
            p[x * STRIDE + y] = t
        end
        end
    end
    cs.dim.partition = p
end

} end
