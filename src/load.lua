local window = require("src.window")
local Tileset = require("src.tileset")
local player = require("src.units.player")
local map = require("src.mapRender")

function load()
    window.initialize()
    -- This works in all LÖVE versions
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Load the tilesets
    tileset = Tileset.new("assets/Tileset-16x16.jpg")

    -- Create animations
    tileset:createAnimation("conv-BR", tileset:getTileIndex(1,1), 3, .25)
    tileset:createAnimation("conv-BL", tileset:getTileIndex(2,1), 3, .25)
    tileset:createAnimation("conv-RU", tileset:getTileIndex(3,1), 3, .25)
    tileset:createAnimation("conv-LU", tileset:getTileIndex(4,1), 3, .25)
    tileset:createAnimation("conv-RL", tileset:getTileIndex(5,1), 3, .25)
    tileset:createAnimation("conv-LR", tileset:getTileIndex(6,1), 3, .25)
    tileset:createAnimation("conv-UB", tileset:getTileIndex(8,1), 3, .25)
    tileset:createAnimation("conv-BU", tileset:getTileIndex(9,1), 3, .25)

    player.load()
end