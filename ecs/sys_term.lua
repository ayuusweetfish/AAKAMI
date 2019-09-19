local audio = require 'audio'
local input = require 'input'
local ecs = require 'ecs/ecs'
require 'ecs/utils'

return function () return {

lastDownY = false,
update = function (self, cs)
    local p = cs.player[1]
    local downY = input.Y()
    local called = false

    for _, e in pairs(cs.term) do
        -- `once` might be true/false/-1
        if e.term.once ~= -1 and rectIntscAround(p.dim, e.dim, 4) then
            -- Display the hovering bubble
            e.term.bubble.sprite.visible = true
            if downY and not self.lastDownY and not called then
                e.term.callback(e)
                if e.term.once then
                    ecs.removeEntity(e.term.bubble)
                    e.term.once = -1
                end
                called = true
                audio.play('turnonterminal')
                audio.get('Beverage Battle'):setVolume(0.2)
            end
        else
            -- Hide the bubble
            e.term.bubble.sprite.visible = false
        end
    end

    self.lastDownY = downY
end

} end
