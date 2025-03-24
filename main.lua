-- Main love Callbacks
require("src.load")
require("src.update")
require("src.draw")

local window = require("src.window")
local menu = require("src.sys.menu")
local map = require("src.mapRender")

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
    -- Pass the key press to the keypressed function defined in update.lua
    keypressed(key)
end

function love.resize(w, h)
    window.resize(w, h)
end
