local ecs = require 'ecs/ecs'

local C = { 'QuQ', 'QvQ', 'QwQ', 'QxQ', 'OuO', 'OvO', 'OwO', 'OxO' }
local E = {}

math.randomseed(20190912)

function check()
    for i = 1, #ecs.entities do
        if i ~= ecs.entities[i]._entity then return false end
        for k, v in pairs(ecs.entities[i]._lookup) do
            if ecs.components[k][v] == nil or
                ecs.components[k][v][k].enti ~= ecs.entities[i].TvT.enti
            then
                return false
            end
        end
    end
    return true
end

for i = 1, 1000 do
    if math.random(2) == 1 then
        print('Create ' .. tostring(i))
        -- Create a random entity
        local e = { TvT = { enti = i } }
        -- Randomly add components
        for j = 1, #C do
            if math.random(2) == 1 then
                e[C[j]] = { enti = i }
            end
        end
        ecs.addEntity(e)
        E[#E + 1] = e
    elseif #E > 0 then
        -- Remove a random entity
        local idx = math.random(#E)
        print('Remove ' .. E[idx].TvT.enti)
        ecs.removeEntity(E[idx])
        E[idx] = E[#E]
        table.remove(E, #E)
    end
    if not check() then
        print('> <')
        for i = 1, #ecs.entities do
            print(i, ecs.entities[i]._entity, ecs.entities[i].TvT.enti)
            for k, v in pairs(ecs.entities[i]._lookup) do
                print(k, ecs.components[k][v][k].enti)
            end
        end
    end
end
