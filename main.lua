--[[ recreacion de seaquest ]]

function love.load()
    local anim8 = require('lib/anim8')
end

function love.update(dt)
end

function love.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Seaquest: Definitive Edition", 200, 200)
end