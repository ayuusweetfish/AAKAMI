local ecs = require 'ecs/ecs'
require 'ecs/utils'

return function () return {

update = function (self, cs)
    local p = cs.player[1]

    for _, e in pairs(cs.term) do
        if not e.term.used and rectIntscAround(p.dim, e.dim, 4) then
            -- Display the hovering bubble
            e.term.bubble.sprite.visible = true
            if love.keyboard.isDown('i') then
                e.term.used = true
                e.term.callback()
                ecs.removeEntity(e.term.bubble)
            end
        else
            -- Hide the bubble
            e.term.bubble.sprite.visible = false
        end
    end
end

} end
