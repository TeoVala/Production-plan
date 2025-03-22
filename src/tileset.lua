local Tileset = {}

Tileset.__index = Tileset

local window = require("src.window") -- Require the window module to access scale factors

function Tileset.new(imagePath)
    local self = setmetatable({}, Tileset)

    -- Load the image data
    local imageData = love.image.newImageData(imagePath)

    -- Constants for the specific blue color to remove (#4700ff)
    local keyR, keyG, keyB = 0x47 / 255, 0x00 / 255, 0xFF / 255

    -- Apply color key using mapPixel (fast and efficient)
    imageData:mapPixel(function(x, y, r, g, b, a)
        -- Check if the color is close to the target blue (with a small tolerance)
        local tolerance = 0.01
        if math.abs(r - keyR) < tolerance and 
           math.abs(g - keyG) < tolerance and 
           math.abs(b - keyB) < tolerance then
            return r, g, b, 0  -- Make transparent
        else
            return r, g, b, a  -- Leave unchanged
        end
    end)

    -- Without tolerance
    -- imageData:mapPixel(function(x, y, r, g, b, a)
    --     -- Check for exact color match
    --     if r == keyR and g == keyG and b == keyB then
    --         return r, g, b, 0  -- Make transparent
    --     else
    --         return r, g, b, a  -- Leave unchanged
    --     end
    -- end)

    -- Load the tileset image
    self.image = love.graphics.newImage(imageData)

    -- Store tile dimensions
    self.tileWidth = 16
    self.tileHeight = 16
    self.baseWidth = 16
    self.baseHeight = 16

    -- Calculate tileset dimensions
    self.columns = math.floor(self.image:getWidth() / 16)
    self.rows = math.floor(self.image:getHeight() / 16)

    -- Precalculate quads for efficiency
    self.quads = {}
    for y = 0, self.rows - 1 do
        for x = 0, self.columns - 1 do
            local index = y * self.columns + x + 1
            self.quads[index] = love.graphics.newQuad(
                x * 16,
                y * 16,
                16,
                16,
                self.image:getDimensions()
            )
        end
    end

    -- Store animations
    self.animations = {}

    return self
end

-- Draw specific tile from the tileset
function Tileset:drawTile(tileIndex, x, y, scale, rotation, flipH, flipV)
    scale = scale or 1
    rotation = rotation or 0
    flipH = flipH or false
    flipV = flipV or false

    if self.quads[tileIndex] then
        -- Use the same scale factor for everything to preserve alignment
        local windowScale = math.min(window.getScaleX(), window.getScaleY())

        -- Calculate centering offsets
        local xOffset = (window.getCurrentWidth() - window.getOriginalWidth() * windowScale) / 2
        local yOffset = (window.getCurrentHeight() - window.getOriginalHeight() * windowScale) / 2

        -- Apply flipping by adjusting the scale values
        local scaleX = scale * windowScale
        local scaleY = scale * windowScale
        
        if flipH then scaleX = -scaleX end
        if flipV then scaleY = -scaleY end

         -- Set origin to the center of the tile for rotation
        local originX = rotation and self.tileWidth / 2 or 0
        local originY = rotation and self.tileWidth / 2 or 0
         
         -- Adjust origin when flipping
        if flipH then originX = self.tileWidth - originX end
        if flipV then originY = self.tileHeight - originY end

        love.graphics.draw(
            self.image,
            self.quads[tileIndex],
            x * windowScale + xOffset, -- Add X offset for centering
            y * windowScale + yOffset, -- Add Y offset for centering
            rotation,
            scaleX,
            scaleY,
            originX,
            originY
        )
    end
end

-- Get a tile index from row and column coordinates
function Tileset:getTileIndex(row, column)
    return (row - 1) * self.columns + column
end

-- Create an animation (starting from a specific tile and containing a number of frames)
function Tileset:createAnimation(name, startTileIndex, numFrames, frameTime, options)
    local frames = {}
    for i = 0, numFrames - 1 do
        table.insert(frames, startTileIndex + i)
    end

    -- Default options
    options = options or {}

    self.animations[name] = {
        frames = frames,
        frameTime = frameTime or 0.1,
        currentFrame = 1,
        timer = 0,
        playing = true,
        loop = true,
        onComplete = nil, -- Callback for when animation completes
        scale = 1,
        rotation = 0,
        flipH = options.flipH or false,    -- Initialize flip horizontal property
        flipV = options.flipV or false     -- Initialize flip vertical property
    }

    return self.animations[name] -- Return reference to the animation for further customization
end

-- Play an animation
function Tileset:playAnimation(name, restart)
    local anim = self.animations[name]
    if anim then
        anim.playing = true
        if restart then
            anim.currentFrame = 1
            anim.timer = 0
        end
    end
end

-- Pause an animation
function Tileset:pauseAnimation(name)
    local anim = self.animations[name]
    if anim then
        anim.playing = false
    end
end

-- Stop an animation (pause and reset)
function Tileset:stopAnimation(name)
    local anim = self.animations[name]
    if anim then
        anim.playing = false
        anim.currentFrame = 1
        anim.timer = 0
    end
end

-- Edit individual animation properties
function Tileset:setAnimationProperties(name, properties)
    local anim = self.animations[name]
    if anim and properties then
        for key, value in pairs(properties) do
            anim[key] = value
        end
    end
end

-- Update animations based on elapsed time
function Tileset:update(dt)
    for name, anim in pairs(self.animations) do
        if anim.playing then
            anim.timer = anim.timer + dt
            if anim.timer >= anim.frameTime then
                anim.timer = anim.timer - anim.frameTime
                anim.currentFrame = anim.currentFrame + 1

                -- Check if animation has reached its end
                if anim.currentFrame > #anim.frames then
                    if anim.loop then
                        anim.currentFrame = 1
                    else
                        anim.currentFrame = #anim.frames
                        anim.playing = false

                        -- Call completion callback if provided
                        if anim.onComplete then
                            anim.onComplete(name)
                        end
                    end
                end
            end
        end
    end
end

-- Draw the current frame of a named animation
function Tileset:drawAnimation(name, x, y, customScale, customRotation, customFlipH, customFlipV)
    local anim = self.animations[name]
    if not anim then return end

    local tileIndex = anim.frames[anim.currentFrame]
    local scale = customScale or anim.scale or 1
    local rotation = customRotation or anim.rotation or 0
    
    local flipH = customFlipH
    if flipH == nil then  -- Only use animation property if parameter wasn't provided
        flipH = anim.flipH or false
    end
    
    local flipV = customFlipV
    if flipV == nil then  -- Only use animation property if parameter wasn't provided
        flipV = anim.flipV or false
    end

    -- Pass the flip values to drawTile
    self:drawTile(tileIndex, x, y, scale, rotation, flipH, flipV)
end


-- Get scaled width of a tile
function Tileset:getScaledWidth(scale)
    scale = scale or 1
    local windowScale = math.min(window.getScaleX(), window.getScaleY())

    return self.tileWidth * scale * windowScale
end

-- Get original width of a tile
function Tileset:getTileWidth()
    return self.tileWidth
end

-- Get scaled width of a tile
function Tileset:getScaledHeight(scale)
    scale = scale or 1
    local windowScale = math.min(window.getScaleX(), window.getScaleY())

    return self.tileHeight * scale * windowScale
end

-- Get original height of a tile
function Tileset:getTileHeight()
    return self.tileHeight
end

-- Get the number of columns in the tileset
function Tileset:getColumns()
    return self.columns
end

-- Get the number of rows in the tileset
function Tileset:getRows()
    return self.rows
end

-- Get the total number of tiles in the tileset
function Tileset:getTileCount()
    return self.columns * self.rows
end

-- Check if an animation exists
function Tileset:animationExists(name)
    return self.animations[name] ~= nil
end

-- Get a list of all animation names
function Tileset:getAnimationNames()
    local names = {}
    for name, _ in pairs(self.animations) do
        table.insert(names, name)
    end
    return names
end

-- Clear all animations
function Tileset:clearAnimations()
    self.animations = {}
end

return Tileset
