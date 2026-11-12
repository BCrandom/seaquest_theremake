menu = require('src/menus/mainMenu')
gamestate = require('src/gamestates/gamestate')

function love.load()
    gamestate.load()
end

function love.update(dt)
    gamestate.update(dt)

    if gamestate.current == "menu" and menu.button and menu.button.clicked then
        gamestate.switch("play")
    end
end

function love.draw()
    gamestate.draw()
end

function love.keypressed(key)
    gamestate.keypressed(key)
end