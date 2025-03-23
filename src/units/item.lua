item = {}
local window = require("src.window")
local map = require("src.mapRender")

levelItems = {}
grabbedItems = {}

itemsValuesId = {
    [1] = { 1, 1 },
    [2] = { 1, 2 },
    [3] = { 1, 3 },
    [4] = { 2, 1 },
    [5] = { 2, 2 },
}

-- Store the color values themselves, not the function calls
local colRarValues = {
    [1] = { 1, 1, 1, 0.8 },
    [2] = { 101 / 255, 217 / 255, 59 / 255, .85 }, -- Green #65d93b
    [3] = { 32 / 255, 107 / 255, 227 / 255, .8 }   -- Blue #206be3
}

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
local centerThreshold = 5 -- How close to center before changing dir
local centeringSpeed = 10 -- Speed at which items center themselves to tile centers


function tableToString(t)
    local str = "{"
    for i, v in ipairs(t) do
        if type(v) == "table" then
            -- If the value is a table, recursively call tableToString
            str = str .. tableToString(v)
        else
            -- Otherwise, just append the value
            str = str .. tostring(v)
        end
        if i < #t then
            str = str .. ", " -- Add a comma after each item except the last
        end
    end
    str = str .. "}"
    return str
end


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
    local length = math.sqrt(dx * dx + dy * dy)

    if length > 0 then
        return { x = dx / length, y = dy / length }
    else
        return { x = 0, y = 0 }
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

function item.draw(tileScale)
    for _, theItem in ipairs(levelItems) do
        local itemType = itemsValuesId[theItem.itemId]
        local col, row = itemType[1], itemType[2]
        local tileIndex = itemsTileset:getTileIndex(col, row)
        local outLineIndex = itemsTileset:getTileIndex(col + 2, row)

        -- Calculate center of the item in game coordinates
        local itemCenterX = theItem.x + theItem.size / 2
        local itemCenterY = theItem.y + theItem.size / 2

        -- Calculate tile size when drawn at the specified scale
        local tileDrawWidth = itemsTileset:getTileWidth() * tileScale
        local tileDrawHeight = itemsTileset:getTileHeight() * tileScale

        -- Calculate the top-left position where the tile should be drawn
        -- to be centered on the item center
        local tileDrawX = itemCenterX - tileDrawWidth / 2
        local tileDrawY = itemCenterY - tileDrawHeight / 2

        -- -- Draw colored outline based on item value
        love.graphics.setColor(1, 1, 1)
        itemsTileset:drawTile(
            outLineIndex,
            tileDrawX,            -- Adjusted X to center the tile
            tileDrawY,            -- Adjusted Y to center the tile
            tileScale * 1.40,     -- Scale relative to tile size, also make items a bit bigger
            theItem.rotation or 0 -- Rotation
        )

        -- Then overlay a colored mask using alpha blend mode
        love.graphics.setBlendMode("alpha", "alphamultiply")

        -- Apply the color based on the itemValue
        local colorToUse = colRarValues[theItem.itemValue] or colRarValues[1] -- Default to first color if not found
        love.graphics.setColor(unpack(colorToUse))                            -- unpack converts the table to individual arguments

        itemsTileset:drawTile(
            outLineIndex,
            tileDrawX,
            tileDrawY,
            tileScale * 1.40,
            theItem.rotation or 0
        )


        -- Reset blend mode to normal
        love.graphics.setBlendMode("alpha")

        love.graphics.setColor(1, 1, 1)
        itemsTileset:drawTile(
            tileIndex,
            tileDrawX,            -- Adjusted X to center the tile
            tileDrawY,            -- Adjusted Y to center the tile
            tileScale * 1.15,     -- Scale relative to tile size, also make items a bit bigger
            theItem.rotation or 0 -- Rotation
        )



        -- -- Debug: Draw center marker
        -- local centerX = tileDrawX
        -- local centerY = tileDrawY
        -- love.graphics.setColor(1, 0, 0)
        -- love.graphics.circle('fill', centerX, centerY, 3)
    end


    -- DEBUG START Set debug color (red with transparency)
    -- love.graphics.setColor(1, 0, 0, 0.5)

    -- local windowScale = math.min(window.getScaleX(), window.getScaleY())
    -- local xOffset = (window.getCurrentWidth() - window.getOriginalWidth() * windowScale) / 2

    -- -- Draw collision rectangles for all items
    -- for _, item in ipairs(levelItems) do
    --     -- Retrieve item original position
    --     local originalX = item.x
    --     local originalY = item.y
    --     local tileSize = 16 * windowScale

    --     -- Scale the positions
    --     local left = originalX * windowScale + xOffset-tileSize - ((tileSize * windowScale) *2.35) /4
    --     local top = originalY * windowScale-tileSize - ((tileSize * windowScale) *2.35) /4
    --     local width = (tileSize * windowScale) *2.35 -- 2.35 is the grabber threshold
    --     local height = (tileSize * windowScale)*2.35

    --     -- Draw the collision rectangle
    --     love.graphics.setColor(1, 0, 0, 1)                        -- Set color to red for visibility
    --     love.graphics.rectangle('line', left, top, width, height) -- Draw outline
    -- end


    -- Debug END x_x this one got me good

    -- Display item count for debugging
    love.graphics.setColor(1, 1, 1)
    -- love.graphics.print("Items: " .. #levelItems, 10, 250)
    -- love.graphics.print("grabbedItemsItems: " .. #grabbedItems, 10, 260)
    -- love.graphics.print("grabbedItems: " .. tableToString(grabbedItems), 10, 280)
end

return item
