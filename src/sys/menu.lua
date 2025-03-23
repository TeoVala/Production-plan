menu = {}
-- At the top of your main.lua or in your game state
isPaused = false

function menu.pauseGame()
    isPaused = true
end

function menu.resumeGame()
    isPaused = false
end

function menu.togglePause()
    isPaused = not isPaused
end

return menu