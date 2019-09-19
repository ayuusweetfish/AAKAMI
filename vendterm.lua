local spritesheet = require 'spritesheet'
local input = require 'input'
local ecs = require 'ecs/ecs'
local buff = require 'mech/buff'
local vend = require 'mech/vend'

local player, playerEntity

local term      -- Current terminal entity
local lastDownY
local lastDownX
local lastDownL, lastDownR
local lastDownU, lastDownD
local T         -- Total time

local selRow, selCol = 0, 0 -- Persist

local inCardsPanel
local cardNames
local total
local selIndex = 0  -- Persists

local isMenu, menuItem  -- Is in sell/upgrade menu

local refreshCards = function ()
    cardNames = {}
    total = 0
    for k, v in pairs(player.buff) do
        if not v.equipped then
            total = total + 1
            cardNames[total] = k
        end
    end
end

vendTermReset = function (_term)
    playerEntity = ecs.components.player[1]
    player = playerEntity.player

    term = _term
    lastDownY = nil
    lastDownX = nil
    lastDownL, lastDownR = nil, nil
    lastDownU, lastDownD = nil, nil
    T = 0
    inCardsPanel = false

    refreshCards()
    isMenu, menuItem = false, 0
end

local mainUpdate = function ()
    local downY = input.Y()
    if downY and lastDownY == false then
        -- Exit
        return false
    end
    lastDownY = downY

    local downX = input.X()
    if downX and lastDownX == false then
        local selIndex = selRow * 2 + selCol
        if selIndex == 0 then
            local price = vend.heal
            if player.coin >= price and playerEntity.health.val < playerEntity.health.max then
                player.coin = player.coin - price
                playerEntity.health.val = playerEntity.health.val + 1
            end
        elseif selIndex == 1 then
            local price = vend.healthMax(playerEntity.health.max)
            if player.coin >= price then
                player.coin = player.coin - price
                playerEntity.health.max = playerEntity.health.max + 1
                playerEntity.health.val = playerEntity.health.val + 1
            end
        elseif selIndex == 2 then
            local price = vend.memory(player.memory)
            if player.coin >= price then
                player.coin = player.coin - price
                player.memory = player.memory + 1
            end
        elseif selIndex == 3 then
            inCardsPanel = true
        end
    end
    lastDownX = downX

    local downL = input.L()
    local downR = input.R()
    local downU = input.U()
    local downD = input.D()
    if downL and lastDownL == false then selCol = 1 - selCol end
    if downR and lastDownR == false then selCol = 1 - selCol end
    if downU and lastDownU == false then selRow = 1 - selRow end
    if downD and lastDownD == false then selRow = 1 - selRow end
    lastDownL = downL
    lastDownR = downR
    lastDownU = downU
    lastDownD = downD

    return true
end

local cardsUpdate = function ()
    local downY = input.Y()
    if downY and lastDownY == false then
        lastDownY = downY
        if isMenu then isMenu = false else return false end
    end
    lastDownY = downY

    local downX = input.X()

    if isMenu then
        if downX and lastDownX == false then
            local selName = cardNames[selIndex + 1]
            local selPlayerBuff = player.buff[selName]
            local selCard = buff[selName]
            local selMem = selCard.memory[selPlayerBuff.level]
            if menuItem == 0 then
                -- Upgrade
                if selPlayerBuff.level < #selCard.args and
                    player.coin >= selCard.upgrade[selPlayerBuff.level]
                then
                    player.coin = player.coin - selCard.upgrade[selPlayerBuff.level]
                    selPlayerBuff.level = selPlayerBuff.level + 1
                end
            else
                -- Sell
                player.buff[selName] = nil
                player.coin = player.coin + selCard.sellrate
                refreshCards()
                if selIndex >= total then selIndex = math.max(0, total - 1) end
                isMenu = false
            end
        end

        local downL = input.L()
        local downR = input.R()
        local downU = input.U()
        local downD = input.D()
        if downL and lastDownL == false then menuItem = 1 - menuItem end
        if downR and lastDownR == false then menuItem = 1 - menuItem end
        if downU and lastDownU == false then menuItem = 1 - menuItem end
        if downD and lastDownD == false then menuItem = 1 - menuItem end
        lastDownL = downL
        lastDownR = downR
        lastDownU = downU
        lastDownD = downD
    else
        if downX and lastDownX == false and total > 0 then
            isMenu, menuItem = true, 0
        end

        if total ~= 0 then
            selIndex, lastDownL, lastDownR, lastDownU, lastDownD =
                moveLRUD(total, selIndex, lastDownL, lastDownR, lastDownU, lastDownD)
        end
    end

    lastDownX = downX

    return true
