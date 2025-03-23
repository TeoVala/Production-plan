player = {}

local window = require("src.window") -- Require the window module to access scale factors
local score = require("src.sys.score")

function player.load()
    player.x = 400
    player.y = 400
    player.xvel = 0
    player.yvel = 0
    player.friction = 5.8
    player.speed = 1200
    grabThreshold = 2.35

    -- Lower crane
    player.startingY = player.y
    player.targetY = 40
    player.isLowering = false
    player.returning = false

    player.loweringSpeed = 120
    player.returnSpeed = 80

    -- Wait a moment before starting to return (optional)
    player.returnDelay = .2 -- Half a second delay
    player.currentDelay = 0
end

-- Player physics
function physics(dt)
    player.x = player.x + player.xvel * dt
    player.y = player.y + player.yvel * dt
    player.xvel = player.xvel * (1 - math.min(dt * player.friction, 1))
    player.yvel = player.yvel * (1 - math.min(dt * player.friction, 1))
end

function move(dt)
    if not player.isLowering and not player.returning then
        -- Get input directions first
        local xInput = 0
        local yInput = 0

        if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
            xInput = 1
        elseif love.keyboard.isDown("a") or love.keyboard.isDown("left") then
            xInput = -1
        end

        if love.keyboard.isDown("s") or love.keyboard.isDown("down") then
            yInput = 1
        elseif love.keyboard.isDown("w") or love.keyboard.isDown("up") then
            yInput = -1
        end

        -- Normalize diagonal movement
        if xInput ~= 0 and yInput ~= 0 then
            local length = math.sqrt(2)
            xInput = xInput / length
            yInput = yInput / length
        end

        -- Apply input to velocity
        player.xvel = player.xvel + xInput * player.speed * dt
        player.yvel = player.yvel + yInput * player.speed * dt

        if love.keyboard.isDown("space") and not player.isLowering and not player.returning then
            startLowering()
        end
    end
end

function startLowering()
    if not player.isLowering and not player.returning then
        player.startingY = player.y
        player.isLowering = true
        player.xvel = 0                    -- Stop moving x
        player.yvel = player.loweringSpeed -- Start moving down
    end
end

function hookStuff(dt)
    if player.isLowering then
        -- When lowering, apply downward velocity
        player.yvel = player.loweringSpeed

        -- Check if we've reached the target Y
        if player.y >= player.startingY + player.targetY then
            player.y = player.startingY + player.targetY -- Snap to exact position
            player.yvel = 0                              -- Stop movement
            player.isLowering = false
            player.returning = true                      -- Start returning process

            -- Wait a moment before starting to return (optional)
            player.currentDelay = player.returnDelay -- Start the delay timer
        end
    elseif player.returning then
        player.grabItem()

        if player.currentDelay > 0 then
            player.currentDelay = player.currentDelay - dt
            -- physics and move should still be called while the delay is active
        else
            -- Move back toward starting position
            player.yvel = -player.returnSpeed

            -- Check if we've reached the starting position
            if player.y <= player.startingY then
                player.y = player.startingY -- Snap to exact position
                player.yvel = 0             -- Stop movement
                player.returning = false    -- End returning process
            end
        end
    end
end

-- Simple AABB collision check
function player.checkCollision(rect1, rect2)
    return not (
        rect1.right < rect2.left or
        rect1.left > rect2.right or
        rect1.bottom < rect2.top or
        rect1.top > rect2.bottom
    )
end

