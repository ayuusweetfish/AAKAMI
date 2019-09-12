local spritesheet = require 'spritesheet'
local ecs = require 'ecs/ecs'

local IS_DESKTOP = true

local W = 320
local H = 240
local SCALE = 1

if IS_DESKTOP then SCALE = 3 end

local sidelen = 16

local shader
local canvas

local T = 0
local ecs_update_count = 0

local playerEntity
local dispSystem

local w = {}

function love.conf(t)
    t.window.physics = false
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
        dim = { sidelen * 2, sidelen * 2, 14, 14 },
        vel = { 0, 0 },
        sprite = { name = 'quq5' },
        player = {},
        colli = { passive = true }
    })

    -- Enemy
    ecs.addEntity({
        dim = { sidelen * 5.5, sidelen * 5.5, 14, 14 },
        vel = { 0, 0 },
        sprite = { name = 'quq6' },
        enemy = {},
        colli = { passive = true, block = true }
    })

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
                colli = { block = (i ~= 4) }
            })
        end
    end
    for i = 14, 30 do
        for j = 14, 30 do
            ecs.addEntity({
                dim = { sidelen * i, sidelen * j, sidelen, sidelen },
                sprite = { name = 'quq1' },
                colli = { block = true }
            })
        end
    end
    ecs.addSystem(1, require('ecs/sys_player')())
    ecs.addSystem(1, require('ecs/sys_enemy')())
    ecs.addSystem(1, require('ecs/sys_vel')())
    ecs.addSystem(1, require('ecs/sys_colli')())
    dispSys = ecs.addSystem(2, require('ecs/sys_disp')(spritesheet))
end

function love.update()
    T = T + love.timer.getDelta()

    local t = math.floor(T / 1)
    if w[t] ~= nil then
        ecs.removeEntity(w[t])
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
    love.graphics.setCanvas(canvas)
    love.graphics.clear(1, 1, 1)
    love.graphics.setColor(1, 1, 1)
    ecs.update(2)
    spritesheet.flush()

    love.graphics.setCanvas(nil)
    love.graphics.setShader(shader)
    love.graphics.draw(canvas, 0, 0, 0, SCALE, SCALE)
    love.graphics.setShader(nil)
end
