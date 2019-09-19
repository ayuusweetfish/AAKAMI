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
        dim = { 0, 0, 10, 12 },
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

    -- Map bounds
    ecs.addEntity({
        dim = { 16, 0, L.width * 16, 16 },
        colli = { block = true, tag = 0xffffffff }
    })
    ecs.addEntity({
        dim = { 16, 16 + L.height * 16, L.width * 16, 16 },
        colli = { block = true, tag = 0xffffffff }
    })
    ecs.addEntity({
        dim = { 0, 16, 16, L.height * 16 },
        colli = { block = true, tag = 0xffffffff }
    })
    ecs.addEntity({
        dim = { 16 + L.width * 16, 16, 16, L.height * 16 },
        colli = { block = true, tag = 0xffffffff }
    })

    -- Objects
    for _, o in pairs(L.layers[5].objects) do
        if o.name == 'Spawn' then
            playerEntity.dim[1] = 912--o.x
            playerEntity.dim[2] = 976--o.y
        elseif o.name == 'Buff' or o.name == 'Shop' then
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
                        dim = { o.x - 5, o.y - 24, 16, 16 },
                        sprite = { name = 'gamepad1', z = 2 }
                    })
                }
            })
        elseif o.name:sub(1, 4) == 'Door' then
            local isV = (o.name:byte(5) == 86)  -- 86 == ord('V')
            local id = tonumber(o.name:sub(6)) or 0
            ecs.addEntity({
                dim = isV and { o.x + 16, o.y + 32, 16, 32 }
                    or { o.x, o.y, 32, 16 },
                sprite = isV and { name = 'tileset3#doorv', oy = 16, z = 0 }
                    or { name = 'tileset3#doorh', oy = 16, z = 0 },
                colli = { block = true, tag = 3 },
                door = {
                    id = id,
                    bubble = (id == 0 and nil or ecs.addEntity({
                        dim = isV and { o.x + 12, o.y - 8, 16, 16 }
                            or { o.x + 4, o.y - 36, 16, 16 },
                        sprite = { name = 'requirekey', z = 2 }
                    }))
                }
            })
        elseif o.name:sub(1, 3) == 'Key' then
            local id = tonumber(o.name:sub(4))
            ecs.addEntity({
                dim = { o.x + 16, o.y + 16, 16, 16 },
                sprite = { name = 'tileset3#169' },
                key = { id = id }
            })
        elseif o.name == 'Area' then
            ecs.addEntity({
                dim = { o.x + 16, o.y + 16, o.width, o.height },
                enemyarea = {}
            })
        elseif o.name == 'EliteArea' then
            ecs.addEntity({
                dim = { o.x + 16, o.y + 16, o.width, o.height },
                elitearea = {}
            })
        elseif o.name == 'Elevator' then
            ecs.addEntity({
                dim = { o.x + 8, o.y, 16, 16 },
                sprite = { name = 'tileset3#elevator0', ox = 8, oy = 16 },
                colli = { block = true, tag = 3 },
                door = { fin = true }
            })
        end
    end

    return playerEntity
end
