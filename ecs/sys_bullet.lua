return function () return {

update = function (self, cs)
    for _, e1 in pairs(cs.bullet or {}) do
        cs.dim:colliding(e1, function (e2)
            if not e2.colli.fence and
                bit.band(e2.colli.tag or 0, e1.bullet.mask) ~= 0
            then
                -- Is player?
                if e2.player ~= nil then
                    local p = e2.player
                    if p.colour == e1.bullet.colour then
                        p.energy = math.min(p.energy + 10, p.energyMax)
                    else
                        p.health = p.health - 1
                        if p.health <= 0 then
                            p.fail = true
                        end
                    end
                end

                -- Vanish
                e1._removal = true
                return true
            end
        end)
    end
end

} end
