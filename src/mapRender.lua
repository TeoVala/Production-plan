local window = require('src.window')

map = {}
local tileSize = 16

local mapTiles = {
    { 1, 6, 6, 6, 6, 2 }, -- row 1
    { 9, 0, 0, 0, 0, 8 }, -- row 2
    { 9, 0, 0, 0, 0, 8 }, -- row 3
    { 9, 0, 0, 0, 0, 8 }, -- row 3
    { 9, 0, 0, 0, 0, 8 }, -- row 3
    { 9, 0, 0, 0, 0, 8 }, -- row 3
    { 3, 5, 5, 5, 5, 4 }, -- row 4
}

tileValues = {
    [0] = 'empty',
    [1] = 'conv-BR',
    [2] = 'conv-BL',
    [3] = "conv-RU",
    [4] = "conv-LU",
    [5] = "conv-RL",
    [6] = "conv-LR",
    [8] = "conv-UB",
    [9] = "conv-BU",
}


function map.draw(tileScale)
    -- Calculate map dimensions
    local mapWidth = #mapTiles[1]
    local mapHeight = #mapTiles

    -- Center the map in the original window size
    local mapX = (window.getOriginalWidth() - (mapWidth * tileSize * tileScale)) / 2
    local mapY = (window.getOriginalHeight() - (mapHeight * tileSize * tileScale)) / 2
    -- Get window scale and offsets exactly as in player.lua
    local windowScale = math.min(window.getScaleX(), window.getScaleY())

    -- Draw each tile
    for i, row in ipairs(mapTiles) do
        for j, value in ipairs(row) do
            local tileType = tileValues[value]
            if tileType ~= 'empty' then
                -- Calculate tile position in game coordinates
                local tileX = mapX + ((j - 1) * tileSize * tileScale )
                local tileY = mapY + ((i - 1) * tileSize * tileScale )

                tileset:drawAnimation(
                    tileType,
                    tileX,
                    tileY,
                    tileScale
                )
            end
        end
    end
end

return map
