return function (spritesheet) return {

component = 'sprite',
spritesheet = spritesheet,
update = function (self, cs)
    for _, c in pairs(cs) do
        self.spritesheet.draw(c.name, c.entity.dim[1], c.entity.dim[2])
    end
end

} end
