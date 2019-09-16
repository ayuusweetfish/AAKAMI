local create = function (transitions)
    local obj = {
        transitions = transitions,
        age = 0,
        curState = 1,
        curTrans = nil,     -- key
        _curTrans = nil,    -- value
        curTransStep = -1
    }

    obj.step = function (self)
        self.age = self.age + 1
        -- Transition?
        local t = self._curTrans
        if t ~= nil then
            self.curTransStep = self.curTransStep + 1
            if self.curTransStep >= t[2] then
                self.curTrans = nil
                self._curTrans = nil
                self.curTransStep = -1
            end
        end
    end

    obj.trans = function (self, index, override)
        if not override and self.curTrans ~= nil then return end
        local t = self.transitions[index]
        if t == nil then print(index) return end
        -- Immediately switch to the new state
        self.curState = t[1]
        self.curTrans = index
        self._curTrans = t
        self.curTransStep = 0
    end

    return obj
end

return {
    create = create
}
