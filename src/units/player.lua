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

    -- For hit collision stuff
    player.invulnerable = false
    player.invulnerabilityTimer = 0
    player.isFlashing = false
    player.flashTimer = 0
    player.flashDuration = 0.2         -- Duration of each flash (on or off)
    player.isDead = false
    player.invulnerabilityDuration = 2.5 -- Duration of invulnerability in seconds

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

-- Add a variable to track collisions for debugging
player.debugInfo = {
    playerRect = nil,
    wallRects = {},
    checkingTiles = {},
    lastCollision = nil,
    collisionTime = 0
}

function player.makeInvulnerable(duration)
    player.invulnerable = true
    player.invulnerabilityTimer = 1 or player.invulnerabilityDuration
    player.isFlashing = true
    player.flashTimer = player.flashDuration
end

function invulnerabilityForTheWeak(dt)
    -- Update invulnerability timer
    if player.invulnerable then
        player.invulnerabilityTimer = player.invulnerabilityTimer - dt

        -- Flash effect handling
        player.flashTimer = player.flashTimer - dt
        if player.flashTimer <= 0 then
            player.isFlashing = not player.isFlashing
            player.flashTimer = player.flashDuration
        end

        -- End invulnerability when timer expires
        if player.invulnerabilityTimer <= 0 then
            player.invulnerable = false
            player.isFlashing = false
        end
    end

    -- If player has just started returning, make them invulnerable
    if player.returning and not player.invulnerable then
        player.makeInvulnerable(player.invulnerabilityDuration)
    end

    -- Check if player health is depleted
    if playerHealth <= 0 and not player.isDead then
        player.isDead = true
        isPaused = true
    end
end

-- Function to update player invulnerability state
function updatePlayerInvulnerability(player, dt)
    if player.invulnerable then
        player.invulnerabilityTimer = player.invulnerabilityTimer - dt

        -- Handle flashing effect
        if player.isFlashing then
            player.flashTimer = player.flashTimer - dt
            if player.flashTimer <= 0 then
                player.isFlashing = not player.isFlashing
                player.flashTimer = 0.1 -- Reset flash timer
            end
        end

        -- Check if invulnerability period is over
        if player.invulnerabilityTimer <= 0 then
            player.invulnerable = false
            player.isFlashing = false
        end
    end
end

