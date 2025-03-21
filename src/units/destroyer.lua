local destroyer = {}
local window = require("src.window")
local map = require("src.mapRender")

-- Store destroyer positions
destroyer.locations = {}
destroyer.initialized = false


-- Simple AABB collision check
function destroyer.checkCollision(rect1, rect2)
    return not (
        rect1.right < rect2.left or
        rect1.left > rect2.right or
        rect1.bottom < rect2.top or
        rect1.top > rect2.bottom
    )
end

-- Initialize the destroyers -- locate destroyers on the map
function destroyer.initialize(tileScale)
    if destroyer.initialized then return end -- if already done don't do it again

    local mapTiles = map.mapTiles
    local mapWidth = #mapTiles[1]
    local mapHeight = #mapTiles

    -- Get sizes of the map according to the window size
    local mapX = (window.getOriginalWidth() - (mapWidth * tileSize * tileScale)) / 2
    local mapY = (window.getOriginalHeight() - (mapHeight * tileSize * tileScale)) / 2

    -- Find the destroyers
    for i, row in ipairs(mapTiles) do
        for j, value in ipairs(row) do
            if value == 41 then -- Tile value 41 is destroyer
                local tileX = mapX + ((j - 1) * tileSize * tileScale)
                local tileY = mapY + ((i - 1) * tileSize * tileScale)

                table.insert(destroyer.locations, {
                    x = tileX,
                    y = tileY,
                    width = tileSize * tileScale,
                    height = tileSize * tileScale,
                    gridI = i,
                    gridJ = j
                })
            end
        end
    end

    destroyer.initialized = true
end

-- Check if items intersect with destroyers and remove them if they do
function destroyer.update(dt, tileScale)
    if not destroyer.initialized then
        destroyer.initialize(tileScale)
    end

    -- Collision with destroyers and removing items
    local itemsToRemove = {}

    for _, destr in ipairs(destroyer.locations) do
        -- Destroyer rectangles AABB collisions
        local destroyerRect = {
            left = destr.x,
            top = destr.y,
            right = destr.x + destr.width,
            bottom = destr.y + destr.height
        }

        -- Item rects 
        for i, item in ipairs(levelItems) do
            local itemRect = {
                left = item.x,
                top = item.y,
                right = item.x + item.size,
                bottom = item.y + item.size,
            }

            -- The AABB collision check
            if destroyer.checkCollision(destroyerRect, itemRect) then
                table.insert(itemsToRemove, i)
            end
        end
    end

    -- Remove items that collided with destroyers
    table.sort(itemsToRemove, function(a, b) return a > b end)
    for _, index in ipairs(itemsToRemove) do
        table.remove(levelItems, index)
    end

end

-- Draw destroyer debug visuals (optional)
function destroyer.draw(tileScale)
    -- debug
    -- local windowScale = math.min(window.getScaleX(), window.getScaleY())
    -- local xOffset = (window.getCurrentWidth() - window.getOriginalWidth() * windowScale) / 2
    -- local yOffset = (window.getCurrentHeight() - window.getOriginalHeight() * windowScale) / 2
    
    -- -- Draw destroyers
    -- love.graphics.setColor(0.8, 0.2, 0.2)
    -- for _, a in ipairs(destroyer.locations) do
    --     love.graphics.rectangle(
    --         'line',
    --         a.x * windowScale + xOffset,
    --         a.y * windowScale + yOffset,
    --         a.width * windowScale,
    --         a.height * windowScale
    --     )
    -- end
end

return destroyer