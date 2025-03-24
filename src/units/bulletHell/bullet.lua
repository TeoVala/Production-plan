local window = require('src.window')
local bullet = {}
bullet.__index = bullet


-- Todo fix collision when the windows are pretty small loll

-- Bullet tile definitions
local bulletTiles = {
    { 7, 3 }, -- bolt
    { 8, 1 }, -- bolt nut
    { 8, 2 }  -- wrench
}

bullets = {}

-- Bullet coll with player

function checkBulletPlayerCollision(bullet, player)
    -- Get the window scale to ensure consistent collision detection across screen sizes
    local windowScale = math.min(window.getScaleX(), window.getScaleY())

    -- Get player dimensions (assuming player uses tileset rendering)
    local playerWidth = 16 * windowScale
    local playerHeight = 16 * windowScale

    -- Get bullet dimensions (adjust these according to your bullet implementation)
    local bulletWidth, bulletHeight
    if bullet.tileset then
        -- If bullet uses tileset rendering
        bulletWidth = bullet.tileset:getScaledWidth(bullet.scale or 1)
        bulletHeight = bullet.tileset:getScaledHeight(bullet.scale or 1)
    else
        -- If bullet has direct dimensions
        bulletWidth = (bullet.width or 8) * windowScale
        bulletHeight = (bullet.height or 8) * windowScale
    end

    -- Calculate reduced hitbox for more forgiving collision (70% of actual size)
    local playerHitboxWidth = playerWidth * 1.5
    local playerHitboxHeight = playerHeight * 1.5

    -- Center player hitbox
    local playerHitboxX = (player.x - tileSize / 2) * windowScale + (playerWidth - playerHitboxWidth) / 2
    local playerHitboxY = (player.y - tileSize / 2) + (playerHeight - playerHitboxHeight) / 2

    -- Center the bullet hitbox
    local bulletHitboxX = bullet.x * windowScale + (bulletWidth - bulletWidth * 0.8) / 2
    local bulletHitboxY = bullet.y * windowScale + (bulletHeight - bulletHeight * 0.8) / 2
    local bulletHitboxWidth = bulletWidth * 0.8
    local bulletHitboxHeight = bulletHeight * 0.8

    -- Simple AABB collision detection
    if bulletHitboxX < playerHitboxX + playerHitboxWidth and
        bulletHitboxX + bulletHitboxWidth > playerHitboxX and
        bulletHitboxY < playerHitboxY + playerHitboxHeight and
        bulletHitboxY + bulletHitboxHeight > playerHitboxY then
        -- Implement damage with invulnerability period
        if not player.invulnerable then
            -- Decrease player health
            playerHealth = playerHealth - 1

            -- Set player as invulnerable for a short period
            player.invulnerable = true
            player.invulnerabilityTimer = 2.5 -- 1 second of invulnerability

            -- Add visual feedback for the hit
            player.flashTimer = 0.1
            player.isFlashing = true

            -- Mark bullet as inactive or for removal
            bullet.active = false

            -- Play hit sound if available
            if love.audio and sounds and sounds.playerHit then
                sounds.playerHit:play()
            end

            return true
        end
    end

    return false
end

-- Bullet coll END

function bullet.new(x, y, angle, speed, color, radius)
    local self = setmetatable({}, bullet)
    self.x = x
    self.y = y
    self.angle = angle
    self.speed = speed
    self.color = color or { 1, 0, 0 }
    self.radius = radius or 5
    self.active = true

    table.insert(bullets, self)

    -- Select a random bullet tile from the available options
    self.tileType = bulletTiles[math.random(1, #bulletTiles)]
    self.tileIndex = tileset:getTileIndex(self.tileType[1], self.tileType[2])

    -- Random rotation speed (between 1-5 radians per second)
    self.rotationSpeed = math.random(1, 5) * (math.random() > 0.5 and 1 or -1)
    self.rotation = math.random() * math.pi * 2 -- Initial random rotation

    -- Size for the collision box (matches the tile size)
    self.width = tileSize * 0.8
    self.height = tileSize * 0.8

    return self
end

-- Instance method for updating a single bullet
function bullet:update(dt)
    -- Get window scale for consistent movement
    local windowScale = math.min(window.getScaleX(), window.getScaleY())

    -- Move the bullet based on angle and speed (adjusted for window scale)
    self.x = self.x + math.cos(self.angle) * self.speed * dt
    self.y = self.y + math.sin(self.angle) * self.speed * dt

    -- Update rotation
    self.rotation = self.rotation + self.rotationSpeed * dt

    -- Remove bullets that are off-screen (with a margin)
    local margin = self.radius * 2
    if self.x < -margin or self.x > window.getOriginalWidth() + margin or
        self.y < -margin or self.y > window.getOriginalHeight() + margin then
        self.active = false
    end
end

-- Instance method for drawing a single bullet
function bullet:draw(tileScale)
    -- Use window scale for consistent sizing
    local windowScale = math.min(window.getScaleX(), window.getScaleY())

    -- Calculate offsets for window resizing, similar to player.lua
    local xOffset = (window.getCurrentWidth() - window.getOriginalWidth() * windowScale) / 2
    local yOffset = (window.getCurrentHeight() - window.getOriginalHeight() * windowScale) / 2

    -- Draw the tile with rotation
    love.graphics.setColor(1, 1, 1)
    tileset:drawTile(
        self.tileIndex,
        self.x,
        self.y,
        tileScale * 1.25,
        self.rotation
    )


    -- Draw debug collision box
    -- love.graphics.setColor(1, 0, 0, 0.3) -- Semi-transparent red

    -- -- Calculate collision box dimensions and position in screen space
    -- local boxWidth = self.width * tileScale * windowScale
    -- local boxHeight = self.height * tileScale * windowScale

    -- love.graphics.rectangle(
    --     "line",
    --     self.x * windowScale + xOffset - boxWidth / 2,
    --     self.y * windowScale + yOffset - boxHeight / 2,
    --     boxWidth,
    --     boxHeight
    -- )

    -- love.graphics.print("Bulletscount: " .. #bullets , 10, 10)

    love.graphics.setColor(1, 1, 1)
end

-- MODULE method for updating all bullets
function bullet.updateAll(dt)
    for i = #bullets, 1, -1 do
        local bulletObj = bullets[i]
        bulletObj:update(dt)

        -- Add collision check
        if player and checkBulletPlayerCollision(bulletObj, player) then
            bulletObj.active = false
        end

        if not bulletObj.active then
            table.remove(bullets, i)
        end
    end
end

-- MODULE method for drawing all bullets
function bullet.drawAll(tileScale)
    for _, bulletObj in ipairs(bullets) do
        bulletObj:draw(tileScale)
    end
end

-- Factory function to create new bullets
function bullet.createBullet(x, y, angle, speed, color, radius)
    return bullet.new(x, y, angle, speed, color, radius)
end

-- Clear all bullets
function bullet.clear()
    bullets = {}
end

-- Get the bullets table
function bullet.getBullets()
    return bullets
end

return bullet
