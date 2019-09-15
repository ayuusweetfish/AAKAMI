local spritesheet = require 'spritesheet'
local ecs = require 'ecs/ecs'
require 'buffterm'
require 'vendterm'
require 'knapsack'

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
local dispSystem

local termUpdate, termDraw = nil, nil

local lastDownI
local knapsackRunning

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
    spritesheet.loadImage('images/ground1.png')
    spritesheet.loadImage('images/ground2.png')
    spritesheet.loadImage('images/ground3.png')
    spritesheet.loadCrunch('images/quq.bin')

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

    -- Ground
    for x = -10, 30 do
        for y = -10, 30 do
            local name
            if ((x + y) % 2 == 0) then name = 'ground1' else name = 'ground2' end
            ecs.addEntity({
                dim = { x * sidelen, y * sidelen, sidelen, sidelen },
                sprite = { name = name, z = -1 }
            })
        end
    end

    -- Player
    playerEntity = ecs.addEntity({
        dim = { sidelen * 2, sidelen * 2, 21, 21 },
        vel = { 0, 0 },
        sprite = { name = 'quq6' },
        player = {
            -- XXX: Get rid of this
            buff = {
                penetrate = { level = 2, equipped = false },
                rebound = { level = 1, equipped = false },
                dodge = { level = 1, equipped = false },
                rstarve = { level = 1, equipped = false },
                bstarve = { level = 1, equipped = false },
                fork = { level = 1, equipped = false },
                magazine = { level = 1, equipped = false },
                cannon = { level = 1, equipped = false }
            },
            coin = 500,
            colour = 0,
            memory = 4,
            health = 5, healthMax = 5,
            energy = 100, energyMax = 100
        },
        colli = { passive = true, tag = 2 }
    })
    player = playerEntity.player

    -- Enemy
    --[[for i = 1, 15 do
        ecs.addEntity({
            dim = { sidelen * (7 + i * 1.5), sidelen * 5.5, 21, 21 },
            vel = { 0, 0 },
            sprite = { name = 'quq6' },
            enemy = { interval = 60 },
            colli = { passive = true, tag = 4 }
        })
    end]]
    ecs.addEntity({
        dim = { sidelen * 9, sidelen * 5.5, 21, 21 },
        vel = { 0, 0 },
        sprite = { name = 'quq6' },
        enemy = { name = 'donut' },
        colli = { passive = true, tag = 4 }
    })

    -- Terminal
    for i = 1, 4 do
        ecs.addEntity({
            dim = { sidelen * 3, sidelen * (3 + 2 * i), sidelen, sidelen },
            sprite = { name = 'quq2' },
            colli = { block = true },
            term = {
                once = (i ~= 1),
                callback = (i == 1 and vendTermInteraction or buffTermInteraction),
                bubble = ecs.addEntity({
                    dim = { sidelen * 3, sidelen * (2 + 2 * i), sidelen, sidelen },
                    sprite = { name = 'quq9', z = 1 }
                })
            }
        })
    end

    -- Obstacles
    local walls = {{
        {4, 4}, {5, 4}, {6, 4}, {7, 4},
        {4, 5},                 {7, 5},
        {4, 6},                 {7, 6},
                {5, 7}
    }, {
                {5, 10}
    }, {
                {6, 9}
    }, {
                {7, 10}
    }}
    for i = 1, 4 do
        local h = sidelen
        if i == 3 then h = sidelen * 2 end
        for _, wall in ipairs(walls[i]) do
            w[#w + 1] = ecs.addEntity({
                dim = { sidelen * wall[1], sidelen * wall[2], sidelen, h },
                sprite = { name = 'quq' .. tostring(i) },
                colli = { block = (i ~= 4), tag = 1, fence = (i >= 2) }
            })
        end
    end
    for i = 14, 30 do
        for j = 14, 30 do
            ecs.addEntity({
                dim = { sidelen * i, sidelen * j, sidelen, sidelen },
                sprite = { name = 'quq1' },
                colli = { block = true, tag = 1 }
            })
        end
    end

    for i = 0, 31 do
        ecs.addEntity({
            dim = { sidelen * i, sidelen * -4, sidelen, sidelen },
            sprite = { name = 'quq1' },
            colli = { block = true, tag = 1 }
        })
        ecs.addEntity({
            dim = { sidelen * i, sidelen * 31, sidelen, sidelen },
            sprite = { name = 'quq1' },
            colli = { block = true, tag = 1 }
        })
    end
    for j = -4, 31 do
        ecs.addEntity({
            dim = { sidelen * -1, sidelen * j, sidelen, sidelen },
            sprite = { name = 'quq1' },
            colli = { block = true, tag = 1 }
        })
        ecs.addEntity({
            dim = { sidelen * 32, sidelen * j, sidelen, sidelen },
            sprite = { name = 'quq1' },
            colli = { block = true, tag = 1 }
        })
    end

    ecs.addSystem(1, require('ecs/sys_spcpart')())
    ecs.addSystem(1, require('ecs/sys_player')())
    ecs.addSystem(1, require('ecs/sys_enemy')())
    ecs.addSystem(1, require('ecs/sys_follow')())
    ecs.addSystem(1, require('ecs/sys_vel')())
    ecs.addSystem(1, require('ecs/sys_bullet')())
    ecs.addSystem(1, require('ecs/sys_colli')())
    ecs.addSystem(1, require('ecs/sys_term')())
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

    T = T + love.timer.getDelta()

    local t = math.floor(T / 1)
    if w[t] ~= nil then
        --ecs.removeEntity(w[t])
        w[t] = nil
    end

    if love.keyboard.isDown('escape') then
        love.event.quit()
    end

    local new_count = math.floor(T / ecs.dt)
    for i = 1, new_count - ecs_update_count do
        ecs.update(1)
    end
    ecs_update_count = new_count

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
    love.graphics.setColor(1, 1, 1)
    ecs.update(2)
    spritesheet.flush()

    if termDraw ~= nil then termDraw()
    elseif knapsackRunning then knapsackDraw()
    else
        -- HUD
        spritesheet.text(
            string.format('Health  %d/%d\nEnergy  %d/%d',
                player.health, player.healthMax,
                player.energy, player.energyMax),
            6, H * 0.1)
    end

    love.graphics.print(tostring(love.timer.getFPS()))

    if IS_DESKTOP then
        love.graphics.setCanvas(nil)
        love.graphics.setShader(shader)
        love.graphics.draw(canvas, 0, 0, 0, SCALE, SCALE)
        love.graphics.setShader(nil)
    end
end
