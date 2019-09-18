local ecs = require 'ecs/ecs'
require 'ecs/utils'

return function () return {

update = function (self, cs)
    local p = cs.player[1]
    local k = p.player.keys
    if k == nil then k = {} p.player.keys = k end

    for _, e in pairs(cs.door) do
        local near = rectIntscAround(p.dim, e.dim, 8)
        local b = e.door.bubble
        if (e.door.id == 0 or k[e.door.id]) and near then
            e.colli.tag = 0
            e.colli.block = false
            e.sprite.visible = false
            if b ~= nil then b.sprite.visible = false end
        else
            e.colli.tag = 3
            e.colli.block = true
            e.sprite.visible = true
            if b ~= nil then b.sprite.visible = near end
        end
    end

    for _, e in pairs(cs.key) do
        if rectIntsc(p.dim, e.dim) then
            k[e.key.id] = true
            e._removal = true
        end
    end
end

} end
