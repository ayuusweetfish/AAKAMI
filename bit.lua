if _G['bit'] == nil then
  _G['bit'] = {
    band = function (a, b)
      local val = 1
      local ans = 0
      while b > 0 do
        if a % 2 == 1 and b % 2 == 1 then ans = ans + val end
        val = val + val
        a = math.floor(a / 2)
        b = math.floor(b / 2)
      end
      return ans
    end,
    bor = function (a, b)
      local val = 1
      local ans = 0
      while b > 0 do
        if a % 2 == 1 or b % 2 == 1 then ans = ans + val end
        val = val + val
        a = math.floor(a / 2)
        b = math.floor(b / 2)
      end
      return ans
    end,
    lshift = function (a, b) return a * (2 ^ b) end,
    arshift = function (a, b) return math.floor(a / (2 ^ b)) end,
  }
end
