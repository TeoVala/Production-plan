local sound = require("src.sys.soundHandling")
local levelData = require('src.levels.levelData')

local menu = {}
local window = require("src.window")

-- Store tile indices for decorative elements
local decorativeTiles = {}

-- Menu items configuration
local menuItems = {
    { text = "New Game",     action = "startGame",  level = 1 },
    { text = "How to play",  action = "howToPlay" },
    { text = "Quit",         action = "quit" }
}

-- Menu state
local selectedItem = 1
local titleScale = 1.0
local titleScaleDir = 1
local menuItemsScale = {}
local menuState = "main" -- Can be "main", "levelSelect", "howToPlay"

-- Level selection submenu
local levelMenuItems = {
    { text = "Level 1", action = "startGame", level = 1 },
    { text = "Level 2", action = "selectedlevel", level = 2 },
    { text = "Level 3", action = "selectedlevel", level = 3 },
    { text = "Back",    action = "mainMenu" }
}
local selectedLevelItem = 1

-- How to play content
local howToPlayText = {
    "How to Play",
    "",
    "Move: W, A, S, D or Arrow Keys - Pickup: Space",
    "",
    "Collect items matching the production plan in the top right",
    "There are 3 rareties that will multiply your score and are as follows",
    "White-Common, Green-Kinda rare idk, Blue-super rare",
    "Also if you pick the items in the right sequence ",
    "you will get some extra points",
    "Also watch out!Our machines haven't been serviced since a decade ago there will be things flying all over the place. ",
    "",
    "And remember if you don't follow the plan you are no factory man!",
}

function menu.load()
    sound.resume()
    -- Initialize scale for each menu item
    for i = 1, #menuItems do
        menuItemsScale[i] = 1.0
    end

    -- Initialize decorative tiles (generate random tiles only once)
    for i = 1, 20 do
        decorativeTiles[i] = {
            tileIndex = { math.random(1, 8), math.random(1, 3) },
            size = (5 + i % 2) -- Base size for this tile
        }
    end
end

function menu.update(dt)
    -- Animate the title with a breathing effect
    titleScale = titleScale + (0.0005 * titleScaleDir)
    if titleScale > 1.1 then
        titleScaleDir = -1
    elseif titleScale < 0.9 then
        titleScaleDir = 1
    end

    -- Animate the selected item
    for i = 1, #menuItems do
        if i == selectedItem then
            menuItemsScale[i] = math.min(1.2, menuItemsScale[i] + dt)
        else
            menuItemsScale[i] = math.max(1.0, menuItemsScale[i] - dt * 2)
        end
    end
end

function menu.draw()
    -- Draw appropriate screen based on menu state
    if menuState == "main" then
        drawMainMenu()
    elseif menuState == "levelSelect" then
        drawLevelSelect()
    elseif menuState == "howToPlay" then
        drawHowToPlay()
    end
end