end

vendTermUpdate = function ()
    T = T + love.timer.getDelta()

    if inCardsPanel then inCardsPanel = cardsUpdate() return true
    else return mainUpdate() end
end

local mainDraw = function ()
    love.graphics.setColor(0.6, 0.7, 0.3, 0.8)
    love.graphics.rectangle('fill',
        W * (0.15 + 0.35 * selCol), H * (0.2 + 0.35 * selRow),
        W * 0.35, H * 0.35)

    love.graphics.setColor(1, 1, 1)
    spritesheet.text('HEAL', W * 0.2, H * 0.25)
    spritesheet.text('SOLIDIFY', W * 0.55, H * 0.25)
    spritesheet.text('ADD MEM', W * 0.2, H * 0.6)
    spritesheet.text('UPGRADE/SELL\nCARDS', W * 0.55, H * 0.6)

    spritesheet.text(
        string.format('+1\n%d coins', vend.heal),
        W * 0.2, H * 0.35)
    spritesheet.text(
        string.format('%d -> %d\n%d coins',
            playerEntity.health.max, playerEntity.health.max + 1,
            vend.healthMax(playerEntity.health.max)),
        W * 0.55, H * 0.35)
    spritesheet.text(
        string.format('%d -> %d\n%d coins',
            player.memory, player.memory + 1, vend.memory(player.memory)),
        W * 0.2, H * 0.7)
end

local cardsDraw = function ()
    love.graphics.setColor(1, 1, 1)

    local selName = cardNames[selIndex + 1]
    local selPlayerBuff = player.buff[selName]
    local selCard = buff[selName]
    local selMem = selCard and selCard.memory[selPlayerBuff.level] or nil

    if isMenu then
        drawOneCard(selCard, W * 0.25, H * 0.4)

        spritesheet.text(
            string.format('%s (Lv. %d)', selName, selPlayerBuff.level),
            W * 0.45, H * 0.25, 1)

        love.graphics.setColor(0.6, 0.7, 0.3, 0.8)
        love.graphics.rectangle('fill',
            W * 0.1, H * (0.6 + menuItem * 0.15),
            W * 0.8, H * 0.15)

        love.graphics.setColor(1, 1, 1)
        spritesheet.text('UPGRADE', W * 0.1 + 4, H * 0.6 + 2)
        local upgradeText
        if selPlayerBuff.level < #selCard.args then
            upgradeText = string.format('%d coins | val: %d -> %d | mem: %d -> %d',
                selCard.upgrade[selPlayerBuff.level],
                selCard.args[selPlayerBuff.level],
                selCard.args[selPlayerBuff.level + 1],
                selCard.memory[selPlayerBuff.level],
                selCard.memory[selPlayerBuff.level + 1])
        else
            upgradeText = 'Maximum'
        end
        spritesheet.text(upgradeText, W * 0.1 + 4, H * 0.6 + 17)
        spritesheet.text('SELL', W * 0.1 + 4, H * 0.75 + 2)
        spritesheet.text(
            tonumber(selCard.sellrate) .. ' coins',
            W * 0.1 + 4, H * 0.75 + 17)

    else
        drawCardList(cardNames, player, selIndex, 0.3)

        -- Card description
        if total ~= 0 then
            spritesheet.text(
                string.format('%s (Lv. %d)', selName, selPlayerBuff.level),
                W * 0.15, H * 0.7, 1)
        end
    end

    love.graphics.setColor(1, 1, 1)
    spritesheet.flush()
end

vendTermDraw = function ()
    love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
    love.graphics.rectangle('fill', 0, 0, W, H)

    if inCardsPanel then cardsDraw()
    else mainDraw() end

    love.graphics.setColor(1, 1, 1)
    spritesheet.text(
        string.format('Health: %d/%d  Memory: %d  Coins: %d',
            playerEntity.health.val, playerEntity.health.max, player.memory, player.coin),
        W * 0.1, H * 0.1
    )
    spritesheet.flush()
end
