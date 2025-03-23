player = require("src.units.player")
item = require("src.units.item")
local spawner = require("src.units.spawner")
local destroyer = require("src.units.destroyer")
local hud = require("src.sys.gameHud")


function update(dt)
    
    player.update(dt)

    -- Update all animations
    tileset:update(dt)
    item.update(dt, tileScale)
    
    -- Update spawners
    spawner.update(dt, tileScale)
    hud.update(dt)
    -- Update destroyers - check for item collisions
    destroyer.update(dt, tileScale)
end