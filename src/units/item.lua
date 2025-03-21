item = {}
local window = require("src.window")
local map = require("src.mapRender")

levelItems = {}

-- Conveyor movement definitions - first phase, second phase
local conveyorDirections = {
    ['conv-BR'] = { { x = 0, y = -1 }, { x = 1, y = 0 } },  -- Bottom to Right: first go up, then right
    ['conv-BL'] = { { x = 0, y = -1 }, { x = -1, y = 0 } }, -- Bottom to Left: first go up, then left
    ['conv-RU'] = { { x = -1, y = 0 }, { x = 0, y = -1 } }, -- Right to Up: first go left, then up
    ['conv-LU'] = { { x = 1, y = 0 }, { x = 0, y = -1 } },  -- Left to Up: first go right, then up
    ['conv-RL'] = { { x = -1, y = 0 } },                    -- Right to Left (straight)
    ['conv-LR'] = { { x = 1, y = 0 } },                     -- Left to Right (straight)
    ['conv-UB'] = { { x = 0, y = 1 } },                     -- Up to Bottom (straight)
    ['conv-BU'] = { { x = 0, y = -1 } },                    -- Bottom to Up (straight)
    ['conv-LB'] = { { x = 1, y = 0 }, { x = 0, y = 1 } },   -- Left to Down: first go right, then down
    ['conv-RB'] = { { x = -1, y = 0 }, { x = 0, y = 1 } },  -- Right to Down: first go left, then down
    ['conv-UL'] = { { x = 0, y = 1 }, { x = -1, y = 0 } },  -- Up to Left: first go down, then left
    ['conv-UR'] = { { x = 0, y = 1 }, { x = 1, y = 0 } },   -- Up to Right: first go down, then right
    ['empty'] = { { x = 0, y = 0 } }                        -- No movement
}

local conveyorSpeed = 35
local centerThreshold = 5  -- How close to center before changing dir
local centeringSpeed = 10 -- Speed at which items center themselves to tile centers

-- Helper function to get tile type and center at a specific position
function item.getTileInfoAtPosition(x, y, tileScale)
    -- Calculate map offsets (same as in mapRender.draw)
    local mapWidth = #map.mapTiles[1]
    local mapHeight = #map.mapTiles
    local mapX = (window.getOriginalWidth() - (mapWidth * tileSize * tileScale)) / 2
    local mapY = (window.getOriginalHeight() - (mapHeight * tileSize * tileScale)) / 2

    -- Convert pixel position to tile indices
    local tileJ = math.floor((x - mapX) / (tileSize * tileScale)) + 1
    local tileI = math.floor((y - mapY) / (tileSize * tileScale)) + 1

    -- Check if indices are valid
    if tileI >= 1 and tileI <= #map.mapTiles and
        tileJ >= 1 and tileJ <= #map.mapTiles[1] then
        local tileValue = map.mapTiles[tileI][tileJ]
        local tileType = tileValues[tileValue]

        -- Calculate center of the tile
        local centerX = mapX + (tileJ - 0.5) * tileSize * tileScale
        local centerY = mapY + (tileI - 0.5) * tileSize * tileScale

        return {
            type = tileType,
            center = { x = centerX, y = centerY },
            i = tileI,
            j = tileJ
        }
    end

    return { type = "empty", center = { x = 0, y = 0 } }
end

-- Calculate distanceBetween two points for the center of the tile
function item.distanceBetween(x1, y1, x2, y2)
    return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
end

