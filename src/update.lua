local player = require("src.units.player")
local item = require("src.units.item")
local spawner = require("src.units.spawner")
local destroyer = require("src.units.destroyer")
local hud = require("src.sys.gameHud")
local menu = require('src.sys.menu')
local sound = require("src.sys.soundHandling")
local bulletSpawner = require("src.units.bulletHell.bulletSpawner")
local score = require("src.sys.score")
local levelData = require('src.levels.levelData')
local map = require('src.mapRender')

function update(dt)
    -- If in menu state, only update the menu
    if gameState == "menu" then
        menu.update(dt)
        return
    elseif gameState == "play" then
        if not isPaused then
            player.update(dt)
            score.update(dt)
            -- Update all animations
            tileset:update(dt)
            item.update(dt, tileScale)
    
            -- Update spawners
            spawner.update(dt, tileScale)
    
            -- Update spawners
            spawner.update(dt, tileScale)
    
            -- Update bullet spawners - pass player position for aiming
            bulletSpawner.update(dt, tileScale, player.x, player.y)
            
            
            -- Draw hud
            hud.update(dt)
            -- Update destroyers - check for item collisions
            destroyer.update(dt, tileScale)
    
            -- Resume music if it was paused
            sound.resume()
        else
            -- Pause music when game is paused
            sound.pause()
        end
    end
end

-- Add keyboard handling for menu
function keypressed(key)
    if gameState == "menu" then
        local result = menu.keypressed(key)
    end
end
