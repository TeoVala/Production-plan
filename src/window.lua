local window = {}

-- Window dimensions
local originalWidth, originalHeight
local currentWidth, currentHeight
local scaleX, scaleY

function window.initialize()
    -- Store initial dimensions
    originalWidth, originalHeight = love.graphics.getDimensions()
    currentWidth, currentHeight = originalWidth, originalHeight
    
    -- Calculate initial scale
    window.calculateScale()
end

function window.resize(w, h)
    currentWidth, currentHeight = w, h
    window.calculateScale()
end

function window.calculateScale()
    scaleX = currentWidth / originalWidth
    scaleY = currentHeight / originalHeight
end

function window.getScaleX()
    return scaleX
end

function window.getScaleY()
    return scaleY
end

function window.getOriginalWidth()
    return originalWidth
end

function window.getOriginalHeight()
    return originalHeight
end

function window.getCurrentWidth()
    return currentWidth
end

function window.getCurrentHeight()
    return currentHeight
end

function window.drawDebugInfo()
    -- love.graphics.setColor(1, 1, 1)
    -- love.graphics.print("Window: " .. currentWidth .. "x" .. currentHeight, 10, 10)
    -- love.graphics.print("Scale: " .. string.format("%.2f", scaleX) .. "x" .. string.format("%.2f", scaleY), 10, 30)
end

return window