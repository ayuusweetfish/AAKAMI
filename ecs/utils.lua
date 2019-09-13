segIntscLen = function (l1, r1, l2, r2)
    return math.max(0, math.min(r1, r2) - math.max(l1, l2))
end

rectIntsc = function (a, b)
    return (segIntscLen(a[1], a[1] + a[3], b[1], b[1] + b[3]) > 0
        and segIntscLen(a[2], a[2] + a[4], b[2], b[2] + b[4]) > 0)
end

rectIntscAround = function (a, b, w)
    return (segIntscLen(a[1], a[1] + a[3], b[1] - w, b[1] + b[3] + w + w) > 0
        and segIntscLen(a[2], a[2] + a[4], b[2] - w, b[2] + b[4] + w + w) > 0)
end

targetVec = function (s, t, l)
    local tx, ty = t[1] + t[3] * 0.5, t[2] + t[4] * 0.5
    local dx, dy = tx - (s[1] + s[3] * 0.5), ty - (s[2] + s[4] * 0.5)
    if dx * dx + dy * dy < 1e-5 then return 0, 0 end
    local factor = l / math.sqrt(dx * dx + dy * dy)
    return dx * factor, dy * factor
end

targetVecAround = function (s, t, r, l)
    local tx, ty = t[1] + t[3] * 0.5, t[2] + t[4] * 0.5
    local dx, dy = tx - (s[1] + s[3] * 0.5), ty - (s[2] + s[4] * 0.5)
    local dsq = dx * dx + dy * dy
    if dsq < 1e-5 then return 0, 0 end
    local factor = l * (math.sqrt(dsq) - r) / dsq
    return dx * factor, dy * factor
end
