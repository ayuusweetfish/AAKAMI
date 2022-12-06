require 'utils'

-- Map from names to audio sources
local lookup = {}

local loadAudio = function (path, loop, alias)
    if not alias then
        _, alias = splitPath(path)
    end
    local src = love.audio.newSource(path, 'static')
    lookup[alias] = src

    if loop then src:setLooping(true) end
end

local play = function (name)
    local src = lookup[name]
    src:stop()
    src:seek(0)
    src:play()
end

local get = function (name) return lookup[name] end

return {
    loadAudio = loadAudio,
    play = play,
    get = get
}
