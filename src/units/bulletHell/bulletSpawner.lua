local window = require('src.window')
local bullet = require("src.units.bulletHell.bullet")

local bulletSpawner = {}
bulletSpawner.__index = bulletSpawner

---- Spawner Parameters
-- Increase spacing between spawners (larger value = more spread out)
local spacing = 80

-- Reduce the density by placing only on selected points
local density = 0.50 -- Only place 50% of the possible spawners

-- Ensure we have at least a minimum number of spawners
local minimumSpawners = 8

local maxBulletCount = 20

local bulletSpeed = 80

-- Add this to the top of your file or in your love.load() function
math.randomseed(os.time())
--  Burn a few random numbers as the first few can be less random
for i = 1, 10 do
    math.random()
end

local spawners = {}

-- Define possible spawn intervals (in seconds)
local spawnIntervalOptions = {
    2.75, 3.0, 3.25, 3.5, 4.0, 4.5, 4.75, 4.80, 4.80, 4.80, 4.80, 5.0, 5.5, 5.8, 6.0, 6.5, 7.8, 7.5, 7.8, 7.5, 7.8, 7.5, 7.8, 7.5, 7.8, 7.5,
}

-- Patterns
-- Available pattern names for random selection
local patternNames = { "straightShot", "directionalShot", "circlePattern", "spiralPattern", "sineWavePattern" }
-- Store predefined patterns
local bulletPatterns = {
    -- Original straight shot pattern that aims at player
    straightShot = function(x, y, targetX, targetY)
        local angle = math.atan2(targetY - y, targetX - x)
        return bullet.createBullet(x, y, angle, bulletSpeed, { 1, 0, 0 })
    end,

    -- Position-based directional shot (straight in cardinal direction)
    directionalShot = function(x, y, targetX, targetY)
        local mapWidth = window.getOriginalWidth()
        local mapHeight = window.getOriginalHeight()
        local angle

        -- Determine which edge the spawner is on
        if y < 0 then             -- Top edge
            angle = math.pi / 2   -- Down
        elseif y > mapHeight then -- Bottom edge
            angle = -math.pi / 2  -- Up
        elseif x < 0 then         -- Left edge
            angle = 0             -- Right
        else                      -- Right edge
            angle = math.pi       -- Left
        end

        return bullet.createBullet(x, y, angle, bulletSpeed, { 0, 0.7, 1 })
    end,

    -- Circular pattern
    circlePattern = function(x, y, targetX, targetY)
        local bullets = {}
        local count = 8 -- Number of bullets in the circle
        local speed = bulletSpeed

        for i = 1, count do
            local angle = (i / count) * math.pi * 2
            table.insert(bullets, bullet.createBullet(
                x, y, angle, speed, { 1, 0.5, 0.2 }
            ))
        end

        return bullets
    end,

    -- Spiral pattern
    spiralPattern = function(x, y, targetX, targetY)
        local bullets = {}
        local count = 5 -- Number of bullets in the spiral
        local speed = bulletSpeed
        local rotationSpeed = 0.3

        -- Get a persistent angle for this spawner to create the spiral effect
        local spawnerTime = love.timer.getTime() % 100 -- Prevent massive numbers
        local baseAngle = spawnerTime * 2

        for i = 1, count do
            local angle = baseAngle + (i * rotationSpeed)
            table.insert(bullets, bullet.createBullet(
                x, y, angle, speed, { 0.3, 0.8, 1 }
            ))
        end

        return bullets
    end,

    -- Sine wave pattern with randomization
    sineWavePattern = function(x, y, targetX, targetY)
        local bullets = {}

        -- Random parameters (change each time the pattern is fired)
        local bulletCount = math.random(2, 4)
        local amplitude = math.random(30, 50)
        local frequency = 0.2 + math.random() * 0.15
        local speed = bulletSpeed * (0.85 + math.random() * 0.3)
        local spacing = 25 + math.random() * 15
        local angleSpread = math.pi / (4 + math.random() * 4) -- 25-45 degree spread

        -- Colors
        local colorOptions = {
            { 0.4, 0.8, 1 }, -- Light blue
            { 0.8, 0.4, 1 }, -- Purple
            { 0.2, 0.9, 0.7 }, -- Teal
        }
        local color = colorOptions[math.random(#colorOptions)]

        -- Calculate base angle toward player
        local baseAngle = math.atan2(targetY - y, targetX - x)

        for i = 1, bulletCount do
            -- Calculate position with spacing
            local bulletX = x + (i - 1) * spacing * math.cos(baseAngle)
            local bulletY = y + (i - 1) * spacing * math.sin(baseAngle)

            -- Calculate individual bullet angle with spread
            local bulletAngle = baseAngle
            if bulletCount > 1 then
                bulletAngle = baseAngle - (angleSpread / 2) + (angleSpread * (i - 1) / (bulletCount - 1))
            end

            -- Calculate perpendicular offset using sine wave
            local perpAngle = baseAngle + math.pi / 2
            local offsetAmount = math.sin((i - 1) * frequency) * amplitude

            -- Apply sine wave offset
            bulletX = bulletX + math.cos(perpAngle) * offsetAmount
            bulletY = bulletY + math.sin(perpAngle) * offsetAmount

            -- Create the bullet with its unique angle
            table.insert(bullets, bullet.createBullet(
                bulletX, bulletY, bulletAngle, speed, color
            ))
        end

        return bullets
    end


}

function bulletSpawner.new(x, y, patternName)
    local self = setmetatable({}, bulletSpawner)
    self.x = x
    self.y = y
    self.patternName = patternName or "straightShot"
    self.active = true

    -- If no pattern specified, pick a random one
    if not patternName then
        patternName = patternNames[math.random(#patternNames)]
    end

    self.patternName = patternName
    self.active = true

    -- Set a random spawn interval for this spawner
    local randomIndex = math.random(#spawnIntervalOptions)
    self.spawnInterval = spawnIntervalOptions[randomIndex]

    -- Initialize timer with a full interval to stagger initial shots
    self.timer = self.spawnInterval

    table.insert(spawners, self)
    return self
end

-- Module method for setting up all spawners
function bulletSpawner.setupSpawners()
    -- Clear existing spawners
    spawners = {}

    local mapWidth = window.getOriginalWidth()
    local mapHeight = window.getOriginalHeight()

    -- Top edge - only place spawners on every other position
    local topCount = math.floor(mapWidth / spacing)
    for i = 1, topCount do
        -- Use the random check to determine if we place a spawner
        if math.random() < density then
            local x = (i - 0.5) * (mapWidth / topCount)
            bulletSpawner.new(x, -10) -- No pattern specified, will pick random one
        end
    end

    -- Bottom edge
    local bottomCount = math.floor(mapWidth / spacing)
    for i = 1, bottomCount do
        if math.random() < density then
            local x = (i - 0.5) * (mapWidth / bottomCount)
            bulletSpawner.new(x, mapHeight + 10)
        end
    end

    -- Left edge
    local leftCount = math.floor(mapHeight / spacing)
    for i = 1, leftCount do
        if math.random() < density then
            local y = (i - 0.5) * (mapHeight / leftCount)
            bulletSpawner.new(-10, y)
        end
    end

    -- Right edge
    local rightCount = math.floor(mapHeight / spacing)
    for i = 1, rightCount do
        if math.random() < density then
            local y = (i - 0.5) * (mapHeight / rightCount)
            bulletSpawner.new(mapWidth + 10, y)
        end
    end

    -- Ensure we have at least a minimum number of spawners
    if #spawners < minimumSpawners then
        -- Add more random spawners until we reach the minimum
        while #spawners < minimumSpawners do
            -- Select a random edge (1=top, 2=bottom, 3=left, 4=right)
            local edge = math.random(1, 4)
            local x, y

            if edge == 1 then -- Top
                x = math.random() * mapWidth
                y = -10
            elseif edge == 2 then -- Bottom
                x = math.random() * mapWidth
                y = mapHeight + 10
            elseif edge == 3 then -- Left
                x = -10
                y = math.random() * mapHeight
            else -- Right
                x = mapWidth + 10
                y = math.random() * mapHeight
            end

            bulletSpawner.new(x, y)
        end
    end
end

-- Instance method for spawning a bullet from a single spawner
function bulletSpawner:spawnBullet(playerX, playerY)
    if #bullets < maxBulletCount then
        -- 10% chance to change pattern
        if math.random() < 0.1 then
            -- Change pattern
            self.patternName = patternNames[math.random(#patternNames)]

            -- Change intervals also
            local randomIndex = math.random(#spawnIntervalOptions)
            self.spawnInterval = spawnIntervalOptions[randomIndex]
        end

        if bulletPatterns[self.patternName] then
            local result = bulletPatterns[self.patternName](self.x, self.y, playerX, playerY)

            -- Handle both single bullet and bullet table returns
            if type(result) == "table" and result.x then
                -- Single bullet
                table.insert(bullets, result)
            elseif type(result) == "table" then
                -- Multiple bullets
                for _, b in ipairs(result) do
                    table.insert(bullets, b)
                end
            end
        end
    end
    return nil
end

-- Module method for updating all spawners and bullets
function bulletSpawner.update(dt, tileScale, playerX, playerY)
    -- Update all bullets
    bullet.updateAll(dt)

    -- Update each spawner's timer and check for spawning
    for _, spawner in ipairs(spawners) do
        spawner.timer = spawner.timer - dt -- Decrement timer

        -- If timer reaches zero, spawn bullet and reset
        if spawner.timer <= 0 then
            spawner:spawnBullet(playerX, playerY)
            spawner.timer = spawner.spawnInterval -- Reset timer
        end
    end
end

-- Draw a single spawner (debug visual)
function bulletSpawner:drawSingle(tileScale)
    -- Use window scale for consistent sizing
    local windowScale = math.min(window.getScaleX(), window.getScaleY())

    -- Calculate offsets for window resizing
    local xOffset = (window.getCurrentWidth() - window.getOriginalWidth() * windowScale) / 2
    local yOffset = (window.getCurrentHeight() - window.getOriginalHeight() * windowScale) / 2

    -- Draw spawner indicator (debug visual)
    -- love.graphics.setColor(1, 0, 0, 0.7)
    -- love.graphics.circle(
    --     "fill",
    --     self.x * windowScale + xOffset,
    --     self.y * windowScale + yOffset,
    --     8 * tileScale * windowScale
    -- )

    -- -- Debug
    -- Optionally draw timer info for debugging
    -- Calculate position for timer info that's moved more toward center
    -- local screenWidth = window.getCurrentWidth()
    -- local screenHeight = window.getCurrentHeight()

    -- -- Adjust these margins to control how far from the edges
    -- local margin = 100 * windowScale

    -- -- Move x position toward center
    -- local textX = self.x * windowScale + xOffset
    -- if textX < margin then
    --     textX = margin
    -- elseif textX > screenWidth - margin then
    --     textX = screenWidth - margin
    -- end

    -- -- Move y position toward center
    -- local textY = self.y * windowScale + yOffset - 20 * windowScale
    -- if textY < margin then
    --     textY = margin
    -- elseif textY > screenHeight - margin then
    --     textY = screenHeight - margin
    -- end

    -- Draw timer info for debugging
    -- love.graphics.setColor(1, 1, 1)
    -- love.graphics.print(
    --     string.format("%.1f", self.timer),
    --     textX,
    --     textY
    -- )

    -- Debug END

    love.graphics.setColor(1, 1, 1)
end

-- Module method for drawing all spawners and bullets
function bulletSpawner.draw(tileScale)
    -- Draw all spawners (debug visuals)
    for _, spawner in ipairs(spawners) do
        bulletSpawner.drawSingle(spawner, tileScale)
    end

    -- Draw all bullets
    bullet.drawAll(tileScale)
end

-- Module method for accessing the spawners table
function bulletSpawner.getSpawners()
    return spawners
end

return bulletSpawner
