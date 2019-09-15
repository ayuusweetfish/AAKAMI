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

local selRow, selCol = 0, 0 -- Kept between different uses

local inCardsPanel

vendTermReset = function (_term)
    player = ecs.components.player[1].player

    term = _term
    lastDownI = nil
    lastDownU = nil
    lastDownLa, lastDownRa = nil, nil
    lastDownUa, lastDownDa = nil, nil
    T = 0
    inCardsPanel = false
end

local mainUpdate = function ()
    local downI = love.keyboard.isDown('i')
    if downI and lastDownI == false then
        -- Exit
        return false
    end
    lastDownI = downI

    local downU = love.keyboard.isDown('u')
    if downU and lastDownU == false then
        local selIndex = selRow * 2 + selCol
        if selIndex == 3 then
            inCardsPanel = true
        end
    end
    lastDownU = downU

    local downL = love.keyboard.isDown('left')
    local downR = love.keyboard.isDown('right')
    local downU = love.keyboard.isDown('up')
    local downD = love.keyboard.isDown('down')
    if downL and lastDownLa == false then selCol = 1 - selCol end
    if downR and lastDownRa == false then selCol = 1 - selCol end
    if downU and lastDownUa == false then selRow = 1 - selRow end
    if downD and lastDownDa == false then selRow = 1 - selRow end
    lastDownLa = downL
    lastDownRa = downR
    lastDownUa = downU
    lastDownDa = downD

    return true
end

local cardsUpdate = function ()
    local downI = love.keyboard.isDown('i')
    if downI and lastDownI == false then
        lastDownI = downI
        return false
    end
    lastDownI = downI

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
end

local cardsDraw = function ()
    love.graphics.setColor(1, 1, 1)
    spritesheet.text('CARDS!!', W * 0.2, H * 0.25)
end

vendTermDraw = function ()
    love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
    love.graphics.rectangle('fill', 0, 0, W, H)

    if inCardsPanel then cardsDraw()
    else mainDraw() end

    love.graphics.setColor(1, 1, 1)
    spritesheet.text(
        string.format('Max Health: %d  Memory: %d',
            player.healthMax, player.memory),
        W * 0.1, H * 0.1
    )
    spritesheet.flush()
end
