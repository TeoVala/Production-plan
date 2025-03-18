player = {}

local window = require("src.window") -- Require the window module to access scale factors

function player.load()
    player.x = 400
    player.y = 400
    player.xvel = 0
    player.yvel = 0
    player.friction = 5
    player.speed = 800

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
        if love.keyboard.isDown("d") or love.keyboard.isDown("right") and
            player.xvel < player.speed then
            player.xvel = player.xvel + player.speed * dt
        end

        if love.keyboard.isDown("a") or love.keyboard.isDown("left") and
            player.xvel > -player.speed then
            player.xvel = player.xvel - player.speed * dt
        end

        if love.keyboard.isDown("s") or love.keyboard.isDown("down") and
            player.yvel < player.speed then
            player.yvel = player.yvel + player.speed * dt
        end

        if love.keyboard.isDown("w") or love.keyboard.isDown("up") and
            player.yvel > -player.speed then
            player.yvel = player.yvel - player.speed * dt
        end

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

function player.update(dt)
    physics(dt)
    hookStuff(dt)
    move(dt)
end

function player.draw(scaleChar)
    -- Draw shadow
    local windowScale = math.min(window.getScaleX(), window.getScaleY())
    local xOffset = (window.getCurrentWidth() - window.getOriginalWidth() * windowScale) / 2
    local yOffset = (window.getCurrentHeight() - window.getOriginalHeight() * windowScale) / 2

    -- Since tiles are 16x16, calculate the center point of the player
    local tileWidth = 16
    local tileHeight = 16

    -- Calculate the center position of the player
    local centerX = player.x + (tileWidth * scaleChar / 2)
    local centerY = player.y + (tileHeight * scaleChar / 2)

    -- Calculate shadow dimensions - scale proportionally with the character
    local shadowHeight = 3 * scaleChar
    local shadowWidth = 8 * scaleChar

    -- Draw the shadow (red ellipse)
    love.graphics.setColor(0, 0, 0, .60)
    
    if not player.isLowering and not player.returning then
        love.graphics.ellipse(
            "fill",
            centerX * windowScale + xOffset,
            (centerY + player.targetY) * windowScale + yOffset, -- Position shadow below the player center
            shadowWidth * windowScale,
            shadowHeight * windowScale
        )
    else
        love.graphics.ellipse(
            "fill",
            centerX * windowScale + xOffset,
            (player.startingY + (tileHeight * scaleChar / 2) + player.targetY)* windowScale + yOffset, -- Position shadow to final position
            shadowWidth * windowScale,
            shadowHeight * windowScale
        )
    end

    -- Draw the player
    love.graphics.setColor(1, 1, 1)
    if player.returning then
        tileset:drawTile(tileset:getTileIndex(7, 2), player.x, player.y-(shadowHeight*3.5), scaleChar, 0)
    else
        tileset:drawTile(tileset:getTileIndex(7, 1), player.x, player.y, scaleChar, 0)
    end
    

    -- Reset color and draw debug info
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Lowering: " .. tostring(player.isLowering), 10, 10)
    love.graphics.print("Returning: " .. tostring(player.returning), 10, 30)
    love.graphics.print("Y position: " .. tostring(math.floor(player.y)), 10, 50)
    love.graphics.print("Target: " .. tostring(player.startingY + player.targetY), 10, 70)
    love.graphics.print("Y offset: " .. tostring(math.floor(windowScale)), 10, 100)

    love.graphics.print("Delay: " .. tostring(math.floor(player.currentDelay * 10) / 10), 10, 90)
    
    
end

return player
