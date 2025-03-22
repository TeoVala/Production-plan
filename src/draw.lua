local window = require('src.window')
local player = require("src.units.player")
local map = require("src.mapRender")
local item = require("src.units.item")
local spawner = require("src.units.spawner")
local destroyer = require("src.units.destroyer")



function draw()
    -- Clear with background color
    love.graphics.clear(0.1, 0.1, 0.3)

    map.draw(tileScale)

    player.drawShadow(tileScale)
    item.draw(tileScale)

    -- Draw spawner and destroyer debug visuals (optional)
    spawner.draw(tileScale)
    destroyer.draw(tileScale)

    -- Draw player
    player.draw(tileScale)

    -- Draw debug info
    window.drawDebugInfo()
end
