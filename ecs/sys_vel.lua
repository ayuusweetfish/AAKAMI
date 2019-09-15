return function () return {

update = function (self, cs)
    for _, e in pairs(cs.vel) do
        e.dim[1] = e.dim[1] + e.vel[1] * DT
        e.dim[2] = e.dim[2] + e.vel[2] * DT
    end
end

} end
