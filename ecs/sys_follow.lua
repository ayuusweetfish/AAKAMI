return function () return {

update = function (self, cs)
    for _, e in pairs(cs.follow or {}) do
        local ef = e.follow.target
        local ev = e.follow.vel
        local ea = e.follow.accel * DT
        local vx, vy = targetVec(e.dim, ef.dim, ev)
        local dx, dy = vx - e.vel[1], vy - e.vel[2]
        local dsq = dx * dx + dy * dy
        if dsq <= ea * ea then
            e.vel[1], e.vel[2] = vx, vy
        else
            local d = math.sqrt(dsq)
            e.vel[1], e.vel[2] = e.vel[1] + dx / d, e.vel[2] + dy / d
        end
    end
end

} end
