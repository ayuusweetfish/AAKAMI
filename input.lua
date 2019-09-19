local j = nil

local updateJoystick = function ()
    if love.joystick.getJoystickCount() > 0 then
        j = love.joystick.getJoysticks()[1]
    else j = nil end
end

love.joystickadded = updateJoystick
love.joystickremoved = updateJoystick

updateJoystick()

local input = {

-- Y / triangle
Y = function ()
    return love.keyboard.isDown('i') or (j and j:isGamepadDown('y') or false)
end,

-- B / circle
B = function ()
    return love.keyboard.isDown('k') or (j and j:isGamepadDown('b') or false)
end,

-- A / cross
A = function ()
    return love.keyboard.isDown('j') or (j and j:isGamepadDown('a') or false)
end,

-- X / square
X = function ()
    return love.keyboard.isDown('u') or (j and j:isGamepadDown('x') or false)
end,

L = function ()
    return love.keyboard.isDown('left') or (j and j:isGamepadDown('dpleft') or false)
end,

R = function ()
    return love.keyboard.isDown('right') or (j and j:isGamepadDown('dpright') or false)
end,

U = function ()
    return love.keyboard.isDown('up') or (j and j:isGamepadDown('dpup') or false)
end,

D = function ()
    return love.keyboard.isDown('down') or (j and j:isGamepadDown('dpdown') or false)
end,

back = function ()
    return love.keyboard.isDown('escape') or (j and j:isGamepadDown('back') or false)
end

}

input.direction = function ()
    if j then
        local x, y = j:getGamepadAxis('leftx'), j:getGamepadAxis('lefty')
        local dsq = x * x + y * y
        if dsq < 0.1 * 0.1 then return 0, 0
        elseif dsq > 1 then
            local d = math.sqrt(dsq)
            x, y = x / d, y / d
        end
        return x, y
    else
        local x, y = 0, 0
        if input.L() then x = x - 1 end
        if input.R() then x = x + 1 end
        if input.U() then y = y - 1 end
        if input.D() then y = y + 1 end
        if x ~= 0 and y ~= 0 then
            x = x / 1.414213562
            y = y / 1.414213562
        end
        return x, y
    end
end

return input
