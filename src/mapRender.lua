local window = require('src.window')
local levelData = require('src.levels.levelData')
tileSize = 16



local mapTiles = {
}

mapTiles = levelData.level1

map = {
    mapTiles = mapTiles, -- Expose the mapTiles table
}

tileValues = {
    [0] = 'empty',

    -- -- Animated tiles
    [1] = 'conv-BR',
    [2] = 'conv-BL',
    [3] = "conv-RU",
    [4] = "conv-LU",
    [5] = "conv-RL",
    [6] = "conv-LR",
    [7] = "conv-UB",
    [8] = "conv-BU",
    [9] = "conv-LB",
    [10] = "conv-RB",
    [11] = "conv-UL",
    [12] = "conv-UR",

    -- Single tiles
    [20] = { 6, 2 },                      -- wall-L
    [21] = { { 6, 2 }, { true, false } }, -- wall-R
    [22] = { 6, 3 },                      -- wall-U
    [23] = { { 6, 3 }, { false, true } }, -- wall-B
    [24] = { 6, 1 },                      -- wall-TL
    [25] = { { 6, 1 }, { true, false } }, -- wall-TR
    [26] = { 5, 3 },                      -- wall-BL
    [27] = { { 5, 3 }, { true, false } }, -- wall-BR flipH

    -- Units, interactables
    [40] = { 7, 1 }, -- spawner
    [41] = { 7, 2 }, -- destroyer
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

            -- Calculate tile position in game coordinates
            local tileX = mapX + ((j - 1) * tileSize * tileScale)
            local tileY = mapY + ((i - 1) * tileSize * tileScale)

            if value < 20 and value ~= 0 then
                tileset:drawAnimation(
                    tileType,
                    tileX,
                    tileY,
                    tileScale
                )
            elseif value < 40 and value ~= 0 then
                if type(tileType) == "table" and type(tileType[1]) == "table" then
                    local tileCoords = tileType[1]
                    local col, row = tileCoords[1], tileCoords[2]
                    local flip = tileType[2]

                    local tileIndex = tileset:getTileIndex(col, row)

                    tileset:drawTile(
                        tileIndex,
                        tileX, tileY,
                        tileScale,
                        0,
                        unpack(flip) -- Unpack the flip table to pass as separate arguments
                    )
                else
                    local col, row = tileType[1], tileType[2]
                    local tileIndex = tileset:getTileIndex(col, row)

                    tileset:drawTile(
                        tileIndex,
                        tileX, tileY,
                        tileScale,
                        0
                    )
                end
            elseif value >= 40 and value ~= 0 then
                local col, row = tileType[1], tileType[2]
                local tileIndex = tileset:getTileIndex(col, row)

                tileset:drawTile(
                    tileIndex,
                    tileX, tileY,
                    tileScale,
                    0
                )
            end
        end
    end
end

return map
