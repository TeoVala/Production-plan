local window = require('src.window')
local player = require("src.units.player")
local map = require("src.mapRender")

local tileScale = 1.5 -- You can adjust this to change the size of tiles

function draw()
    -- Clear with background color
    love.graphics.clear(0.1, 0.1, 0.3)

   map.draw(tileScale) 

    -- Draw an animation with built-in scaling
    -- tileset:drawAnimation("conv-BU", window.getOriginalWidth() / 2, window.getOriginalHeight() / 2, tileScale)
    -- tileset:drawAnimation("conv-BL", window.getOriginalWidth() / 2, (window.getOriginalHeight() / 2) + 20, tileScale)
    -- tileset:drawAnimation("conv-RU", window.getOriginalWidth() / 2, (window.getOriginalHeight() / 2) + 40, tileScale)
    -- tileset:drawAnimation("conv-LU", window.getOriginalWidth() / 2, (window.getOriginalHeight() / 2) + 60, tileScale)

    -- Draw player
    player.draw(tileScale)

    -- Draw debug info
    window.drawDebugInfo()
end
