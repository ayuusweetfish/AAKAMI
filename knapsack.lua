local spritesheet = require 'spritesheet'
local ecs = require 'ecs/ecs'
local buff = require 'mech/buff'
require 'ui_utils'

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
    print(ecs)
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

    if selIndex >= total then selIndex = math.max(0, total - 1) end
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
    if downU and lastDownU == false and total > 0 then
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

    if total > 0 then
        selIndex, lastDownLa, lastDownRa, lastDownUa, lastDownDa =
            moveLRUD(total, selIndex, lastDownLa, lastDownRa, lastDownUa, lastDownDa)
    end

    return true
end

knapsackDraw = function ()
    love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
    love.graphics.rectangle('fill', 0, 0, W, H)

    -- Card list
    drawCardList(cardNames, player, selIndex, 0.3)

    -- Memory bar
    -- TODO: Draw a bar!
    spritesheet.text(
        string.format('Memory: %d/%d',
            memUsed, player.memory),
        W * 0.1, H * 0.1
    )
    if total > 0 then
        local selName = cardNames[selIndex + 1]
        local selPlayerBuff = player.buff[selName]
        local selMem = buff[selName].memory[selPlayerBuff.level]
        spritesheet.text(
            string.format('-> %d/%d',
                memUsed, player.memory,
                memUsed + selMem * (selPlayerBuff.equipped and -1 or 1), player.memory),
            W * 0.4, H * 0.1
        )

        -- Card description
        spritesheet.text(
            string.format('%s (Lv. %d)', selName, selPlayerBuff.level),
            W * 0.15, H * 0.7, 1)
    end

    spritesheet.flush()
end
