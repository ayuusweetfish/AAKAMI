return function () return {

component = 'enemy',
update = function (self, es)
    for _, e in pairs(es) do e.vel[1], e.vel[2] = 16, 16 end
end

} end
