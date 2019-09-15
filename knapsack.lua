local spritesheet = require 'spritesheet'
local ecs = require 'ecs/ecs'
local buff = require 'mech/buff'

local player

local term      -- Current terminal entity
local lastDownI -- Is key <I> pressed last frame
local lastDownL, lastDownR
local lastDownU, lastDownD
local T         -- Total time

local cardNames
local total
local selIndex

knapsackReset = function (_term)
    player = ecs.components.player[1].player

    term = _term
    lastDownI = nil
    lastDownL, lastDownR = nil, nil
    lastDownU, lastDownD = nil, nil
    T = 0

    cardNames = {}
    total = 0
    for k, _ in pairs(player.buff) do
        total = total + 1
        cardNames[total] = k
    end
    selIndex = 0
end

knapsackUpdate = function ()
    T = T + love.timer.getDelta()

    local downI = love.keyboard.isDown('i')
    if downI and lastDownI == false then
        -- Exit
        return false
    end
    lastDownI = downI

    if total ~= 0 then
        local downL = love.keyboard.isDown('left')
        local downR = love.keyboard.isDown('right')
        local downU = love.keyboard.isDown('up')
        local downD = love.keyboard.isDown('down')
        if downL and lastDownL == false then
            local last = selIndex
            selIndex = selIndex - 3
            if selIndex < 0 then
                selIndex = total - total % 3 + selIndex
                    + (selIndex + 3 < total % 3 and 3 or 0)
            end
            if selIndex == last then selIndex = (selIndex + total - 1) % total end
        end
        if downR and lastDownR == false then
            local last = selIndex
            selIndex = selIndex + 3
            if selIndex >= total then
                selIndex = selIndex % 3
            end
            if selIndex == last then selIndex = (selIndex + 1) % total end
        end
        if downU and lastDownU == false then
            selIndex = (selIndex + total - 1) % total
        end
        if downD and lastDownD == false then
            selIndex = (selIndex + 1) % total
        end
        lastDownL = downL
        lastDownR = downR
        lastDownU = downU
        lastDownD = downD
    end

    return true
end

knapsackDraw = function ()
    love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
    love.graphics.rectangle('fill', 0, 0, W, H)

    local row, col = selIndex % 3, math.floor(selIndex / 3)
    love.graphics.setColor(0.6, 0.7, 0.3, 0.8)
    love.graphics.rectangle('fill',
        W * (col + 1) / 6 - 12, H * (0.291 + 0.15 * row) - 12,
        24, 24)

    love.graphics.setColor(1, 1, 1)

    spritesheet.text(
        string.format('Knapsack\nMax Health: %d  Memory: %d',
            player.healthMax, player.memory),
        W * 0.1, H * 0.1
    )

    local memUsed = 0
    for i = 1, total do
        local row, col = (i - 1) % 3, math.floor((i - 1) / 3)
        spritesheet.drawCen(buff[cardNames[i]].icon, W * (col + 1) / 6, H * (0.225 + 0.15 * row))
        if player.buff[cardNames[i]].equipped then
        end
    end

    if total ~= 0 then
        spritesheet.text(cardNames[selIndex + 1], W * 0.15, H * 0.7, 1)
    end

    spritesheet.flush()
end
