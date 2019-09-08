return function () return {

component = 'vel',
update = function (self, es)
    for _, e in pairs(es) do
        -- TODO: Use smaller time steps
        e.dim[1] = e.dim[1] + e.vel[1] * DT
        e.dim[2] = e.dim[2] + e.vel[2] * DT
    end
end

} end
