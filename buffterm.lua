local spritesheet = require 'spritesheet'
local ecs = require 'ecs/ecs'

local lastDownI = false

buffTermReset = function ()
    lastDownI = nil
end

buffTermUpdate = function (term)
    local downI = love.keyboard.isDown('i')
    if downI and lastDownI == false then
        term.sprite.name = 'quq1'
        return false
    end
    lastDownI = downI
    return true
end

buffTermDraw = function ()
    love.graphics.setColor(0.3, 0.3, 0.3, 0.3)
    love.graphics.rectangle('fill', 0, 0, W, H)
    love.graphics.setColor(1, 1, 1)
    spritesheet.draw('quq10', 10, 10, false, 3)
    spritesheet.flush()
end
