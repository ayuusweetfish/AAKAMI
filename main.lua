local spritesheet = require 'spritesheet'
local input = require 'input'
local ecs = require 'ecs/ecs'
require 'buffterm'
require 'vendterm'
require 'knapsack'
require 'frontcov'

local levelLoad = require 'levels/load'

local IS_DESKTOP = true

W = 320
H = 240
local SCALE = IS_DESKTOP and 3 or 1

local sidelen = 16

local shader
local canvas

local frontCovRunning = true

local T
local ecs_update_count

local playerEntity, player
local gameOver

local dispSystem

local termUpdate, termDraw = nil, nil

local lastDownY
local knapsackRunning

local isSlow
local lastDownKbZ

local w = {}

function love.conf(t)
    t.window.physics = false
end

local buffTermInteraction = function (term)
    lastDownY = true
    buffTermReset(term)
    termUpdate, termDraw = buffTermUpdate, buffTermDraw
end

local vendTermInteraction = function (term)
    lastDownY = true
    vendTermReset(term)
    termUpdate, termDraw = vendTermUpdate, vendTermDraw
end

local reinitializeGameCore = function ()
    playerEntity = levelLoad(
        require('levels/level1'),
        buffTermInteraction,
        vendTermInteraction
    )
    player = playerEntity.player

    ecs.addSystem(1, require('ecs/sys_spcpart')())
    ecs.addSystem(1, require('ecs/sys_player')())
    ecs.addSystem(1, require('ecs/sys_enemy')())
    ecs.addSystem(1, require('ecs/sys_follow')())
    ecs.addSystem(1, require('ecs/sys_vel')())
    ecs.addSystem(1, require('ecs/sys_bullet')())
    ecs.addSystem(1, require('ecs/sys_colli')())
    ecs.addSystem(1, require('ecs/sys_term')())
    ecs.addSystem(1, require('ecs/sys_door')())
    ecs.addSystem(1, require('ecs/sys_area')())
    dispSys = ecs.addSystem(2, require('ecs/sys_disp')(spritesheet))

    T = 0
    ecs_update_count = 0
end

local initializeGameplay = function ()
    -- Audio
    local source = love.audio.newSource('audio/Beverage Battle.ogg', 'static')
    source:setLooping(true)
    love.audio.play(source)

    reinitializeGameCore()
end

function love.load()
    spritesheet.loadCrunch('images/char.bin')
    spritesheet.loadCrunch('images/quq.bin')
    spritesheet.initializeTileset('tileset3', 16)
    spritesheet.cropFromTileset('tileset3', 86, 32, 32, 'offterm')
    spritesheet.cropFromTileset('tileset3', 88, 32, 32, 'buffterm')
    spritesheet.cropFromTileset('tileset3', 90, 32, 32, 'vendterm')
    spritesheet.cropFromTileset('tileset3', 184, 16, 32, 'doorv')
    spritesheet.cropFromTileset('tileset3', 230, 32, 32, 'doorh')
    spritesheet.loadImage('images/gamepad1.png')
    spritesheet.loadImage('images/gamepad2.png')
    spritesheet.loadImage('images/gamepad3.png')
    spritesheet.loadImage('images/gamepad4.png')
    spritesheet.loadImage('images/requirekey.png')
    spritesheet.loadImage('images/life1.png')
    spritesheet.loadImage('images/life2.png')
    spritesheet.loadImage('images/font.png')
    spritesheet.initializeTileset('font', 6, 8)

    love.window.setMode(W * SCALE, H * SCALE)
    love.graphics.setDefaultFilter('nearest', 'nearest')

    local fshadersrc = [[
        extern float T;
        vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
        {
            return Texel(tex, texture_coords);
        }
    ]]
    local vshadersrc = [[
        vec4 position(mat4 transform_projection, vec4 vertex_position)
        {
            return transform_projection * vertex_position;
        }
    ]]
    shader = love.graphics.newShader(fshadersrc, vshadersrc)

    canvas = love.graphics.newCanvas(W, H)
end

