local ecs = require 'ecs/ecs'

local lastDownI = false

buffTermReset = function ()
    lastDownI = nil
end

buffTermUpdate = function (term)
    local downI = love.keyboard.isDown('i')
    if downI and lastDownI == false then
        ecs.removeEntity(term)
        ecs.removeEntity(term.term.bubble)
        return false
    end
    lastDownI = downI
    return true
end

buffTermDraw = function ()
end
