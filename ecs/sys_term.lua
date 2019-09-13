require 'ecs/utils'

return function () return {

update = function (self, cs)
    local p = cs.player[1]

    for _, e in pairs(cs.term) do
        if rectIntscAround(p.dim, e.dim, 4) then
            -- Display the hovering bubble
            e.term.bubble.sprite.z = 1
            if love.keyboard.isDown('i') then
                e.term.callback()
            end
        else
            -- Hide the bubble
            e.term.bubble.sprite.z = -1
        end
    end
end

} end
