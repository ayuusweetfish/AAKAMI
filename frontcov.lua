local spritesheet = require 'spritesheet'
local input = require 'input'

local lastDownB = false
local cutscene = 1
local T = 0

frontCovUpdate = function ()
    if input.back() then love.event.quit() end

    T = T + love.timer.getDelta()

    local downB = input.B()
    if downB and not lastDownB then
        -- Trigger
        cutscene = cutscene + 1
        T = 0
        if cutscene == 3 then
            -- Game start!!
            return false
        end
    end
    lastDownB = downB

    return true
end

frontCovDraw = function ()
    if cutscene == 1 then
        spritesheet.draw(
            'illustration' .. tonumber(math.floor(T / 0.25) % 24 + 1),
            0, 0)
    elseif cutscene == 2 then
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle('fill', 0, 0, W, H)
        love.graphics.setColor(1, 1, 1)
        local a = input.A() and 2 or 0
        local x = input.X() and 2 or 0
        local y = input.Y() and 2 or 0
        spritesheet.draw('gamepad4', W * 0.4, H * 0.35 + x)
        spritesheet.text('Attack', W * 0.4 + 20, H * 0.35 + x)
        spritesheet.draw('gamepad3', W * 0.4, H * 0.45 + a)
        spritesheet.text('SHIFT!', W * 0.4 + 20, H * 0.45 + a)
        spritesheet.draw('gamepad1', W * 0.4, H * 0.55 + y)
        spritesheet.text('Knapsack', W * 0.4 + 20, H * 0.55 + y)
    end

    if T >= 2 then
        spritesheet.drawCen('gamepad2', W * 0.85, H * 0.8)
    end
end
