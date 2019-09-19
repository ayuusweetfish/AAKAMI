local j = nil

local updateJoystick = function ()
    if love.joystick.getJoystickCount() > 0 then
        j = love.joystick.getJoysticks()[1]
    else j = nil end
end

love.joystickadded = updateJoystick
love.joystickremoved = updateJoystick

updateJoystick()

return {

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

}
