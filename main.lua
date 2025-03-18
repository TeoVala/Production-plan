-- Main love Callbacks
require("src.load")
require("src.update")
require("src.draw")

local window = require("src.window")

function love.load()
    load()
end

function love.update(dt)
    update(dt)
end

function love.draw()
    draw()
end

function love.keypressed(key)
end

function love.resize(w, h)
    window.resize(w, h)
end
