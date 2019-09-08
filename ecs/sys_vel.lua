return function () return {

component = 'vel',
update = function (self, es)
    for _, e in pairs(es) do
        -- TODO: Use smaller time steps
        e.dim[1] = e.dim[1] + e.vel[1] / 60.0
        e.dim[2] = e.dim[2] + e.vel[2] / 60.0
    end
end

} end