-- Debug draw function to visualize collisions
function player.drawDebug()
    local windowScale = math.min(window.getScaleX(), window.getScaleY())
    local xOffset = (window.getCurrentWidth() - window.getOriginalWidth() * windowScale) / 2
    local yOffset = (window.getCurrentHeight() - window.getOriginalHeight() * windowScale) / 2

    -- Draw player hitbox
    if player.debugInfo.playerRect then
        love.graphics.setColor(0, 1, 0, 0.5) -- Green semi-transparent
        love.graphics.rectangle("line",
            player.debugInfo.playerRect.left * windowScale + xOffset,
            player.debugInfo.playerRect.top * windowScale + yOffset,
            (player.debugInfo.playerRect.right - player.debugInfo.playerRect.left) * windowScale,
            (player.debugInfo.playerRect.bottom - player.debugInfo.playerRect.top) * windowScale
        )
    end

    -- Draw wall tiles being checked
    love.graphics.setColor(1, 1, 0, 0.3) -- Yellow semi-transparent
    for _, tileRect in ipairs(player.debugInfo.checkingTiles) do
        love.graphics.rectangle("line",
            tileRect.left * windowScale + xOffset,
            tileRect.top * windowScale + yOffset,
            (tileRect.right - tileRect.left) * windowScale,
            (tileRect.bottom - tileRect.top) * windowScale
        )
    end

    -- Draw wall rects that are colliding
    love.graphics.setColor(1, 0, 0, 0.5) -- Red semi-transparent
    for _, wallRect in ipairs(player.debugInfo.wallRects) do
        love.graphics.rectangle("fill",
            wallRect.left * windowScale + xOffset,
            wallRect.top * windowScale + yOffset,
            (wallRect.right - wallRect.left) * windowScale,
            (wallRect.bottom - wallRect.top) * windowScale
        )
    end

    -- Draw last collision point
    if player.debugInfo.lastCollision and player.debugInfo.collisionTime > 0 then
        love.graphics.setColor(1, 0, 1, player.debugInfo.collisionTime) -- Purple fading
        love.graphics.circle("fill",
            player.debugInfo.lastCollision.x * windowScale + xOffset,
            player.debugInfo.lastCollision.y * windowScale + yOffset,
            5 * windowScale
        )
        player.debugInfo.collisionTime = player.debugInfo.collisionTime - 0.01
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)

    -- Draw debug text
    love.graphics.print("Player Position: " .. math.floor(player.x) .. ", " .. math.floor(player.y), 10, 10)
    love.graphics.print("Velocity: " .. string.format("%.2f", player.xvel) .. ", " .. string.format("%.2f", player.yvel),
        10, 30)
    love.graphics.print("Checking Tiles: " .. #player.debugInfo.checkingTiles, 10, 50)
    love.graphics.print("Wall Collisions: " .. #player.debugInfo.wallRects, 10, 70)
end

function player.checkWallCollision()
    -- Clear previous debug info
    player.debugInfo.checkingTiles = {}
    player.debugInfo.wallRects = {}

    -- Get the map data
    local mapTiles = map.mapTiles
    if not mapTiles then return false, nil end

    -- Calculate map dimensions
    local mapWidth = #mapTiles[1]
    local mapHeight = #mapTiles

    -- Center the map (same calculation as in mapRender.lua)
    local mapX = ((window.getOriginalWidth() - (mapWidth * tileSize * tileScale)) / 2) - tileSize
    local mapY = ((window.getOriginalHeight() - (mapHeight * tileSize * tileScale)) / 2) - tileSize

    -- Calculate player hitbox
    local playerWidth = 12 * tileScale -- Slightly smaller than tile size
    local playerHeight = 12 * tileScale


    local playerLeft = player.x - playerWidth / 2
    local playerRight = player.x + playerWidth / 2
    local playerTop = (player.y - playerHeight / 2) + tileSize / 2 -- Adjust top collision as requested
    local playerBottom = (player.y + playerHeight / 2 + player.targetY) - tileSize

    -- Save player rect for debug drawing
    player.debugInfo.playerRect = {
        left = playerLeft,
        top = playerTop,
        right = playerRight,
        bottom = playerBottom
    }

    -- Determine which tiles the player is currently overlapping with
    local startTileX = math.floor((playerLeft - mapX) / (tileSize * tileScale)) + 1
    local endTileX = math.floor((playerRight - mapX) / (tileSize * tileScale)) + 1
    local startTileY = math.floor((playerTop - mapY) / (tileSize * tileScale)) + 1
    local endTileY = math.floor((playerBottom - mapY) / (tileSize * tileScale)) + 1

    -- Clamp to map boundaries
    startTileX = math.max(1, startTileX)
    endTileX = math.min(mapWidth, endTileX)
    startTileY = math.max(1, startTileY)
    endTileY = math.min(mapHeight, endTileY)

    -- Track collisions
    local foundCollision = false
    local allCollidingRects = {}

    -- Check for wall collisions (tiles 20-27 are walls)
    for y = startTileY, endTileY do
        for x = startTileX, endTileX do
            local tileValue = mapTiles[y][x]

            -- Calculate tile position
            local tileX = mapX + ((x - 1) * tileSize * tileScale)
            local tileY = mapY + ((y - 1) * tileSize * tileScale)

            -- Create collision rect for the tile
            local tileRect = {
                left = tileX,
                top = tileY,
                right = tileX + tileSize * tileScale,
                bottom = tileY + tileSize * tileScale
            }

            -- Add to checking tiles for debug
            table.insert(player.debugInfo.checkingTiles, tileRect)

            -- Wall tiles are in the range 20-27
            if tileValue >= 20 and tileValue <= 27 then
                -- Create collision rect for the player
                local playerRect = {
                    left = playerLeft,
                    top = playerTop,
                    right = playerRight,
                    bottom = playerBottom
                }

                -- Check for collision
                if player.checkCollision(playerRect, tileRect) then
                    -- Add to wall rects for debug
                    table.insert(player.debugInfo.wallRects, tileRect)
                    table.insert(allCollidingRects, tileRect)

                    -- Record collision point
                    player.debugInfo.lastCollision = {
                        x = player.x,
                        y = player.y
                    }
                    player.debugInfo.collisionTime = 1.0

                    foundCollision = true
                end
            end
        end
    end

    return foundCollision, allCollidingRects
end

-- Player physics
function physics(dt)
    -- Store previous position
    local prevX, prevY = player.x, player.y

    -- Apply velocity
    player.x = player.x + player.xvel * dt
    player.y = player.y + player.yvel * dt

    -- Check for wall collision
    local collision, wallRects = player.checkWallCollision()

    -- If collision occurred, resolve it
    if not player.isLowering and not player.returning and collision then
        -- Handle each colliding wall
        for _, wallRect in ipairs(wallRects) do
            -- Calculate player hitbox with the same adjustments as in checkWallCollision
            local playerWidth = 12 * tileScale
            local playerHeight = 12 * tileScale

            local playerRect = {
                left = player.x - playerWidth / 2,
                right = player.x + playerWidth / 2,
                top = (player.y - playerHeight / 2) + tileSize / 2, -- Adjust top collision
                bottom = (player.y + playerHeight / 2 + player.targetY) - tileSize
            }

            -- Calculate overlap in each direction
            local overlapLeft = playerRect.right - wallRect.left
            local overlapRight = wallRect.right - playerRect.left
            local overlapTop = playerRect.bottom - wallRect.top
            local overlapBottom = wallRect.bottom - playerRect.top

            -- Find minimum overlap
            local minOverlap = math.min(overlapLeft, overlapRight, overlapTop, overlapBottom)

            -- Resolve by the minimum overlap direction
            if minOverlap == overlapLeft and player.xvel > 0 then
                player.x = player.x - overlapLeft
                player.xvel = 0
            elseif minOverlap == overlapRight and player.xvel < 0 then
                player.x = player.x + overlapRight
                player.xvel = 0
            elseif minOverlap == overlapTop and player.yvel > 0 then
                player.y = player.y - overlapTop
                player.yvel = 0
            elseif minOverlap == overlapBottom and player.yvel < 0 then
                player.y = player.y + overlapBottom
                player.yvel = 0
            end
        end
    end

    -- Apply friction
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
    
    invulnerabilityForTheWeak(dt)
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

    -- Don't draw the player if flashing during invulnerability
    if player.invulnerable and player.isFlashing then
        -- Skip drawing the player sprite when flashing
        -- But still draw debug info and collision boxes if needed
        if debugMode then
            player.drawDebugInfo()
            player.drawHitbox()
        end
        return
    end

    -- Draw the player
    love.graphics.setColor(1, 1, 1)
    if player.returning then
        tileset:drawTile(tileset:getTileIndex(5, 2), player.x, player.y - (shadowHeight * 3.5), scaleChar, 0)
    else
        tileset:drawTile(tileset:getTileIndex(5, 1), player.x, player.y, scaleChar, 0)
    end


    -- Draw collision hit box

    -- -- Draw the player hitbox in green with transparency
    -- local windowScale = math.min(window.getScaleX(), window.getScaleY())

    -- local xOffset = (window.getCurrentWidth() - window.getOriginalWidth() * windowScale) / 2
    -- local yOffset = (window.getCurrentHeight() - window.getOriginalHeight() * windowScale) / 2

    -- local playerWidth = 16 * windowScale
    -- local playerHeight = 16 * windowScale

    -- local playerHitboxWidth = playerWidth * 1.5
    -- local playerHitboxHeight = playerHeight * 1.5

    -- local playerHitboxX = (player.x - tileSize / 2) * windowScale + (playerWidth - playerHitboxWidth) / 2
    -- local playerHitboxY = (player.y - tileSize / 2) * windowScale + (playerHeight - playerHitboxHeight) / 2


    -- -- Draw the player hitbox in green with transparency
    -- love.graphics.setColor(1, 0, 0, 0.8) -- Green with alpha

    -- love.graphics.rectangle(
    --     "line",
    --     playerHitboxX + xOffset,
    --     playerHitboxY + yOffset,
    --     playerHitboxWidth,
    --     playerHitboxHeight
    -- )

    -- -- Reset color
    -- love.graphics.setColor(1, 1, 1, 1)

    -- Draw collision hitbox END
    -- player.drawDebug()
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
