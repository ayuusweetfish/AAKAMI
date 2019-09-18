local ecs = require 'ecs/ecs'
require 'ecs/utils'

local spawnEnemy = function (p, a)
    local x0, y0 = p[1], p[2]
    local x1, y1, w1, h1 = a[1], a[2], a[3] - 16, a[4] - 16
    local x, y
    local t, r, x2, y2
    for _ = 1, 100 do
        t = math.random() * math.pi * 2
        r = math.random() * 32 + 32
        x2 = x0 + r * math.cos(t)
        y2 = y0 + r * math.sin(t)
        if x2 >= x1 and x2 < x1 + w1 and y2 >= y1 and y2 < y1 + h1 then
            x, y = x2, y2
            break
        end
    end
    if x == nil then print('> <') return end

    local names = { 'cola', 'pepsi', 'yeshu' }
    local colours = { 0, 1, nil }
    local patterns = { 'triplet', 'triad', 'penta' }
    local i = math.random(3)

    ecs.addEntity({
        dim = { x, y, 16, 16 },
        vel = { 0, 0 },
        sprite = { name = '' },
        enemy = {
            name = names[i],
            colour = colours[i],
            pattern = patterns[math.random(3)]
        },
        health = { val = 4, max = 4 },
        colli = { passive = true, tag = 4 }
    })
end

return function () return {

update = function (self, cs)
    local p = cs.player[1]

    for _, e in pairs(cs.enemyarea) do
        if rectIntsc(p.dim, e.dim) then
            local sinceLastSpawn = (e.enemyarea.sinceLastSpawn or 0) + 1
            if sinceLastSpawn >= 270 then
                sinceLastSpawn = 0
                spawnEnemy(p.dim, e.dim)
            end
            e.enemyarea.sinceLastSpawn = sinceLastSpawn
        end
    end
end

} end
