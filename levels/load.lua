local ecs = require 'ecs/ecs'

return function (L, buffTermInteraction, vendTermInteraction)
    -- Tileset
    local tiles = L.tilesets[1].tiles

    -- Ground
    local levelW = L.width
    local levelH = L.height
    local floorData = L.layers[1].data
    for x = 1, levelW do
    for y = 1, levelH do
        ecs.addEntity({
            dim = { x * 16, y * 16 },
            sprite = {
                name = 'tileset3#' .. floorData[(y - 1) * levelW + x],
                z = -1
            }
        })
    end
    end

    -- Walls & fences
    local wallData = L.layers[2].data
    local fenceData = L.layers[3].data
    for x = 1, levelW do
    for y = 1, levelH do
        local t = wallData[(y - 1) * levelW + x]
        if t ~= 0 then
            local id = bit.band(t, 1023)
            local colli = tiles[id].properties.collidable
            ecs.addEntity({
                dim = { x * 16, y * 16, 16, 16 },
                sprite = {
                    name = 'tileset3#' .. id,
                    flipX = (bit.band(t, 0x80000000) ~= 0),
                    flipY = (bit.band(t, 0x40000000) ~= 0),
                    z = (colli and -1 or 1)
                },
                colli = (colli and { block = true, tag = 3 } or nil)
            })
        end
        t = fenceData[(y - 1) * levelW + x]
        if t ~= 0 then
            ecs.addEntity({
                dim = { x * 16, y * 16, 16, 16 },
                sprite = {
                    name = 'tileset3#' .. bit.band(t, 1023),
                    flipX = (bit.band(t, 0x80000000) ~= 0),
                    flipY = (bit.band(t, 0x40000000) ~= 0)
                },
                colli = { block = true, tag = 3, fence = true }
            })
        end
    end
    end

    -- Player
    local playerEntity = ecs.addEntity({
        dim = { 16 * 4, 16 * 4, 10, 12 },
        vel = { 0, 0 },
        sprite = { name = 'aka_waiting1' },
        player = {
            -- XXX: Get rid of this
            buff = {
                stockpile = { level = 1, equipped = false }
            },
            coin = 500,
            colour = 0,
            memory = 4,
            energy = 100, energyMax = 100
        },
        health = { val = 5, max = 5 },
        colli = { passive = true, tag = 2 }
    })

    -- Enemy
    ecs.addEntity({
        dim = { 16 * 9, 16 * 5.5, 48, 48 },
        vel = { 0, 0 },
        sprite = { name = '' },
        enemy = { name = 'boss', pattern = 'donut', boss = true },
        health = { val = 8, max = 8 },
        colli = { passive = true, tag = 4 }
    })

    ecs.addEntity({
        dim = { 16 * 11, 16 * 5.5, 16, 16 },
        vel = { 0, 0 },
        sprite = { name = '' },
        enemy = { name = 'yeshu', pattern = 'donut' },
        health = { val = 8, max = 8 },
        colli = { passive = true, tag = 4 }
    })

    -- Objects
    for _, o in pairs(L.layers[5].objects) do
        if o.name == 'Buff' or o.name == 'Shop' then
            -- A terminal
            local isBuff = (o.name == 'Buff')
            ecs.addEntity({
                dim = { o.x - 8, o.y, 18, 16 },
                sprite = {
                    name = (isBuff and 'tileset3#buffterm' or 'tileset3#vendterm'),
                    ox = 7, oy = 16, z = -1
                },
                colli = { block = true },
                term = {
                    once = isBuff,
                    callback = (isBuff and buffTermInteraction or vendTermInteraction),
                    bubble = ecs.addEntity({
                        dim = { o.x - 8, o.y, 16, 16 },
                        sprite = { name = 'quq9', z = 1 }
                    })
                }
            })
        end
    end

    return playerEntity
end
