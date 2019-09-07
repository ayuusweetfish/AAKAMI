local IS_DESKTOP = true

local W = 320
local H = 240
local SCALE = 1

if IS_DESKTOP then SCALE = 3 end

local sidelen = 20

local shader
local canvas

local T = 0

function love.conf(t)
    t.window.physics = false
end

function love.load()
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
    T = T + love.timer.getDelta()

    if love.keyboard.isDown('escape') then
        love.event.quit()
    end
end

function love.draw()
    love.graphics.setCanvas(canvas)
    love.graphics.clear(1, 1, 1)
    love.graphics.setColor(0.8, 0.96, 0.92)
    for x = 0, math.floor(W / sidelen) - 1 do
        for y = x % 2, math.floor(H / sidelen), 2 do
            love.graphics.rectangle('fill',
                sidelen * x, sidelen * y, sidelen, sidelen)
        end
    end

    love.graphics.setCanvas(nil)
    love.graphics.setShader(shader)
    love.graphics.draw(canvas, 0, 0, 0, SCALE, SCALE)
    love.graphics.setShader(nil)
end
