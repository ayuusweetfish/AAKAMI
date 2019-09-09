local entities = {}
local components = {}   -- List of entities with a certain component
local systems = { [1] = {}, [2] = {} }

DT = 1.0 / 300

local addEntity = function (e)
    entities[#entities + 1] = e
    for k, v in pairs(e) do
        local c = (components[k] or {})
        components[k] = c
        c[#c + 1] = e
    end
end

local addSystem = function (pass, s)
    local ss = systems[pass]
    ss[#ss + 1] = s
end

local update = function (pass)
    for _, s in pairs(systems[pass]) do
        s:update(components[s.component])
    end
end

return {
    dt = DT,

    entities = entities,
    components = components,
    systems = systems,

    addEntity = addEntity,
    addSystem = addSystem,
    update = update
}
