-- Array of sprite batches
local batches = {}

-- Map from names to sprite batches and rectangles
-- {
--     batch = <SpriteBatch>,
--     sx = <number>, sy = <number>,
--     sw = <number>, sh = <number>,  -- source rectangle
--     tx = <number>, ty = <number>,  -- destination origin
--     w = <number>, h = <number>     -- canvas size, all in pixels
-- }
local lookup = {}

local splitPath = function (path)
    local p = #path
    local q     -- p: last '/'; q: last '.' after p
    -- ord('/') == 47, ord('.') == 46
    while p >= 1 and path:byte(p) ~= 47 do
        if path:byte(p) == 46 and q == nil then q = p end
        p = p - 1
    end
    q = q or #path + 1
    return path:sub(1, p), path:sub(p + 1, q - 1)
end
--[[
print(splitPath('a/a/bb.cc'))
print(splitPath('aa/bb.cc'))
print(splitPath('aa/bb.cc'))
print(splitPath('aa/bb.'))
print(splitPath('aa/.cc'))
print(splitPath('a.a/bb'))
print(splitPath('aa/bb'))
print(splitPath('bb.cc'))
print(splitPath('bb'))
]]

local loadImage = function (path)
    local _, name = splitPath(path)
    local img = love.graphics.newImage(path)
    local batch = love.graphics.newSpriteBatch(img, nil, 'stream')
    local w, h = img:getPixelDimensions()

    img:setFilter('nearest', 'nearest')
    batches[#batches + 1] = batch
    lookup[name] = {
        batch = batch,
        sx = 0, sy = 0, sw = w, sh = h,
        tx = 0, ty = 0, w = w, h = h,
        quad = love.graphics.newQuad(0, 0, w, h, img:getPixelDimensions())
    }
end

local loadCrunch = function (path)
    local wd, name = splitPath(path)

    local f = io.open(love.filesystem.getSource() .. '/' .. path, 'rb')
    if f == nil then
        print('> < Cannot load sprite sheet metadata ' .. path)
        return nil
    end

    local read_int16 = function ()
        local l, h = f:read(2):byte(1, 2)
        local x = h * 256 + l
        if x >= 32768 then x = x - 65536 end
        return x
    end
    local read_str = function ()
        local s = {}
        repeat
            local ch = f:read(1)
            if ch:byte(1) == 0 then break end
            s[#s + 1] = ch
        until false
        return table.concat(s)
    end

    local texCount = read_int16()
    for texId = 1, texCount do
        local texName = read_str()
        local img = love.graphics.newImage(wd .. texName .. '.png')
        local batch = love.graphics.newSpriteBatch(img, nil, 'stream')
        img:setFilter('nearest', 'nearest')
        batches[#batches + 1] = batch

        local sprCount = read_int16()
        for sprId = 1, sprCount do
            local name = read_str()
            local spr = {}
            spr.batch = batch
            spr.sx = read_int16()
            spr.sy = read_int16()
            spr.sw = read_int16()
            spr.sh = read_int16()
            spr.tx = -read_int16()
            spr.ty = -read_int16()
            spr.w = read_int16()
            spr.h = read_int16()
            spr.quad = love.graphics.newQuad(
                spr.sx, spr.sy, spr.sw, spr.sh,
                img:getPixelDimensions())
            lookup[name] = spr
        end
    end

    f:close()
end

-- (x, y) is the top-left corner
local draw = function (name, x, y, bottomAligned)
    local item = lookup[name]
    if item == nil then print(name) return end
    local yAlignDelta = 0
    if bottomAligned then yAlignDelta = -item.h end
    local rx, ry = x + item.tx, y + item.ty + yAlignDelta
    if rx >= -item.w and rx <= W and ry >= -item.h and ry <= H then
        item.batch:add(item.quad, rx, ry)
    end
end

-- (x, y) is the centre
-- Will be centred w.r.t the size after trimming
local drawCen = function (name, x, y, sx, sy)
    local item = lookup[name]
    if item == nil then print(name) end
    sx = sx or 1
    sy = sy or sx
    local rx = x + (- item.sw * 0.5) * sx
    local ry = y + (- item.sh * 0.5) * sy
    if rx >= -item.w and rx <= W and ry >= -item.h and ry <= H then
        item.batch:add(item.quad, rx, ry, 0, sx, sy)
    end
end

local text = function (s, x, y, size)
    -- TODO
    love.graphics.print(s, x, y, 0, size)
end

local flush = function ()
    for _, v in ipairs(batches) do
        love.graphics.draw(v, 0, 0)
        -- TODO: Support static usage
        v:clear()
    end
end

local clear = function ()
    for _, v in ipairs(batches) do v:clear() end
end

return {
    loadImage = loadImage,
    loadCrunch = loadCrunch,
    draw = draw,
    drawCen = drawCen,
    text = text,
    flush = flush,
    clear = clear
}
