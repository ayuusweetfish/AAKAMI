require 'utils'

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

    local f, err = love.filesystem.read(path)
    if f == nil then
        print('> < Cannot load sprite sheet metadata ' .. path .. ' (' .. err .. ')')
        return nil
    end

    local p = 1

    local read_int16 = function ()
        local l, h = f:byte(p, p + 1)
        p = p + 2
        local x = h * 256 + l
        if x >= 32768 then x = x - 65536 end
        return x
    end
    local read_str = function ()
        local q = p
        repeat
            local ch = f:byte(p)
            p = p + 1
            if ch == 0 then break end
        until false
        return f:sub(q, p - 2)
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
end

local initializeTileset = function (name, sideLenX, sideLenY)
    local item = lookup[name]
    if item == nil then print(name) return end
    sideLenY = sideLenY or sideLenX
    local index = 0
    -- Dodgy...
    for y = 0, item.h - 1, sideLenY do
    for x = 0, item.w - 1, sideLenX do
        local tile = {
            batch = item.batch,
            sx = item.sx + x, sy = item.sy + y, sw = sideLenX, sh = sideLenY,
            tx = 0, ty = 0, w = sideLenX, h = sideLenY
        }
        tile.quad = love.graphics.newQuad(
            tile.sx, tile.sy, tile.sw, tile.sh,
            item.quad:getTextureDimensions()
        )
        index = index + 1
        lookup[name .. '#' .. tonumber(index)] = tile
    end
    end
end

local cropFromTileset = function (tileset, id, w, h, name)
    local item = lookup[tileset .. '#' .. tostring(id)]
    if item == nil then print(tileset, id) return end
    local tile = {
        batch = item.batch,
        sx = item.sx, sy = item.sy, sw = w, sh = h,
        tx = 0, ty = 0, w = w, h = h
    }
    tile.quad = love.graphics.newQuad(
        tile.sx, tile.sy, tile.sw, tile.sh,
        item.quad:getTextureDimensions()
    )
    lookup[tileset .. '#' .. name] = tile
end

-- (x, y) is the top-left corner
local draw = function (name, x, y, flipX, flipY)
    local item = lookup[name]
    if item == nil then print(name) return end
    local rx = x + (flipX and -item.tx or item.tx)
    local ry = y + (flipY and -item.ty or item.ty)
    if rx >= -item.w and rx <= W + item.w and ry >= -item.h and ry <= H + item.h then
        item.batch:add(item.quad, rx, ry, 0, flipX and -1 or 1, flipY and -1 or 1)
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

local text = function (s, x, y, w, size)
    x = x + 3
    y = y + 8
    size = size or 1
    local x0 = x
    local ch = { s:byte(1, #s) }

    -- Which character to break after
    local calcLF = function (s, w, p)
        if p + w - 1 >= #s then return #s end
        if s:byte(p + w) == 32 then return p + w end
        for q = p + w - 1, p + 1, -1 do
            if s:byte(q) == 32 then return q end
        end
        return p
    end

    local nextLF = 0x7fffffff
    if w then
        w = math.floor(w / (6 * size))
        nextLF = calcLF(s, w, 1)
    end

    for i, c in ipairs(ch) do
        if c == 10 or i > nextLF then
            x = x0
            y = y + 9 * size
            if w then nextLF = calcLF(s, w, i) end
        end
        if c >= 32 and c < 128 then
            drawCen('font#' .. tonumber(c - 31), x, y, size)
            x = x + 6 * size
        end
    end
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
    initializeTileset = initializeTileset,
    cropFromTileset = cropFromTileset,
    draw = draw,
    drawCen = drawCen,
    text = text,
    flush = flush,
    clear = clear
}
