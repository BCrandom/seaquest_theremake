local wf = require("src/lib/windfield")
local config = require("src/game/config")

local World = {}

function World.create()
    local world = wf.newWorld(0, 0, true)
    world:setQueryDebugDrawing(true)

    world:addCollisionClass('Enemy')
    world:addCollisionClass('buzo')
    world:addCollisionClass('DisparoJugador')
    world:addCollisionClass('DisparoEnemy')
    world:addCollisionClass('PowerUp')
    world:addCollisionClass('Player')

    world:collisionClassesSet('DisparoJugador', { ignores = { 'DisparoJugador', 'DisparoEnemy' } })
    world:collisionClassesSet('DisparoEnemy', { ignores = { 'DisparoEnemy', 'DisparoJugador' } })
    world:collisionClassesSet('PowerUp', { ignores = { 'DisparoJugador', 'DisparoEnemy', 'Enemy', 'buzo' } })

    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()

    local walls = {}
    walls.top = world:newRectangleCollider(0, 0, width, config.bounds.topWall)
    walls.bottom = world:newRectangleCollider(0, height - config.bounds.bottomWallMargin, width, 1)
    walls.left = world:newRectangleCollider(0, 0, 1, height)
    walls.right = world:newRectangleCollider(width - 1, 0, 1, height)

    for _, wall in pairs(walls) do
        wall:setType("static")
    end

    return world, walls
end

return World
