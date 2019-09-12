segIntscLen = function (l1, r1, l2, r2)
    return math.max(0, math.min(r1, r2) - math.max(l1, l2))
end

rectIntsc = function (a, b)
    return (segIntscLen(a[1], a[1] + a[3], b[1], b[1] + b[3]) > 0
        and segIntscLen(a[2], a[2] + a[4], b[2], b[2] + b[4]) > 0)
end
