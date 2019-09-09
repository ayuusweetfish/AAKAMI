return function (spritesheet) return {

component = 'sprite',
spritesheet = spritesheet,
update = function (self, es)
    table.sort(es, function (lhs, rhs)
        if math.abs(lhs.dim[2] - rhs.dim[2]) <= 1e-6 then
            return lhs.dim[1] < rhs.dim[1]
        end
        return lhs.dim[2] < rhs.dim[2]
    end)

    for _, e in pairs(es) do
        self.spritesheet.draw(
            e.sprite.name,
            math.floor(e.dim[1] + 0.5),
            math.floor(e.dim[2] + 0.5 + e.dim[4])
        )
    end
end

} end
