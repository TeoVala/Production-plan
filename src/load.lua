local window = require("src.window")
local Tileset = require("src.tileset")
local player = require("src.units.player")
local plan = require("src.sys.machPlan")
local sound = require("src.sys.soundHandling")
local bulletSpawner = require("src.units.bulletHell.bulletSpawner") 
local menu = require("src.sys.menu")

function load()
    window.initialize()
    -- This works in all LÖVE versions
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Initialize game state
    gameState = "menu"  -- Start with the menu
    currentLevel = 1    -- Default level
    isPaused = false
    
    -- Load the menu
    menu.load()

    -- Load the tilesets (needed for menu backgrounds and game)
    tileset = Tileset.new("assets/Tileset-16x16.jpg")
    itemsTileset = Tileset.new("assets/items-16x16.jpg")

    sound.load()
    sound.play()

    -- Create animations
    -- Todo fix a pixel it caused when I made the tilesets smaller I have backup of the old one
    -- Convayor belts
    tileset:createAnimation("conv-BR", tileset:getTileIndex(1, 1), 3, .25)
    tileset:createAnimation("conv-BL", tileset:getTileIndex(1, 1), 3, .25, { flipH = true })
    tileset:createAnimation("conv-RU", tileset:getTileIndex(2, 1), 3, .25, { flipH = true })
    tileset:createAnimation("conv-LU", tileset:getTileIndex(2, 1), 3, .25)
    tileset:createAnimation("conv-LB", tileset:getTileIndex(2, 1), 3, .25, { flipV = true })
    tileset:createAnimation("conv-RB", tileset:getTileIndex(2, 1), 3, .25, { flipV = true, flipH = true })
    tileset:createAnimation("conv-UL", tileset:getTileIndex(1, 1), 3, .25, { flipH = true, flipV = true })
    tileset:createAnimation("conv-UR", tileset:getTileIndex(1, 1), 3, .25, { flipV = true })
    tileset:createAnimation("conv-RL", tileset:getTileIndex(4, 1), 3, .25, { flipH = true })
    tileset:createAnimation("conv-LR", tileset:getTileIndex(4, 1), 3, .25)
    tileset:createAnimation("conv-UB", tileset:getTileIndex(3, 1), 3, .25, { flipV = true })
    tileset:createAnimation("conv-BU", tileset:getTileIndex(3, 1), 3, .25)

    player.load()

    -- Set up bullet spawners
    bulletSpawner.setupSpawners()

    plan.init()
    
    -- Initialize score
    scoreNum = 0
end