function drawMainMenu()
    -- Get scaled dimensions
    local screenWidth = window.getCurrentWidth()
    local screenHeight = window.getCurrentHeight()
    local scaleX = window.getScaleX()
    local scaleY = window.getScaleY()

    -- Draw background (could be an image or gradient)
    love.graphics.setColor(0.1, 0.1, 0.2)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

    -- Draw decorative elements using the pre-generated tile indices
    for i = 1, #decorativeTiles do
        love.graphics.setColor(1, 1, 1, 0.3) -- Set transparency for the tiles

        -- Calculate position with oscillating motion
        local x = math.sin(love.timer.getTime() * 0.5 + i) * screenWidth * 0.4 + screenWidth * 0.5
        local y = math.cos(love.timer.getTime() * 0.3 + i) * screenHeight * 0.4 + screenHeight * 0.5
        local size = decorativeTiles[i].size * scaleY


        tileSet = tileset:getTileIndex(decorativeTiles[i].tileIndex[1], decorativeTiles[i].tileIndex[2])
        -- Draw the tile (using the consistent tileIndex for this element)
        tileset:drawTile(
            tileSet,
            x,
            y,
            size,
            love.timer.getTime() * 0.2 + i * 0.1 -- Rotating tiles
        )
    end

    -- Draw title with animation
    love.graphics.setColor(1, 1, 1)
    local titleFont = love.graphics.newFont(48 * scaleY)
    love.graphics.setFont(titleFont)

    -- Apply animated title scale
    love.graphics.push()
    love.graphics.translate(screenWidth / 2, screenHeight * 0.2)
    love.graphics.scale(titleScale, titleScale)
    love.graphics.printf("Production Plan", -screenWidth / 2, 0, screenWidth, "center")
    love.graphics.pop()

    -- Draw menu items
    local menuY = screenHeight * 0.4
    local itemSpacing = 50 * scaleY

    for i, item in ipairs(menuItems) do
        local itemFont = love.graphics.newFont(24 * scaleY * menuItemsScale[i])
        love.graphics.setFont(itemFont)

        if i == selectedItem then
            -- Gradient for selected item
            love.graphics.setColor(1, 0.8, 0.2)
        else
            love.graphics.setColor(0.8, 0.8, 0.8)
        end

        -- Drop shadow
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.printf(item.text, 2 * scaleX, menuY + (i - 1) * itemSpacing + 2 * scaleY, screenWidth, "center")

        -- Actual text
        if i == selectedItem then
            love.graphics.setColor(1, 0.8, 0.2)
        else
            love.graphics.setColor(0.8, 0.8, 0.8)
        end
        love.graphics.printf(item.text, 0, menuY + (i - 1) * itemSpacing, screenWidth, "center")
    end

    -- Draw footer
    love.graphics.setColor(1, 1, 1, 0.7)
    local smallFont = love.graphics.newFont(14 * scaleY)
    love.graphics.setFont(smallFont)
    love.graphics.printf("© 2025 - Production Plan by Astrodreadd aka TeoVala, Everything made by me :)", 0,
        screenHeight - 40 * scaleY, screenWidth, "center")
    love.graphics.printf("Made for LÖVE Jam 2025", 0, screenHeight - 40 * scaleY, screenWidth / 4, "center")

    -- Navigation hint
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.printf("Use arrow keys or WASD to navigate, Enter or Space to select", 0, screenHeight - 20 * scaleY,
        screenWidth, "center")

    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

function drawLevelSelect()
    -- Get scaled dimensions
    local screenWidth = window.getCurrentWidth()
    local screenHeight = window.getCurrentHeight()
    local scaleX = window.getScaleX()
    local scaleY = window.getScaleY()

    -- Draw background
    love.graphics.setColor(0.1, 0.1, 0.2)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

    -- Draw title
    love.graphics.setColor(1, 1, 1)
    local titleFont = love.graphics.newFont(36 * scaleY)
    love.graphics.setFont(titleFont)
    love.graphics.printf("Select Level", 0, screenHeight * 0.15, screenWidth, "center")

    -- Draw level items
    local menuY = screenHeight * 0.3
    local itemSpacing = 50 * scaleY

    for i, item in ipairs(levelMenuItems) do
        local fontSize = 24 * scaleY
        if i == selectedLevelItem then
            fontSize = 28 * scaleY
        end

        local itemFont = love.graphics.newFont(fontSize)
        love.graphics.setFont(itemFont)

        if i == selectedLevelItem then
            love.graphics.setColor(1, 0.8, 0.2)
        else
            love.graphics.setColor(0.8, 0.8, 0.8)
        end

        love.graphics.printf(item.text, 0, menuY + (i - 1) * itemSpacing, screenWidth, "center")
    end

    -- Navigation hint
    love.graphics.setColor(1, 1, 1, 0.5)
    local smallFont = love.graphics.newFont(14 * scaleY)
    love.graphics.setFont(smallFont)
    love.graphics.printf("Press ESC to go back", 0, screenHeight - 20 * scaleY, screenWidth, "center")

    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

