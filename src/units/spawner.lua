local spawner = {}
local window = require("src.window")
local map = require("src.mapRender")

-- Why is randomness like that lol
-- Add this to the top of your file or in your love.load() function
math.randomseed(os.time())
--  Burn a few random numbers as the first few can be less random
for i = 1, 10 do
    math.random()
end

spawner.timers = {} -- Keeps track of timer for each spawner, used it in update
spawner.initialized = false
local spawnIntervals = { 3.75, 3.80, 3.85, 3.90, 4.0, 4.25, 4.35, 4.5, 4.5, 4.5, 4.75, 4.85, 5.0, 5.5, 6.0 }

-- Store spawner locations
spawner.locations = {}

function spawner.findAdjacentConveyor(mapTiles, i, j)
    -- This find conveyor belts around the spawner, and spawns an item on them when the timer ends

    -- Conveyor belt locations
    local directions = {
        { i - 1, j,     "up" },   -- Up
        { i + 1, j,     "down" }, -- Down
        { i,     j - 1, "left" }, -- Left
        { i,     j + 1, "right" } -- Right
    }


    for _, dir in ipairs(directions) do
        local checkI, checkJ, dirName = unpack(dir)

        -- Check if valid position
        if checkI >= 1 and checkI <= #mapTiles and
            checkJ >= 1 and checkJ <= #mapTiles[1] then
            local tileValue = mapTiles[checkI][checkJ]
            local tileType = tileValues[tileValue]

            -- All conveyor belt strings start with "conv-"
            if type(tileType) == "string" and tileType:sub(1, 5) == "conv-" then
                return {
                    direction = dirName,
                    i = checkI,
                    j = checkJ,
                    type = tileType
                }
            end
        end
    end

    return nil
end

-- Spawn an item from a spawner toward conveyor direction
function spawner.spawnItem(spawnerInfo, tileScale)
    local conveyorTile = spawnerInfo.conveyor

    -- Calculate items spawn position
    local mapWidth = #map.mapTiles[1]
    local mapHeight = #map.mapTiles
    local mapX = (window.getOriginalWidth() - (mapWidth * tileSize * tileScale)) / 2
    local mapY = (window.getOriginalHeight() - (mapHeight * tileSize * tileScale)) / 2

    local itemX = mapX + ((conveyorTile.j - 1) * tileSize * tileScale)
    local itemY = mapY + ((conveyorTile.i - 1) * tileSize * tileScale)

    -- Add a small offset to position within the tile
    local offsetX = (tileSize * tileScale) / 4
    local offsetY = (tileSize * tileScale) / 4

    -- Rarity of items
    local function selectRarity()
        local roll = math.random(1, 100)

        if roll <= 75 then
            return 1 -- Common (75% chance) - White
        elseif roll <= 95 then
            return 2 -- Medium Rare (20% chance) - Green
        else
            return 3 -- Ultra Rare (5% chance) - Blue
        end
    end


    -- Create the item
    local newItem = {
        x = itemX + offsetX,
        y = itemY + offsetY,
        velocity = { x = 0, y = 0 },
        size = tileSize * 0.75, -- Make item slightly smaller than a tile
        currentTile = conveyorTile.type,
        tileCenter = {
            x = itemX + (tileSize * tileScale) / 2,
            y = itemY + (tileSize * tileScale) / 2
        },
        reachedCenter = false,
        currDirection = { x = 0, y = 0 },
        itemId = math.random(1, 5), -- Random item type
        itemValue = selectRarity(), -- Rarity values
        rotation = math.random(-30, 30) * (math.pi / 180) --Rotate item randomly, Convert degrees to radians
    }

    -- Add to the global levelItems table
    table.insert(levelItems, newItem)
end

-- Lets gooo lets start this bad boy up
function spawner.initialize(tileScale)
    local mapTiles = map.mapTiles
    local mapWidth = #mapTiles[1]
    local mapHeight = #mapTiles

    local mapX = (window.getOriginalWidth() - (mapWidth * tileSize * tileScale)) / 2
    local mapY = (window.getOriginalHeight() - (mapHeight * tileSize * tileScale)) / 2

    -- Get all the spawners from the map
    for i, row in ipairs(mapTiles) do
        for j, value in ipairs(row) do
            if value == 40 then -- 40 is the value of the spawner
                local tileX = mapX + ((j - 1) * tileSize * tileScale)
                local tileY = mapY + ((i - 1) * tileSize * tileScale)

                -- Check for conveyor belt tiles
                local adjacentConveyor = spawner.findAdjacentConveyor(mapTiles, i, j)

                if adjacentConveyor then
                    local theInterval = spawnIntervals
                        [math.random(#spawnIntervals)] -- Initialize timer, random intervals from the list

                    table.insert(spawner.locations, {
                        x = tileX,
                        y = tileY,
                        gridI = i,
                        gridJ = j,
                        conveyor = adjacentConveyor,
                        -- timer = spawner.spawnInterval -- Initialize timer, non random
                        timer = theInterval,    -- Initialize timer, random intervals from the list
                        currTimer = theInterval -- The currTimer that changes
                    })
                end
            end
        end
    end

    spawner.initialized = true
end

function spawner.update(dt, tileScale)
    -- Timers update and spawn items

    if not spawner.initialized then
        spawner.initialize(tileScale)
    end

    -- Update spawner timers
    for _, spawn in ipairs(spawner.locations) do
        spawn.timer = spawn.timer - dt -- Properly decrements timer

        if spawn.timer <= 0 then
            spawner.spawnItem(spawn, tileScale)
            spawn.timer = spawn.currTimer -- Reset timer
        end
    end
end

-- Draw spawner debug visuals (optional)
function spawner.draw(tileScale)
    local windowScale = math.min(window.getScaleX(), window.getScaleY())
    local xOffset = (window.getCurrentWidth() - window.getOriginalWidth() * windowScale) / 2
    local yOffset = (window.getCurrentHeight() - window.getOriginalHeight() * windowScale) / 2

    -- Draw spawners
    love.graphics.setColor(0, 0.7, 0.3)
    for _, spawn in ipairs(spawner.locations) do
        -- love.graphics.rectangle(
        --     'line',
        --     spawn.x * windowScale + xOffset,
        --     spawn.y * windowScale + yOffset,
        --     tileSize * tileScale * windowScale,
        --     tileSize * tileScale * windowScale
        -- )

        -- Draw timer
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(
            string.format("%.1f", spawn.timer),
            spawn.x * windowScale + xOffset,
            spawn.y * windowScale + yOffset
        )
    end
end

return spawner
