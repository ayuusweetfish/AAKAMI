splitPath = function (path)
    local p = #path
    local q     -- p: last '/'; q: last '.' after p
    -- ord('/') == 47, ord('.') == 46
    while p >= 1 and path:byte(p) ~= 47 do
        if path:byte(p) == 46 and q == nil then q = p end
        p = p - 1
    end
    q = q or #path + 1
    return path:sub(1, p), path:sub(p + 1, q - 1)
end
--[[
print(splitPath('a/a/bb.cc'))
print(splitPath('aa/bb.cc'))
print(splitPath('aa/bb.cc'))
print(splitPath('aa/bb.'))
print(splitPath('aa/.cc'))
print(splitPath('a.a/bb'))
print(splitPath('aa/bb'))
print(splitPath('bb.cc'))
print(splitPath('bb'))
]]
