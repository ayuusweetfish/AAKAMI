local spritesheet = require 'spritesheet'
local ecs = require 'ecs/ecs'
local buff = require 'mech/buff'

local player

local term      -- Current terminal entity
local lastDownI -- Is key <I> pressed last frame
local lastDownL, lastDownR
local T         -- Total time

vendTermReset = function (_term)
    player = ecs.components.player[1].player

    term = _term
    lastDownI = nil
    lastDownL, lastDownR = nil, nil
    T = 0
end

vendTermUpdate = function ()
    T = T + love.timer.getDelta()

    local downI = love.keyboard.isDown('i')
    if downI and lastDownI == false then
        -- Exit
        return false
    end
    lastDownI = downI

    local downL = love.keyboard.isDown('left') or love.keyboard.isDown('up')
    local downR = love.keyboard.isDown('right') or love.keyboard.isDown('down')
    if downL and lastDownL == false then
    end
    if downR and lastDownR == false then
    end
    lastDownL = downL
    lastDownR = downR

    return true
end

vendTermDraw = function ()
    love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
    love.graphics.rectangle('fill', 0, 0, W, H)
    love.graphics.setColor(1, 1, 1)
    spritesheet.flush()
end
