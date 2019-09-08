local entities = {}
local components = {}
local systems = { [1] = {}, [2] = {} }

local addEntity = function (e)
    entities[#entities + 1] = e
    for k, v in pairs(e) do
        v.entity = e
        local c = (components[k] or {})
        components[k] = c
        c[#c + 1] = v
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
    entities = entities,
    components = components,
    systems = systems,

    addEntity = addEntity,
    addSystem = addSystem,
    update = update
}
