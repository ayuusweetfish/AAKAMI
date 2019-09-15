local entities = {}
local components = {}   -- List of entities with a certain component
local systems = { [1] = {}, [2] = {} }

DT = 1.0 / 120

-- e._entity is the index in entities table
-- e._lookup is the indices in component lists

local addEntity = function (e)
    entities[#entities + 1] = e

    local lookup = {}
    for k, v in pairs(e) do
        -- k: name of the component
        local c = (components[k] or {})
        components[k] = c
        c[#c + 1] = e
        lookup[k] = #c
    end

    e._entity = #entities
    e._lookup = lookup

    return e
end

local removeEntity = function (e)
    for k, v in pairs(e._lookup) do
        -- Remove from component lists
        local c = components[k]
        local e2 = c[#c]    -- The entity to be updated
        c[v] = e2
        e2._lookup[k] = v
        table.remove(c, #c)
    end

    -- Remove from the entity list
    entities[e._entity] = entities[#entities]
    entities[#entities]._entity = e._entity
    table.remove(entities, #entities)
end

local addSystem = function (pass, s)
    local ss = systems[pass]
    ss[#ss + 1] = s
    return s
end

local update = function (pass)
    for _, s in pairs(systems[pass]) do
        s:update(components)
    end
    local removed = {}
    for _, e in ipairs(entities) do
        if e._removal then removed[#removed + 1] = e end
    end
    for _, e in ipairs(removed) do removeEntity(e) end
end

local reset = function ()
    entities = {}
    components = {}
    systems = { [1] = {}, [2] = {} }
end

return {
    dt = DT,

    entities = entities,
    components = components,
    systems = systems,

    addEntity = addEntity,
    removeEntity = removeEntity,
    addSystem = addSystem,
    update = update,

    reset = reset
}
