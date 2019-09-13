require 'ecs/utils'

local BLOCK = 7     -- 128
local STRIDE = 6    -- 64

local rsh, lsh = bit.rshift, bit.lshift

local _colliding = function (self, e, dim, cb)
    local p = self.partition
    local x1, x2, y1, y2 =
        rsh(dim[1], BLOCK), rsh(dim[1] + dim[3], BLOCK),
        rsh(dim[2], BLOCK), rsh(dim[2] + dim[4], BLOCK)
    local x, y
    for x = x1, x2 do
    for y = y1, y2 do
        local block = p[lsh(x, STRIDE) + y]
        if block then
            for _, t in pairs(block) do
                if e ~= t and rectIntsc(dim, t.dim) then
                    if cb(t) then goto fin end
                end
            end
        end
    end
    end
::fin::
end

local colliding = function (self, e, cb)
    _colliding(self, e, e.dim, cb)
end

local collidingAround = function (self, e, w, cb)
    _colliding(self, e, {
        e.dim[1] - w, e.dim[2] - w,
        e.dim[3] + w + w, e.dim[4] + w + w
    }, cb)
end

return function () return {

update = function (self, cs)
    if cs.dim.colliding == nil then
        cs.dim.colliding = colliding
        cs.dim.collidingAround = collidingAround
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
