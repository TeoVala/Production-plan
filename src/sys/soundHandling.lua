local sound = {}

local mainTrack = nil
local isMuted = false
local volume = .04

function sound.load()
    -- Load the background music file
    mainTrack = love.audio.newSource("assets/sounds/main_theme.wav", "stream")
    mainTrack:setLooping(true) -- Make it loop continuously
    mainTrack:setVolume(volume)
end

function sound.play()
    if mainTrack and not mainTrack:isPlaying() and not isMuted then
        mainTrack:play()
    end
end

function sound.stop()
    if mainTrack and mainTrack:isPlaying() then
        mainTrack:stop()
    end
end

function sound.pause()
    if mainTrack and mainTrack:isPlaying() then
        mainTrack:pause()
    end
end

function sound.resume()
    if mainTrack and not mainTrack:isPlaying() and not isMuted then
        mainTrack:play()
    end
end

function sound.toggleMute()
    isMuted = not isMuted
    
    if isMuted then
        if mainTrack and mainTrack:isPlaying() then
            mainTrack:pause()
        end
    else
        if mainTrack and not mainTrack:isPlaying() then
            mainTrack:play()
        end
    end
    
    return isMuted
end

function sound.setVolume(newVolume)
    volume = newVolume
    if mainTrack then
        mainTrack:setVolume(volume)
    end
end

function sound.getVolume()
    return volume
end

return sound
