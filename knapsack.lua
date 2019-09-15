local spritesheet = require 'spritesheet'
local ecs = require 'ecs/ecs'
local buff = require 'mech/buff'

local player

local term      -- Current terminal entity
local lastDownI -- Is key <I> pressed last frame
local lastDownU -- Is key <U> pressed last frame
local lastDownLa, lastDownRa
local lastDownUa, lastDownDa
local T         -- Total time

local cardNames
local total
local selIndex = 0  -- Persists
local memUsed

knapsackReset = function (_term)
    player = ecs.components.player[1].player

    term = _term
    lastDownI = nil
    lastDownLa, lastDownRa = nil, nil
    lastDownUa, lastDownDa = nil, nil
    T = 0

    cardNames = {}
    total = 0
    memUsed = 0
    for k, v in pairs(player.buff) do
        total = total + 1
        cardNames[total] = k
        if v.equipped then
            memUsed = memUsed + buff[k].memory[v.level]
        end
    end
end

knapsackUpdate = function ()
    T = T + love.timer.getDelta()

    local downI = love.keyboard.isDown('i')
    if downI and lastDownI == false then
        -- Exit
        return false
    end
    lastDownI = downI

    local downU = love.keyboard.isDown('u')
    if downU and lastDownU == false then
        -- Equip/unequip
        local selName = cardNames[selIndex + 1]
        local selPlayerBuff = player.buff[selName]
        local memDelta = buff[selName].memory[selPlayerBuff.level]
        local newMemUsed = memUsed +
            (selPlayerBuff.equipped and -memDelta or memDelta)
        if newMemUsed <= player.memory then
            selPlayerBuff.equipped = not selPlayerBuff.equipped
            memUsed = newMemUsed
        end
    end
    lastDownU = downU

    if total ~= 0 then
        local downL = love.keyboard.isDown('left')
        local downR = love.keyboard.isDown('right')
        local downU = love.keyboard.isDown('up')
        local downD = love.keyboard.isDown('down')
        if downL and lastDownLa == false then
            local last = selIndex
            selIndex = selIndex - 3
            if selIndex < 0 then
                selIndex = total - total % 3 + selIndex
                    + (selIndex + 3 < total % 3 and 3 or 0)
            end
            if selIndex == last then selIndex = (selIndex + total - 1) % total end
        end
        if downR and lastDownRa == false then
            local last = selIndex
            selIndex = selIndex + 3
            if selIndex >= total then
                selIndex = selIndex % 3
            end
            if selIndex == last then selIndex = (selIndex + 1) % total end
        end
        if downU and lastDownUa == false then
            selIndex = (selIndex + total - 1) % total
        end
        if downD and lastDownDa == false then
            selIndex = (selIndex + 1) % total
        end
        lastDownLa = downL
        lastDownRa = downR
        lastDownUa = downU
        lastDownDa = downD
    end

    return true
end

knapsackDraw = function ()
    love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
    love.graphics.rectangle('fill', 0, 0, W, H)

    local row, col = selIndex % 3, math.floor(selIndex / 3)
    love.graphics.setColor(0.6, 0.7, 0.3, 0.8)
    love.graphics.rectangle('fill',
        W * (col + 1) / 6 - 16, H * (0.3 + 0.15 * row) - 16,
        32, 32)

    love.graphics.setColor(1, 1, 1)

    -- Card list
    for i = 1, total do
        local row, col = (i - 1) % 3, math.floor((i - 1) / 3)
        local name = cardNames[i]
        local x, y = W * (col + 1) / 6, H * (0.3 + 0.15 * row)
        spritesheet.drawCen(buff[name].icon, x, y)
        if player.buff[name].equipped then
            spritesheet.drawCen('quq8', x, y)
        end
    end

    -- Memory bar
    -- TODO: Draw a bar!
    local selName = cardNames[selIndex + 1]
    local selPlayerBuff = player.buff[selName]
    local selMem = buff[selName].memory[selPlayerBuff.level]
    spritesheet.text(
        string.format('Memory: %d/%d -> %d/%d',
            memUsed, player.memory,
            memUsed + selMem * (selPlayerBuff.equipped and -1 or 1), player.memory),
        W * 0.1, H * 0.1
    )

    -- Card description
    if total ~= 0 then
        spritesheet.text(
            string.format('%s (Lv. %d)', selName, selPlayerBuff.level),
            W * 0.15, H * 0.7, 1)
    end

    spritesheet.flush()
end
