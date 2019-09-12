return function () return {

update = function (self, cs)
    for _, e1 in pairs(cs.bullet or {}) do
        cs.dim:colliding(e1, function (e2)
            if e2 ~= e1.bullet.source and (e2.colli.block or e2.player) then
                e1._removal = true
                return true
            end
        end)
    end
end

} end
