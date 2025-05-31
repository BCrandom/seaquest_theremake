local menu = {}

function menu.load()
    menu.pixelFont = love.graphics.newFont("assets/fonts/PressStart2P-Regular.ttf", 16)

    menu.button = { 
        x = 300,
        y = 250,
        w = 200,
        h = 50,
        txt = "Presiona Space para empezar",
        clicked = false
    }
end

function menu.update(dt)
    if love.keyboard.isDown("space") then
        menu.button.txt = "¡Clic detectado!"
        menu.button.clicked = true
    else
        menu.button.txt = "¡Haz clic aquí!"
        --[[ menu.button.clicked = false ]]
    end
end

function menu.draw()
    love.graphics.setFont(menu.pixelFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Seaquest: Definitive Edition", 0, 200, love.graphics.getWidth(), "center")

    love.graphics.setColor(0.4, 0.4, 0.4) 
    love.graphics.rectangle("fill", menu.button.x, menu.button.y, menu.button.w, menu.button.h)

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(menu.button.txt, menu.button.x, menu.button.y + (menu.button.h / 2) - 10, menu.button.w, "center")
end

return menu