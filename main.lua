local spritesheet = require 'spritesheet'
local ecs = require 'ecs/ecs'
require 'buffterm'
require 'vendterm'
require 'knapsack'

local levelLoad = require 'levels/load'

local IS_DESKTOP = true

W = 320
H = 240
local SCALE = IS_DESKTOP and 3 or 1

local sidelen = 16

local shader
local canvas

local T = 0
local ecs_update_count = 0

local playerEntity, player
local gameOver

local dispSystem

local termUpdate, termDraw = nil, nil

local lastDownI
local knapsackRunning

local isSlow
local lastDownZ

local w = {}

function love.conf(t)
    t.window.physics = false
end

local buffTermInteraction = function (term)
    lastDownI = true
    buffTermReset(term)
    termUpdate, termDraw = buffTermUpdate, buffTermDraw
end

local vendTermInteraction = function (term)
    lastDownI = true
    vendTermReset(term)
    termUpdate, termDraw = vendTermUpdate, vendTermDraw
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
    spritesheet.loadImage('images/triangle.png')

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

    -- Audio
    local source = love.audio.newSource('audio/Beverage Battle.ogg', 'static')
    source:setLooping(true)
    love.audio.play(source)

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
end

function love.update()
    if termUpdate ~= nil then
        if not termUpdate() then termUpdate, termDraw = nil, nil end
        return
    elseif knapsackRunning then
        knapsackRunning = knapsackUpdate()
        return
    end

    local downZ = love.keyboard.isDown('z')
    if downZ and not lastDownZ then isSlow = not isSlow end
    lastDownZ = downZ

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
        if love.keyboard.isDown('u') then
            ecs.reset()
            gameOver = false
            love.load()
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

    local downI = love.keyboard.isDown('i')
    if downI and not lastDownI then
        knapsackReset()
        knapsackRunning = true
    end
    lastDownI = downI

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

    if gameOver then
        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        love.graphics.rectangle('fill', 0, 0, W, H)
        love.graphics.setColor(1, 1, 1)
        spritesheet.text('GAME OVER\nPress X to retry', W * 0.2, H * 0.35, 2)
    elseif termDraw ~= nil then termDraw()
    elseif knapsackRunning then knapsackDraw()
    else
        -- HUD
        spritesheet.text(
            string.format('Health  %d/%d\nEnergy  %d/%d',
                playerEntity.health.val, playerEntity.health.max,
                player.energy, player.energyMax),
            6, H * 0.1)
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
