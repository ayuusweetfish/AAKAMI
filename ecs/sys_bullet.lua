return function () return {

update = function (self, cs)
    for _, e1 in pairs(cs.bullet or {}) do
        e1.sprite.oy = 28

        cs.dim:colliding(e1, function (e2)
            if not e2.colli.fence and
                bit.band(e2.colli.tag or 0, e1.bullet.mask) ~= 0
            then
                if e2.health ~= nil then
                    -- Is absorbed?
                    local p = e2.player
                    if p ~= nil and p.colour == e1.bullet.colour then
                        p.energy = math.min(p.energy + 10, p.energyMax)
                    else
                        e2.health.val = e2.health.val - 1
                        -- Play hit animation
                        -- TODO: Consider enemies also
                        if p then
                            p.fsm:trans(
                                p.fsm.curState == 1 and 'akaHit' or 'ookamiHit',
                                true
                            )
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
