local spritesheet = require 'spritesheet'
local ecs = require 'ecs/ecs'
local buff = require 'mech/buff'

local player

local term      -- Current terminal entity
local lastDownI -- Is key <I> pressed last frame
local lastDownL, lastDownR
local T         -- Total time
local selIndex
local cardNames
local cards

buffTermReset = function (_term)
    player = ecs.components.player[1].player

    term = _term
    lastDownI = nil
    lastDownL, lastDownR = nil, nil
    T = 0
    selIndex = 1

    local pool = {}
    for k, _ in pairs(buff) do
        if player.buff[k] == nil then pool[#pool + 1] = k end
    end

    if #pool < 3 then print('OvO') end
    local a = math.random(#pool - 2)
    local b = math.random(#pool - 1)
    local c = math.random(#pool)
    if b == a then b = #pool - 1 end
    if c == a or c == b then c = #pool end

    cardNames = { pool[a], pool[b], pool[c] }
    cards = { buff[pool[a]], buff[pool[b]], buff[pool[c]] }
end

buffTermUpdate = function ()
    T = T + love.timer.getDelta()

    local downI = love.keyboard.isDown('i')
    if downI and lastDownI == false then
        -- Card get!
        player.buff[cardNames[selIndex]] = 1

        term.sprite.name = 'quq1'
        return false
    end
    lastDownI = downI

    local downL = love.keyboard.isDown('left') or love.keyboard.isDown('up')
    local downR = love.keyboard.isDown('right') or love.keyboard.isDown('down')
    if downL and lastDownL == false then selIndex = (selIndex + 1) % 3 + 1 end
    if downR and lastDownR == false then selIndex = selIndex % 3 + 1 end
    lastDownL = downL
    lastDownR = downR

    return true
end

buffTermDraw = function ()
    love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
    love.graphics.rectangle('fill', 0, 0, W, H)
    love.graphics.setColor(1, 1, 1)
    for i = 1, 3 do
        spritesheet.drawCen(
            cards[i].icon, W * (i * 0.3 - 0.1), H * 0.35,
            i == selIndex and 4 or 3)
    end
    spritesheet.flush()
end
