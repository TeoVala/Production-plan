-- General shit
tileScale = 1.65

function love.conf(t)
    t.title = "Production plan"
    t.window.width = 1280
    t.window.height = 720
    t.window.resizable = true
    t.window.minwidth = 640
    t.window.minheight = 360

    t.modules.joystick = false
    t.modules.physics = false
    
end