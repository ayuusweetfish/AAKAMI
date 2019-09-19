local audio = require 'audio'
local ecs = require 'ecs/ecs'
require 'ecs/utils'

return function () return {

update = function (self, cs)
    local p = cs.player[1]
    local k = p.player.keys
    if k == nil then k = {} p.player.keys = k end

    for _, e in pairs(cs.door) do
        local near = rectIntscAround(p.dim, e.dim, 8)

        if e.door.fin then
            if e.door.since then
                e.door.since = e.door.since + 1
                if e.door.since >= 270 then
                    p.player.win = true
                elseif e.door.since >= 90 then
                    e.sprite.name = 'tileset3#elevator2'
                elseif e.door.since >= 30 then
                    e.sprite.name = 'tileset3#elevator1'
                end
            elseif near then
                e.door.since = 0
            end

        else
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
    end

    for _, e in pairs(cs.key) do
        if rectIntsc(p.dim, e.dim) then
            k[e.key.id] = true
            e._removal = true
            audio.play('pickupcoin')
        end
    end
end

} end
