local spritesheet = require 'spritesheet'
local ecs = require 'ecs/ecs'
local buff = require 'mech/buff'

local player

local term      -- Current terminal entity
local lastDownI -- Is key <I> pressed last frame
local lastDownL, lastDownR
local T         -- Total time

knapsackReset = function (_term)
    player = ecs.components.player[1].player

    term = _term
    lastDownI = nil
    lastDownL, lastDownR = nil, nil
    T = 0
end

knapsackUpdate = function ()
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

knapsackDraw = function ()
    love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
    love.graphics.rectangle('fill', 0, 0, W, H)
    love.graphics.setColor(1, 1, 1)

    spritesheet.text(
        string.format('Knapsack\nMax Health: %d  Memory: %d',
            player.healthMax, player.memory),
        W * 0.1, H * 0.1
    )

    local index = 0
    local memUsed = 0
    for k, v in pairs(buff) do
        local row, col = index % 5, math.floor(index / 5)
        index = index + 1
        spritesheet.drawCen(buff[k].icon, W * (0.1 + 0.3 * col), H * (0.2 + 0.1 * row))
        spritesheet.text(k, W * (0.15 + 0.3 * col), H * (0.233 + 0.1 * row))
        if v.equipped then
        end
    end

    spritesheet.flush()
end