function love.update()
    if frontCovRunning then
        frontCovRunning = frontCovUpdate()
        if not frontCovRunning then initializeGameplay() end
        return
    elseif termUpdate ~= nil then
        if not termUpdate() then termUpdate, termDraw = nil, nil end
        return
    elseif knapsackRunning then
        knapsackRunning = knapsackUpdate()
        return
    end

    local downKbZ = love.keyboard.isDown('z')
    if downKbZ and not lastDownKbZ then isSlow = not isSlow end
    lastDownKbZ = downKbZ

    T = T + love.timer.getDelta() * (isSlow and 1.0 / 16 or 1)

    local t = math.floor(T / 1)
    if w[t] ~= nil then
        --ecs.removeEntity(w[t])
        w[t] = nil
    end

    if love.keyboard.isDown('escape') then
        love.event.quit()
    end

    if gameOver then
        if input.B() then
            ecs.reset()
            gameOver = false
            reinitializeGameCore()
        end
        return
    end

    local new_count = math.floor(T / ecs.dt)
    for i = 1, new_count - ecs_update_count do
        ecs.update(1)
    end
    ecs_update_count = new_count

    if playerEntity.health.val <= 0 then
        -- Game over!
        gameOver = true
        return
    end

    local downY = input.Y()
    if downY and not lastDownY then
        knapsackReset()
        knapsackRunning = true
    end
    lastDownY = downY

    local camX, camY = dispSys.cam[1], dispSys.cam[2]
    local camDX, camDY =
        playerEntity.dim[1] + playerEntity.dim[3] - W / 2 - camX,
        playerEntity.dim[2] + playerEntity.dim[4] - H / 2 - camY
    local dsq = camDX * camDX + camDY * camDY
    if dsq < 0.5 then
        dispSys.cam[1], dispSys.cam[2] = camX + camDX, camY + camDY
    else
        dispSys.cam[1], dispSys.cam[2] = camX + camDX / 15, camY + camDY / 15
    end
end

function love.draw()
    if IS_DESKTOP then
        love.graphics.setCanvas(canvas)
    end
    love.graphics.clear(1, 1, 1)
    ecs.update(2)
    love.graphics.setColor(1, 1, 1)
    spritesheet.flush()

    if frontCovRunning then frontCovDraw()
    elseif gameOver then
        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        love.graphics.rectangle('fill', 0, 0, W, H)
        love.graphics.setColor(1, 1, 1)
        spritesheet.text('GAME OVER', W * 0.25, H * 0.35, 2)
        spritesheet.draw('gamepad2', W * 0.7, H * 0.9)
        spritesheet.text('Restart', W * 0.7 + 20, H * 0.9)
    elseif termDraw ~= nil then termDraw()
    elseif knapsackRunning then knapsackDraw()
    else
        -- HUD
        for i = 1, playerEntity.health.max do
            spritesheet.draw(
                i <= playerEntity.health.val and 'life1' or 'life2',
                i * 20 - 8, 12)
        end
        local x, y = 12, 32
        local w = player.energyMax + 2
        local w1 = player.energy + 2
        local h = 12
        love.graphics.setColor(0x3d / 255, 0x3d / 255, 0x3d / 255)
        love.graphics.rectangle('fill', x + 2, y, w - 4, h)
        love.graphics.rectangle('fill', x + 1, y + 1, w - 2, h - 2)
        love.graphics.rectangle('fill', x, y + 2, w, h - 4)
        local dw = function (r, g, b, w)
            if w < 3 then return end
            love.graphics.setColor(r / 255, g / 255, b / 255)
            love.graphics.rectangle('fill', x + 2, y + 1, w - 4, h - 2)
            love.graphics.rectangle('fill', x + 1, y + 2, w - 2, h - 4)
        end
        dw(0xbd, 0xbd, 0xbd, w)
        dw(0xc5, 0x60, 0x25, w1)
        dw(0xee, 0x8e, 0x2e, w1 - 1)
        love.graphics.setColor(0xfc / 255, 0xcb / 255, 0xa3 / 255)
        if w1 >= 6 then
            love.graphics.setLineWidth(1)
            love.graphics.setLineStyle('rough')
            love.graphics.line(x + 2, y + 2, x + w1 - 4, y + 2)
        end
    end

    love.graphics.setColor(1, 1, 1)
    spritesheet.flush()

    love.graphics.print(tostring(love.timer.getFPS()))

    if IS_DESKTOP then
        love.graphics.setCanvas(nil)
        love.graphics.setShader(shader)
        love.graphics.draw(canvas, 0, 0, 0, SCALE, SCALE)
        love.graphics.setShader(nil)
    end
end
