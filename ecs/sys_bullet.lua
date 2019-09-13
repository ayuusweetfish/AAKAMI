return function () return {

update = function (self, cs)
    for _, e1 in pairs(cs.bullet or {}) do
        cs.dim:colliding(e1, function (e2)
            if bit.band(e2.colli.tag or 0, e1.bullet.mask) ~= 0 then
                e1._removal = true
                return true
            end
        end)
    end
end

} end
