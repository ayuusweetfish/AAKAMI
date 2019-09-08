return function (spritesheet) return {

component = 'sprite',
spritesheet = spritesheet,
update = function (self, es)
    for _, e in pairs(es) do
        self.spritesheet.draw(
            e.sprite.name,
            math.floor(e.dim[1] + 0.5),
            math.floor(e.dim[2] + 0.5)
        )
    end
end

} end