function drawHowToPlay()
    -- Get scaled dimensions
    local screenWidth = window.getCurrentWidth()
    local screenHeight = window.getCurrentHeight()
    local scaleY = window.getScaleY()

    -- Draw background
    love.graphics.setColor(0.1, 0.1, 0.2)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

    -- Draw instructions
    local textY = screenHeight * 0.2
    local lineSpacing = 30 * scaleY

    for i, line in ipairs(howToPlayText) do
        love.graphics.setColor(1, 1, 1)

        if i == 1 then
            -- Title
            local titleFont = love.graphics.newFont(36 * scaleY)
            love.graphics.setFont(titleFont)
            love.graphics.printf(line, 0, textY, screenWidth, "center")
            textY = textY + 60 * scaleY
        else
            -- Regular text
            local textFont = love.graphics.newFont(20 * scaleY)
            love.graphics.setFont(textFont)
            love.graphics.printf(line, screenWidth * 0.2, textY, screenWidth * 0.6, "left")
            textY = textY + lineSpacing
        end
    end

    -- Navigation hint
    love.graphics.setColor(1, 1, 1, 0.5)
    local smallFont = love.graphics.newFont(14 * scaleY)
    love.graphics.setFont(smallFont)
    love.graphics.printf("Press Enter or Space or ESC to return to menu", 0, screenHeight - 20 * scaleY, screenWidth,
        "center")

    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

function menu.keypressed(key)
    print("Menu keypressed handler with key: " .. key)

    if menuState == "main" then
        return handleMainMenuKeys(key)
    elseif menuState == "levelSelect" then
        return handleLevelSelectKeys(key)
    elseif menuState == "howToPlay" then
        return handleHowToPlayKeys(key)
    end

    return nil
end

function handleMainMenuKeys(key)
    if key == "up" or key == "w" then
        selectedItem = selectedItem - 1
        if selectedItem < 1 then
            selectedItem = #menuItems
        end
        return { action = "navigate" }
    elseif key == "down" or key == "s" then
        selectedItem = selectedItem + 1
        if selectedItem > #menuItems then
            selectedItem = 1
        end
        return { action = "navigate" }
    elseif key == "return" or key == "space" then
        -- Get the selected item
        local item = menuItems[selectedItem]

        -- Handle different actions
        if item.action == "startGame" then
            gameState = 'play'
            return
        
        elseif item.action == "selectLevel" then
            menuState = "levelSelect"
            return { action = "changeScreen", screen = "levelSelect" }
        elseif item.action == "howToPlay" then
            menuState = "howToPlay"
            return { action = "changeScreen", screen = "howToPlay" }
        elseif item.action == "quit" then
            love.event.quit()
        end
    elseif key == "escape" then
        love.event.quit()
    end

    return nil
end

function handleLevelSelectKeys(key)
    if key == "up" or key == "w" then
        selectedLevelItem = selectedLevelItem - 1
        if selectedLevelItem < 1 then
            selectedLevelItem = #levelMenuItems
        end
        return { action = "navigate" }
    elseif key == "down" or key == "s" then
        selectedLevelItem = selectedLevelItem + 1
        if selectedLevelItem > #levelMenuItems then
            selectedLevelItem = 1
        end
        return { action = "navigate" }
    elseif key == "return" or key == "space" then
        local item = levelMenuItems[selectedLevelItem]

        if item.action == "startGame" then
            menuState = "main" -- Reset menu state before starting game
            return item        -- Return the level item to start the game
        elseif item.action == "mainMenu" then
            menuState = "main"
            return { action = "changeScreen", screen = "main" }
        end
    elseif key == "escape" then
        menuState = "main"
        return { action = "changeScreen", screen = "main" }
    end

    return nil
end

function handleHowToPlayKeys(key)
    if key == "return" or key == "space" or key == "escape" then
        menuState = "main"
        return { action = "changeScreen", screen = "main" }
    end

    return nil
end

return menu
