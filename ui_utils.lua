local spritesheet = require 'spritesheet'
local buff = require 'mech/buff'

moveLRUD = function (total, selIndex, lastDownLa, lastDownRa, lastDownUa, lastDownDa)
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
    return selIndex, downL, downR, downU, downD
end

drawCardList = function (cardNames, player, selIndex, offsetY)
    local row, col = selIndex % 3, math.floor(selIndex / 3)
    love.graphics.setColor(0.6, 0.7, 0.3, 0.8)
    love.graphics.rectangle('fill',
        W * (col + 1) / 6 - 16, H * (0.3 + 0.15 * row) - 16,
        32, 32)

    love.graphics.setColor(1, 1, 1)
    for i = 1, #cardNames do
        local row, col = (i - 1) % 3, math.floor((i - 1) / 3)
        local name = cardNames[i]
        local x, y = W * (col + 1) / 6, H * (offsetY + 0.15 * row)
        spritesheet.drawCen(buff[name].icon, x, y)
        if player.buff[name].equipped then
            spritesheet.drawCen('quq8', x, y)
        end
    end
end

drawOneCard = function (card, x, y, enlarge)
    local scale = (enlarge and 3 or 2)
    spritesheet.drawCen(card.icon, x, y, scale)
end
