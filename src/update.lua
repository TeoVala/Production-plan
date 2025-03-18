player = require("src.units.player")

function update(dt)
    -- Update all animations
    tileset:update(dt)

    player.update(dt)
end