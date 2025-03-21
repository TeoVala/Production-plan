player = require("src.units.player")
item = require("src.units.item")
local spawner = require("src.units.spawner")
local destroyer = require("src.units.destroyer")

local tileScale = 1.5 -- You can adjust this to change the size of tiles

function update(dt)
    player.update(dt)

    -- Update all animations
    tileset:update(dt)
    item.update(dt, tileScale)
    
    -- Update spawners
    spawner.update(dt, tileScale)
    
    -- Update destroyers - check for item collisions
    destroyer.update(dt, tileScale)
end