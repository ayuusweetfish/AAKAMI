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

    batches[#batches + 1] = batch
    lookup[name] = {
        batch = batch,
        sx = 0, sy = 0, sw = w, sh = h,
        tx = 0, ty = 0, w = w, h = h
    }
end

local loadCrunch = function (path)
    local wd, name = splitPath(path)

    local f = io.open(path, 'rb')
    if f == nil then return nil end

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
            lookup[name] = spr
        end
    end

    f:close()
end

-- (x, y) is the top-left corner
local draw = function (name, x, y, bottomAligned)
    local item = lookup[name]
    local yAlignDelta = 0
    if bottomAligned then yAlignDelta = -item.h end
    if item ~= nil then
        item.batch:add(love.graphics.newQuad(
            item.sx, item.sy,
            item.sw, item.sh,
            item.batch:getTexture():getPixelDimensions()
        ), x + item.tx, y + item.ty + yAlignDelta)
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
    draw = draw,
    flush = flush,
    clear = clear
}
