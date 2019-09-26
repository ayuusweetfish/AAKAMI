local spritesheet = require 'spritesheet'
local audio = require 'audio'
local input = require 'input'
local ecs = require 'ecs/ecs'
local buff = require 'mech/buff'

local player

local term      -- Current terminal entity
local lastDownY
local lastDownL, lastDownR
local T         -- Total time
local selIndex
local cardNames
local cards

-- Persists, used to display introduction to the knapsack
-- 0: first-time visit
-- 1: first-time visit, picked card, showing knapsack introduction
-- 2: other cases
local knapsackIntro = 0

buffTermReset = function (_term)
    player = ecs.components.player[1].player

    term = _term
    lastDownY = nil
    lastDownL, lastDownR = nil, nil
    T = 0
    selIndex = 1

    local pool = {}
    for k, v in pairs(buff) do
        if player.buff[k] == nil and
            (v.prereq == nil or player.buff[v.prereq] ~= nil)
        then
            pool[#pool + 1] = k
        end
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

    local downY = input.Y()
    if downY and lastDownY == false then
        audio.play('confirm')

        if knapsackIntro ~= 1 then
            -- Card get!
            player.buff[cardNames[selIndex]] = { level = 1, equipped = false }
            term.sprite.name = 'tileset3#offterm'
        end
        
        if knapsackIntro == 0 then
            knapsackIntro = 1
        else
            knapsackIntro = 2
            return false
        end
    end
    lastDownY = downY

    local downL = input.L() or input.U()
    local downR = input.R() or input.D()
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

    if knapsackIntro == 1 then
        spritesheet.drawCen('gamepad1', W * 0.25, H * 0.45)
        spritesheet.text('Open your knapsack to equip!', W * 0.3, H * 0.45 - 8)
    else
        spritesheet.text('TAKE ONE!', W * 0.125, H * 0.1, W, 2)
        for i = 1, 3 do
            drawOneCard(
                cards[i], W * (i * 0.3 - 0.1), H * 0.4,
                i == selIndex)
        end
        spritesheet.text(cards[selIndex].name, W * 0.15, H * 0.625)
        spritesheet.text(cards[selIndex].desc, W * 0.15, H * 0.7, W * 0.7)
    end

    spritesheet.draw('gamepad1', W * 0.7, H * 0.9)
    spritesheet.text('Confirm', W * 0.7 + 20, H * 0.9)

    spritesheet.flush()
end
