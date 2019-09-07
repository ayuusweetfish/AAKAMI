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

-- (x, y) is the top-left corner
local draw = function (name, x, y)
    local item = lookup[name]
    if item ~= nil then
        -- Incomplete!
        item.batch:add(x, y)
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
    draw = draw,
    flush = flush,
    clear = clear
}
