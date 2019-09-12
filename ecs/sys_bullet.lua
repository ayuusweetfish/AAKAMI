return function () return {

update = function (self, cs)
    for _, e1 in pairs(cs.bullet or {}) do
        for _, e2 in pairs(cs.colli) do
            if e2 ~= e1 and e2 ~= e1.bullet.source
                and (e2.colli.block or e2.player)
                and rectIntsc(e1.dim, e2.dim)
            then
                e1._removal = true
                break
            end
        end
    end
end

} end
