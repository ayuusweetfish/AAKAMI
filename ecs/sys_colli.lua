local segIntsc = function (l1, r1, l2, r2)
    return math.max(l1, l2) < math.min(r1, r2)
end

local rectIntsc = function (a, b)
    return segIntsc(a[1], a[1] + a[3], b[1], b[1] + b[3])
        and segIntsc(a[2], a[2] + a[4], b[2], b[2] + b[4])
end

return function () return {

component = 'dim',
update = function (self, es)
    -- TODO: Optimize if this becomes the bottleneck

    -- Checks whether e1 collides with any other entity
    -- Returns push amount required in four directions (X+, X-, Y+, Y-)
    local check = function (e1)
        -- Find out min_x, max_x, min_y, max_y of colliding entities
        -- in e1's coordinate system
        local x1, x2 = 1e10, -1e10
        local y1, y2 = 1e10, -1e10
        for _, e2 in pairs(es) do
            if e2 ~= e1 and rectIntsc(e1.dim, e2.dim) then
                x1 = math.min(x1, e2.dim[1])
                x2 = math.max(x2, e2.dim[1] + e2.dim[3])
                y1 = math.min(y1, e2.dim[2])
                y2 = math.max(y2, e2.dim[2] + e2.dim[4])
            end
        end
        if x1 == 1e10 then return nil
        else return
            math.min(math.max(x1 - e1.dim[1], 0), e1.dim[3]),
            e1.dim[3] - math.min(math.max(x2 - e1.dim[1], 0), e1.dim[3]),
            math.min(math.max(y1 - e1.dim[2], 0), e1.dim[4]),
            e1.dim[4] - math.min(math.max(y2 - e1.dim[2], 0), e1.dim[4])
        end
    end

    for _, e1 in pairs(es) do if e1.passiveCollide then
        local x1, x2, y1, y2 = check(e1)
        if x1 ~= nil then
            e1.vel[1], e1.vel[2] = 0, 0 -- XXX: ...

            if (x1 ~= 0 and x2 ~= 0) or (y1 ~= 0 and y2 ~= 0) then
                print('Squeezing happened, check your map > <')
            end
            -- Check for a nearest direction to push out
            -- This assumes that e1 will never be squeezed
            local dx, dy = 1e10, 1e10
            if x1 == 0 then
                -- Push left
            else
                -- Push right
            end
        end
    end end
end

} end
