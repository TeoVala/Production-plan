local window = require('src.window')
local bullet = {}
bullet.__index = bullet

bullets = {}

function bullet.new(x, y, angle, speed, color, radius)
    local self = setmetatable({}, bullet)
    self.x = x
    self.y = y
    self.angle = angle
    self.speed = speed
    self.color = color or {1, 0, 0}
    self.radius = radius or 5
    self.active = true
    
    table.insert(bullets, self)
    return self
end

-- Instance method for updating a single bullet
function bullet:update(dt)
    -- Get window scale for consistent movement
    local windowScale = math.min(window.getScaleX(), window.getScaleY())
    
    -- Move the bullet based on angle and speed (adjusted for window scale)
    self.x = self.x + math.cos(self.angle) * self.speed * dt
    self.y = self.y + math.sin(self.angle) * self.speed * dt
    
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
    
    love.graphics.setColor(self.color)
    love.graphics.circle(
        "fill", 
        self.x * windowScale + xOffset, 
        self.y * windowScale + yOffset, 
        self.radius * tileScale * windowScale
    )
    
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.circle(
        "line", 
        self.x * windowScale + xOffset, 
        self.y * windowScale + yOffset, 
        self.radius * tileScale * windowScale
    )
    -- love.graphics.print("Bulletscount: " .. #bullets , 10, 10)
    
    love.graphics.setColor(1, 1, 1)
end

-- MODULE method for updating all bullets
function bullet.updateAll(dt)
    for i = #bullets, 1, -1 do
        local bulletObj = bullets[i]
        bulletObj:update(dt)
        
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
