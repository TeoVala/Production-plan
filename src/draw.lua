local window = require('src.window')
local player = require("src.units.player")
local map = require("src.mapRender")
local item = require("src.units.item")
local spawner = require("src.units.spawner")
local destroyer = require("src.units.destroyer")
local hud = require("src.sys.gameHud")
local bulletSpawner = require("src.units.bulletHell.bulletSpawner")

function draw()
    -- Clear with background color
    love.graphics.clear(0.1, 0.1, 0.3)

    map.draw(tileScale)

    player.drawShadow(tileScale)
    item.draw(tileScale)

    -- Draw spawner and destroyer debug visuals (optional)
    spawner.draw(tileScale)
    destroyer.draw(tileScale)


    -- Draw player
    player.draw(tileScale)


    -- Draw bullethell
    bulletSpawner.draw(tileScale)

    -- Draw hud
    hud.draw(tileScale)

    if isPaused then
        -- Get window dimensions
        local windowWidth = love.graphics.getWidth()
        local windowHeight = love.graphics.getHeight()

        -- Define rectangle dimensions
        local rectWidth = 250
        local rectHeight = 150

        -- Calculate top-left position to center the rectangle
        local x = windowWidth / 2 - rectWidth / 2
        local y = windowHeight / 2 - rectHeight / 2

        -- Draw teal HUD panel (slightly smaller than the background)
        love.graphics.setColor(0 / 255, 128 / 255, 128 / 255) -- Teal color
        local padding = 10
        love.graphics.rectangle("fill",
            x + padding,
            y + padding,
            rectWidth - padding * 2,
            rectHeight - padding * 2,
            10, -- rounded corners radius
            10  -- rounded corners segments
        )

        -- Store the current font so we can restore it later
        local defaultFont = love.graphics.getFont()

        -- Create a larger font
        local font = love.graphics.newFont(18)
        love.graphics.setFont(font)

        -- Prepare score text
        local scoreText = "Score: " .. scoreNum

        -- Get text dimensions to center it
        local textWidth = font:getWidth(scoreText)
        local textHeight = font:getHeight()

        -- Draw text (white, centered in the teal box)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(
            scoreText,
            x + rectWidth / 2 - textWidth / 2,
            y + rectHeight / 2 - textHeight / 2
        )

        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line",
            x + padding,
            y + padding,
            rectWidth - padding * 2,
            rectHeight - padding * 2,
            10,
            10
        )

        love.graphics.setColor(1, 1, 1, 0.6)
        love.graphics.circle("fill", x + padding + 15, y + padding + 15, 5)
        love.graphics.circle("fill", x + rectWidth - padding - 15, y + padding + 15, 5)

        -- Reset color and font to defaults for other drawings
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(defaultFont)
    end

    -- Draw debug info
    window.drawDebugInfo()
end