function player.grabItem()
    if not player.returning then
        return {}
    end

    local itemGrabbed = {}
    local grabThreshold = 2.35

    -- Get window scale factor (using the same approach as in tileset.lua)
    local windowScale = math.min(window.getScaleX(), window.getScaleY())
    local xOffset = (window.getCurrentWidth() - window.getOriginalWidth() * windowScale) / 2

    local tileScale = 16
    local grabberSize = tileScale * windowScale -- Scale up with window size

    -- Destroyer rectangles AABB collisions
    local playerRect = {
        left = player.x * windowScale - grabberSize / 2,
        top = player.y * windowScale - grabberSize / 2,
        right = player.x * windowScale + grabberSize / 2,
        bottom = player.y * windowScale + grabberSize / 2
    }

    -- Safety check - if levelItems isn't available, return empty list
    if not levelItems then
        return {}
    end

    -- Item rects
    for i, item in ipairs(levelItems) do
        local itemRect = {
            left = item.x * windowScale + xOffset - grabberSize,
            top = item.y * windowScale - grabberSize,
            right = (item.x * windowScale + (tileSize * grabThreshold) + xOffset - tileSize),
            bottom = (item.y * windowScale + (tileSize * grabThreshold) - tileSize)
        }

        -- The AABB collision check
        if player.checkCollision(playerRect, itemRect) then
            table.insert(itemGrabbed, i)
        end
    end

    -- Remove items that collided with destroyers
    table.sort(itemGrabbed, function(a, b) return a > b end)
    for _, index in ipairs(itemGrabbed) do
        local itemId = levelItems[index].itemId

        -- Check if this item's ID is in currPlan AND if we haven't reached the limit for this type
        local canAddToPlan = false

        -- Count how many of this item type are already in grabbedItems
        local existingCount = 0
        for _, item in ipairs(grabbedItems) do
            if item[1] == itemId then
                existingCount = existingCount + 1
            end
        end

        -- Count how many of this item type should be in the plan
        local planCount = 0
        for _, planId in ipairs(currPlan) do
            if planId == itemId then
                planCount = planCount + 1
            end
        end

        -- We can add if we haven't reached the limit for this type
        if existingCount < planCount then
            canAddToPlan = true
        end

        if canAddToPlan then
            -- {type, value}
            table.insert(grabbedItems, { itemId, levelItems[index].itemValue })
            table.remove(levelItems, index)


            -- Check if the newly added item matches any item in the plan
            for i, planItem in ipairs(planItemsStatus) do
                local planItemId = planItem[1]

                if itemId == planItemId and planItem[2] == false then
                    -- We found a matching plan item that hasn't been marked as found yet
                    planItemsStatus[i][2] = true
                    break -- Stop after marking the first matching item
                end
            end

            if #grabbedItems >= 3 then -- To make it more parts make this changeable
                score.runCalc()
            end
        else
            table.remove(levelItems, index)
            score.minusScore()
        end
    end
end

function player.update(dt)
    physics(dt)
    hookStuff(dt)
    move(dt)
end

function player.drawShadow(scaleChar)
    -- Draw shadow
    local windowScale = math.min(window.getScaleX(), window.getScaleY())

    local xOffset = (window.getCurrentWidth() - window.getOriginalWidth() * windowScale) / 2
    local yOffset = (window.getCurrentHeight() - window.getOriginalHeight() * windowScale) / 2

    -- Calculate shadow dimensions - scale proportionally with the character

    local shadowHeight = 3 * scaleChar
    local shadowWidth = 8 * scaleChar

    -- Draw the shadow (red ellipse)
    love.graphics.setColor(0, 0, 0, .60)

    if not player.isLowering and not player.returning then
        love.graphics.ellipse(
            "fill",
            player.x * windowScale + xOffset,
            (player.y + player.targetY) * windowScale, -- Position shadow below the player center
            shadowWidth * windowScale,
            shadowHeight * windowScale
        )
    else
        love.graphics.ellipse(
            "fill",
            player.x * windowScale + xOffset,
            (player.startingY + player.targetY) * windowScale + yOffset, -- Position shadow to final position
            shadowWidth * windowScale,
            shadowHeight * windowScale
        )
    end
end

function player.draw(scaleChar)
    -- Draw shadow
    local windowScale = math.min(window.getScaleX(), window.getScaleY())
    local shadowHeight = 3 * scaleChar

    -- Draw the player
    love.graphics.setColor(1, 1, 1)
    if player.returning then
        tileset:drawTile(tileset:getTileIndex(5, 2), player.x, player.y - (shadowHeight * 3.5), scaleChar, 0)
    else
        tileset:drawTile(tileset:getTileIndex(5, 1), player.x, player.y, scaleChar, 0)
    end


    -- Reset color and draw debug info
    -- love.graphics.setColor(1, 1, 1)
    -- love.graphics.print("Lowering: " .. tostring(player.isLowering), 10, 10)
    -- love.graphics.print("Returning: " .. tostring(player.returning), 10, 30)
    -- love.graphics.print("X position: " .. tostring(math.floor(player.x)), 10, 50)
    -- love.graphics.print("Y position: " .. tostring(math.floor(player.y)), 10, 70)
    -- love.graphics.print("Target: " .. tostring(player.startingY + player.targetY), 10, 90)

    -- love.graphics.print("Delay: " .. tostring(math.floor(player.currentDelay * 10) / 10), 10, 130)
end

return player
