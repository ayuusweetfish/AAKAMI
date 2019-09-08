return function (spritesheet) return {

component = 'sprite',
spritesheet = spritesheet,
update = function (self, es)
    for _, e in pairs(es) do
        self.spritesheet.draw(e.sprite.name, e.dim[1], e.dim[2])
    end
end

} end
