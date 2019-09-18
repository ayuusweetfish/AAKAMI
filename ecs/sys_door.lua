local ecs = require 'ecs/ecs'
require 'ecs/utils'

return function () return {

update = function (self, cs)
    local p = cs.player[1]

    for _, e in pairs(cs.door) do
        if rectIntscAround(p.dim, e.dim, 8) then
            e.colli.tag = 0
            e.colli.block = false
            e.sprite.visible = false
        else
            e.colli.tag = 3
            e.colli.block = true
            e.sprite.visible = true
        end
    end
end

} end
