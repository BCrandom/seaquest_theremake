local Gamestate = {}

Gamestate.current = "menu"

local menu = require 'menus/mainMenu'
local game = require 'game/mainGame'
local death = require 'menus/gameOverMenu'

function Gamestate.switch(state)
    Gamestate.current = state

    -- Cargar recursos cuando cambiamos a un nuevo estado
    if state == "menu" then
        menu.load()
    elseif state == "play" then
        game.load()
    elseif state == "death" then
        death.load()
    end
end

function Gamestate.gameOver()
    return game.player.dead
end

function Gamestate.load()
    menu.load()
end

function Gamestate.update(dt)
    --[[ if Gamestate.current == "play" and Gamestate.gameOver() then
        Gamestate.switch("death")
    end ]]
    
    if Gamestate.current == "menu" then
        menu.update(dt)
    elseif Gamestate.current == "play" then
        game.update(dt)
    elseif Gamestate.current == "death" then
        death.update(dt)
    end
end

function Gamestate.draw()
    if Gamestate.current == "menu" then
        menu.draw()
    elseif Gamestate.current == "play" then
        if game and game.draw then
            game.draw()
        else
            print("Error: game.draw no está definido.")
        end
    elseif Gamestate.current == "death" then
        death.draw()
    end
end

function Gamestate.keypressed(key)
    if Gamestate.current == "death" and key == "return" then
        Gamestate.returnToMenu()
    end
end

function Gamestate.returnToMenu()
    Gamestate.switch("menu")
end

return Gamestate