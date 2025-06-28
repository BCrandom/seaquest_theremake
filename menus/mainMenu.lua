local menu = {}

function menu.load()
    menu.pixelFont = love.graphics.newFont("assets/fonts/PressStart2P-Regular.ttf", 16)
    menu.pixelFontTitle = love.graphics.newFont("assets/fonts/PressStart2P-Regular.ttf", 23)

    menu.button = { 
        x = 300,
        y = 250,
        w = 200,
        h = 70,
        txt = "Presiona 'Space' para Empezar",
        clicked = false
    }

    bg = love.graphics.newImage("assets/sprites/map/background.png")
end

function menu.update(dt)
    if love.keyboard.isDown("space") then
        menu.button.txt = ">:D"
        menu.button.clicked = true
    elseif love.keyboard.isDown("escape") then
        menu.button.txt = "¡Hasta la proxima!"
        menu.button.clicked = false
        love.event.quit()
    end
end

function menu.draw()
    love.graphics.draw(bg, 0, 0)

    love.graphics.setFont(menu.pixelFontTitle)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Bugquest: Another Seaquest Remake", 0, 200, love.graphics.getWidth(), "center")

    love.graphics.setFont(menu.pixelFont)
    love.graphics.setColor(0.4, 0.4, 0.4) 
    love.graphics.rectangle("fill", menu.button.x, menu.button.y, menu.button.w, menu.button.h)

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(menu.button.txt, menu.button.x, menu.button.y + (menu.button.h / 2) - 22, menu.button.w, "center")

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Presiona 'scape' para salir", 0, 550, love.graphics.getWidth(), "center")
end

return menu