-- Calculate a normalized direction vector from point 1 to point 2
function item.directionVector(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    local length = math.sqrt(dx*dx + dy*dy)
    
    if length > 0 then
        return {x = dx/length, y = dy/length}
    else
        return {x = 0, y = 0}
    end
end

function item.update(dt, tileScale)
    for _, theItem in ipairs(levelItems) do
        -- Get the center point of the item
        local itemCenterX = theItem.x + theItem.size / 2
        local itemCenterY = theItem.y + theItem.size / 2

        -- Get the tile info at the item's position
        local tileInfo = item.getTileInfoAtPosition(itemCenterX, itemCenterY, tileScale)

        -- Check if we moved to a new tile
        if not theItem.currentTile or
            (theItem.currentTile.i ~= tileInfo.i or theItem.currentTile.j ~= tileInfo.j) then
            theItem.currentTile = tileInfo
            theItem.tileCenter = tileInfo.center
            theItem.reachedCenter = false
        end

        -- Get directional info for this tile type
        local directions = conveyorDirections[tileInfo.type] or conveyorDirections["empty"]

        -- Check if at the center
        local distToCenter = item.distanceBetween(
            itemCenterX, itemCenterY,
            theItem.tileCenter.x, theItem.tileCenter.y
        )

        if tileInfo.type ~= "empty" and distToCenter <= centerThreshold * 2 then
            local movingHorizontally = true
            local movingVertically = true

            -- Check if we should snap to horizontal or vertical alignment
            if theItem.reachedCenter and #directions > 1 then
                -- We are in corner second phase
                movingHorizontally = directions[2].x ~= 0
                movingVertically = directions[2].y ~= 0
            elseif #directions > 1 then
                -- We are in corner first phase
                movingHorizontally = directions[1].x ~= 0
                movingVertically = directions[1].y ~= 0
            else
                -- Straight pieces
                movingHorizontally = directions[1].x ~= 0
                movingVertically = directions[1].y ~= 0
            end
            -- Apply horizontal or vertical alignment
            if movingHorizontally and not movingVertically then
                -- Moving horizontally, align vertically
                local targetY = theItem.tileCenter.y - theItem.size / 2
                local alignmentSpeed = 0.3 -- Adjust alignment speed (higher = faster)

                if math.abs(theItem.y - targetY) > 0.5 then
                    theItem.y = theItem.y + (targetY - theItem.y) * alignmentSpeed
                end
            elseif movingVertically and not movingHorizontally then
                -- Moving vertically, align horizontally
                local targetX = theItem.tileCenter.x - theItem.size / 2
                local alignmentSpeed = 0.3 -- Adjust alignment speed (higher = faster)

                if math.abs(theItem.x - targetX) > 0.5 then
                    theItem.x = theItem.x + (targetX - theItem.x) * alignmentSpeed
                end
            end
        elseif tileInfo.type == "empty" then
            local movingHorizontally = false
            local movingVertically = false
            theItem.currDirection = { x = 0, y = 0 }
        end

        -- Movement logic
        if distToCenter > centerThreshold and not theItem.reachedCenter then
            -- Item should move toward tile center first
            local dirToCenter = item.directionVector(
                itemCenterX, itemCenterY,
                theItem.tileCenter.x, theItem.tileCenter.y
            )

            -- Move toward center of tile, but keep full speed
            theItem.x = theItem.x + dirToCenter.x * centeringSpeed * dt
            theItem.y = theItem.y + dirToCenter.y * centeringSpeed * dt
        else
            -- Item is centered on the tile, now follow conveyor direction
            theItem.reachedCenter = true

            -- Corner handling
            if #directions > 1 then -- If greater than 1 then its a corner piece
                if theItem.reachedCenter then
                    -- Reached the center
                    theItem.currDirection = directions[2] -- Get the second direction
                else
                    -- Still heading to center, use the first direction
                    theItem.currDirection = directions[1] -- Get the second direction
                end
            else
                -- Straight piece, just use the one direction
                theItem.currDirection = directions[1]
            end
        end


        -- Update position based on current direction
        theItem.x = theItem.x + theItem.currDirection.x * conveyorSpeed * dt
        theItem.y = theItem.y + theItem.currDirection.y * conveyorSpeed * dt
    end
end

function item.draw()
    -- Get window scaling factors for proper positioning
    local windowScale = math.min(window.getScaleX(), window.getScaleY())
    local xOffset = (window.getCurrentWidth() - window.getOriginalWidth() * windowScale) / 2
    local yOffset = (window.getCurrentHeight() - window.getOriginalHeight() * windowScale) / 2

    for _, theItem in ipairs(levelItems) do
        -- Calculate item position with proper scaling
        local scaledX = theItem.x * windowScale + xOffset
        local scaledY = theItem.y * windowScale + yOffset
        local scaledWidth = theItem.size * windowScale
        local scaledHeight = theItem.size * windowScale

        -- Draw the item
        love.graphics.setColor(0, 1, 0)
        love.graphics.rectangle(
            'fill',
            scaledX,
            scaledY,
            scaledWidth,
            scaledHeight
        )
    end
end

return item
