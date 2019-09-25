local spritesheet = require 'spritesheet'
local audio = require 'audio'
local input = require 'input'
local ecs = require 'ecs/ecs'
local buff = require 'mech/buff'
require 'ui_utils'

local player

local term      -- Current terminal entity
local lastDownY
local lastDownX
local lastDownL, lastDownR
local lastDownU, lastDownD
local T         -- Total time

local cardNames
local total
local selIndex = 0  -- Persists
local memUsed

knapsackReset = function (_term)
    player = ecs.components.player[1].player

    term = _term
    lastDownY = nil
    lastDownL, lastDownR = nil, nil
    lastDownU, lastDownD = nil, nil
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

    local downY = input.Y()
    if downY and lastDownY == false then
        -- Exit
        return false
    end
    lastDownY = downY

    local downX = input.X()
    if downX and lastDownX == false and total > 0 then
        -- Equip/unequip
        local selName = cardNames[selIndex + 1]
        local selPlayerBuff = player.buff[selName]
        local memDelta = buff[selName].memory[selPlayerBuff.level]
        local newMemUsed = memUsed +
            (selPlayerBuff.equipped and -memDelta or memDelta)
        if newMemUsed <= player.memory then
            selPlayerBuff.equipped = not selPlayerBuff.equipped
            memUsed = newMemUsed
            audio.play('menu')
        end
        -- TODO: Unavailable sound effect?
    end
    lastDownX = downX

    if total > 0 then
        selIndex, lastDownL, lastDownR, lastDownU, lastDownD =
            moveLRUD(total, selIndex, lastDownL, lastDownR, lastDownU, lastDownD)
    end

    return true
end

knapsackDraw = function ()
    love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
    love.graphics.rectangle('fill', 0, 0, W, H)

    -- Card list
    drawCardList(cardNames, player, selIndex, 0.25)

    -- Memory bar
    local changeRangeL, changeRangeR = -1, -1

    if total > 0 then
        local selName = cardNames[selIndex + 1]
        local selPlayerBuff = player.buff[selName]
        local selCard = buff[selName]
        local selMem = selCard.memory[selPlayerBuff.level]
        if selPlayerBuff.equipped then
            changeRangeL, changeRangeR = memUsed - selMem + 1, memUsed
        else
            changeRangeL, changeRangeR = memUsed + 1, memUsed + selMem
        end

        -- Card description
        spritesheet.text(
            string.format('%s (Lv. %d)', selCard.name, selPlayerBuff.level),
            W * 0.15, H * 0.585)
        spritesheet.text(selCard.desc, W * 0.15, H * 0.65, W * 0.7)
    end

    for i = 1, player.memory do
        local num = (i <= memUsed and 1 or 2)
        if i >= changeRangeL and i <= changeRangeR then num = num + 2 end
        spritesheet.draw(
            'memory' .. tostring(num),
            W * 0.1 + 15 * (i - 1), H * 0.08
        )
    end
    if changeRangeR then
        for i = player.memory + 1, changeRangeR do
            spritesheet.draw(
                'memory5',
                W * 0.1 + 15 * (i - 1), H * 0.08
            )
        end
    end

    -- Key hints
    local equipped = false
    spritesheet.draw('gamepad4', W * 0.7, H * 0.82)
    spritesheet.text(equipped and 'Unequip' or 'Equip', W * 0.7 + 20, H * 0.82)
    spritesheet.draw('gamepad1', W * 0.7, H * 0.9)
    spritesheet.text('Back', W * 0.7 + 20, H * 0.9)

    spritesheet.flush()
end
