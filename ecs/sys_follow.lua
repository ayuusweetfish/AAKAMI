return function () return {

update = function (self, cs)
    for _, e in pairs(cs.follow or {}) do
        local ef = e.follow.target
        local ev = e.follow.vel
        e.vel[1], e.vel[2] = targetVec(e.dim, ef.dim, ev)
    end
end

} end
