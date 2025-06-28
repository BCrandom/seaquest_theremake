local death = {}

function death.load()
    death.pixelFont = love.graphics.newFont("assets/fonts/PressStart2P-Regular.ttf", 16)
    death.pixelFontTitle = love.graphics.newFont("assets/fonts/PressStart2P-Regular.ttf", 25)
end

function death.update(dt)
end

function death.draw()
    love.graphics.setFont(menu.pixelFontTitle)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("GAME OVER", -1, love.graphics.getHeight() / 2 - 39, love.graphics.getWidth(), "center")
    love.graphics.setColor(1, 0, 0)
    love.graphics.printf("GAME OVER", 0, love.graphics.getHeight() / 2 - 40, love.graphics.getWidth(), "center")

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(menu.pixelFont)
    love.graphics.printf("Presiona Enter", 0, love.graphics.getHeight() / 2 - 10, love.graphics.getWidth(), "center")
end

return death