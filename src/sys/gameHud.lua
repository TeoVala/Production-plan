local window = require('src.window')

hud = {}
-- itemsValuesId all local locations

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

function hud.update(dt)
end

function hud.drawScore()
    -- Define the score display parameters
    local scoreX = 20 -- Position from left edge
    local scoreY = 20 -- Position from top edge
    local fontSize = 1.2 -- Scale of the font
    local scoreText = "Score: " .. scoreNum
    local padding = 10 -- Padding inside the box

    -- Calculate text dimensions
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(scoreText) * fontSize
    local textHeight = font:getHeight() * fontSize

    -- Draw the box with cool effect
    love.graphics.setColor(0.1, 0.1, 0.3, 0.8)                                  -- Dark blue background
    love.graphics.rectangle('fill', scoreX - padding, scoreY - padding,
        textWidth + padding * 2, textHeight + padding * 2, 8, 8)                -- Rounded corners

    -- Draw glowing border
    love.graphics.setColor(0.4, 0.6, 1, 0.7) -- Light blue glow
    love.graphics.setLineWidth(3)
    love.graphics.rectangle('line', scoreX - padding, scoreY - padding,
        textWidth + padding * 2, textHeight + padding * 2, 8, 8)

    -- Add inner highlight line
    love.graphics.setColor(0.8, 0.9, 1, 0.5) -- Lighter blue inner highlight
    love.graphics.setLineWidth(1)
    love.graphics.rectangle('line', scoreX - padding + 3, scoreY - padding + 3,
        textWidth + padding * 2 - 6, textHeight + padding * 2 - 6, 6, 6)

    -- Draw the text
    love.graphics.setColor(1, 1, 1, 1) -- White text
    love.graphics.print(scoreText, scoreX, scoreY, 0, fontSize, fontSize)

    -- Reset line width
    love.graphics.setLineWidth(1)
end

function hud.draw(tileScale)
    -- Get the window scale parameters
    local scaleX = window.getScaleX()
    local scaleY = window.getScaleY()
    local windowWidth = window.getCurrentWidth()
    local windowHeight = window.getCurrentHeight()

    -- Calculate a combined scale factor for UI elements
    local uiScale = math.min(scaleX, scaleY) * tileScale

    -- Define HUD box dimensions and position
    local boxPadding = 8 * uiScale
    local tileSize = 25 * uiScale
    local tileSpacing = 5 * uiScale
    local boxWidth = (tileSize * 3) + (tileSpacing * 2) + (boxPadding * 2)
    local boxHeight = tileSize + (boxPadding * 2)

    -- Position the box at the top right corner with some margin
    local boxX = windowWidth - boxWidth - 20 * uiScale
    local boxY = 30 * uiScale

    local fontSize = .8 * uiScale
    local titleY = boxY - 15 * uiScale
    local scoreY = boxY * uiScale + 200

    love.graphics.print("Machine plan", boxX, titleY, 0, fontSize, fontSize)
    -- love.graphics.print("Score: " .. scoreNum, boxX, scoreY, 0, fontSize, fontSize)
    -- Draw the box background with semi-transparency
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle('fill', boxX, boxY, boxWidth, boxHeight)

    -- Draw border for the box
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.rectangle('line', boxX, boxY, boxWidth, boxHeight)

    -- Draw the three tiles inside the box using the item system
    love.graphics.setColor(1, 1, 1, 1)

    local windowScale = math.min(window.getScaleX(), window.getScaleY())
    local xOffset = (window.getCurrentWidth() - window.getOriginalWidth() * windowScale) / 2
    local yOffset = (window.getCurrentHeight() - window.getOriginalHeight() * windowScale) / 2

    -- Draw rects around collected items
    for i = 1, #currPlan do
        local tileX = boxX + boxPadding + (i - 1) * (tileSize + tileSpacing)
        local tileY = boxY + boxPadding

        -- Get item type from the ID
        local itemId = currPlan[i]
        local itemType = itemsValuesId[itemId]

        if itemType then
            local col, row = itemType[1], itemType[2]
            local tileIndex = itemsTileset:getTileIndex(col, row)

            -- Calculate center position for the tile
            local itemCenterX = tileX + tileSize / 2
            local itemCenterY = tileY + tileSize / 2

            local tileDrawX = (itemCenterX - xOffset) / windowScale
            local tileDrawY = (itemCenterY - yOffset) / windowScale

            -- Draw the actual item
            love.graphics.setColor(1, 1, 1)
            itemsTileset:drawTile(
                tileIndex,
                tileDrawX,
                tileDrawY,
                tileScale * 1.40,
                0
            )
        end

        -- Draw rectangle indicator based on match status
        if planItemsStatus[i] and planItemsStatus[i][2] == true then
            -- Green rectangle for correct items
            love.graphics.setColor(0, 1, 0, 0.7)
            love.graphics.rectangle('line', tileX - 2, tileY - 2, tileSize + 4, tileSize + 4, 3, 3)
        else
            -- Red rectangle for items in wrong position or missing
            love.graphics.setColor(1, 0, 0, 0.7)
            love.graphics.rectangle('line', tileX - 2, tileY - 2, tileSize + 4, tileSize + 4, 3, 3)
        end

        love.graphics.setColor(1, 1, 1, 1)
    end
    hud.drawScore()
    -- love.graphics.print("Currplan: " .. tableToString(currPlan), 10, 10)
end

return hud
