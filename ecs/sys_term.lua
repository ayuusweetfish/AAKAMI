local ecs = require 'ecs/ecs'
require 'ecs/utils'

return function () return {

lastDownI = false,
update = function (self, cs)
    local p = cs.player[1]
    local downI = love.keyboard.isDown('i')
    local called = false

    for _, e in pairs(cs.term) do
        -- `once` might be true/false/-1
        if e.term.once ~= -1 and rectIntscAround(p.dim, e.dim, 4) then
            -- Display the hovering bubble
            e.term.bubble.sprite.visible = true
            if downI and not self.lastDownI and not called then
                e.term.callback(e)
                if e.term.once then
                    ecs.removeEntity(e.term.bubble)
                    e.term.once = -1
                end
                called = true
            end
        else
            -- Hide the bubble
            e.term.bubble.sprite.visible = false
        end
    end

    self.lastDownI = downI
end

} end
