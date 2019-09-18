return function () return {

update = function (self, cs)
    for _, e1 in pairs(cs.bullet or {}) do
        e1.sprite.oy = 28

        if e1.bullet.age then e1.bullet.age = e1.bullet.age + 1 end

        cs.dim:colliding(e1, function (e2)
            if not e2.colli.fence and
                bit.band(e2.colli.tag or 0, e1.bullet.mask) ~= 0
            then
                if e2.health ~= nil then
                    -- Is absorbed?
                    local p = e2.player
                    if p ~= nil and p.colour == e1.bullet.colour then
                        local increment = (
                            (p.colour == 0 and p.buff.rstarve and p.buff.rstarve.equipped) or
                            (p.colour == 1 and p.buff.bstarve and p.buff.bstarve.equipped)
                        ) and 15 or 10
                        p.energy = math.min(p.energy + increment, p.energyMax)
                    else
                        -- Dodge?
                        if p ~= nil then
                            if e1.bullet.dodged then return end
                            if p.buff.dodge and p.buff.dodge.equipped and math.random() < 0.1 then
                                e1.bullet.dodged = true
                                return
                            end
                        end
                        local damage = 1
                        -- Incise?
                        if e1.bullet.age and e1.bullet.age >= 90 then damage = 2 end
                        print(damage)
                        e2.health.val = e2.health.val - damage
                        -- Play hit animation
                        if p then
                            p.fsm:trans(
                                p.fsm.curState == 1 and
                                (e2.health.val <= 0 and 'akaDeath' or 'akaHit') or
                                (e2.health.val <= 0 and 'ookamiDeath' or 'ookamiHit'),
                                true
                            )
                        elseif e2.enemy then
                            e2.enemy.fsm:trans(e2.health.val <= 0 and 'death' or 'hit', true)
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
