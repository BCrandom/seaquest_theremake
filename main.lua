--[[ recreacion de seaquest ]]
local wf = require "libs/windfield"
    local anim8 = require('lib/anim8')
function love.load()
    love.window.setTitle("Seaquest: Definitive Edition")
    world = wf.newWorld(0, 0, true)
    world:setQueryDebugDrawing(true)

    tiburones = {}
    tiempoEnemigo = 0
    tiempoEntrePatrones = 5 
    tiempoDesdeUltimoPatron = 0

    world:addCollisionClass('Player')
    world:addCollisionClass('Enemy')


    patrones = {
        {lado = "izquierda", cantidad = 4, espacio = 60},
        {lado = "derecha", cantidad = 5, espacio = 80},
        {lado = "derecha", cantidad = 3, espacio = 25},
        {lado = "izquierda", cantidad = 6, espacio = 50},
    }
    indicePatronActual = 1
end


function SpawnTiburonesPatron(patron)
    local anchoVentana = love.graphics.getWidth()
    local altoVentana = love.graphics.getHeight()

    local espacioSuperior = 100
    local espacioInferior = 100

    local alturaArea = altoVentana - espacioSuperior - espacioInferior


    local totalAltura = (patron.cantidad - 1) * patron.espacio

    local yInicio = espacioSuperior + (alturaArea - totalAltura) / 2

    for i = 0, patron.cantidad - 1 do
        local y = yInicio + i * patron.espacio
        local enemigo = {}

        if patron.lado == "izquierda" then
            enemigo.body = world:newRectangleCollider(-40, y, 40, 20)
            enemigo.speed = 100
        else 
            enemigo.body = world:newRectangleCollider(anchoVentana + 40, y, 40, 20)
            enemigo.speed = -100
        end

        enemigo.lado = patron.lado
        enemigo.body:setCollisionClass('Enemy')
        enemigo.body:setType('kinematic')
        table.insert(tiburones, enemigo)
    end
end

function love.update(dt)
    world:update(dt)

    tiempoDesdeUltimoPatron = tiempoDesdeUltimoPatron + dt

    if tiempoDesdeUltimoPatron >= tiempoEntrePatrones then
        local patron = patrones[indicePatronActual]
        SpawnTiburonesPatron(patron)

        indicePatronActual = indicePatronActual + 1
        if indicePatronActual > #patrones then
            indicePatronActual = 1 
        end
        tiempoDesdeUltimoPatron = 0
    end

    for i = #tiburones, 1, -1 do
        local enemy = tiburones[i]
        local x, y = enemy.body:getPosition()
        enemy.body:setX(x + enemy.speed * dt)

        if (enemy.lado == "izquierda" and x > love.graphics.getWidth() + 50) or
           (enemy.lado == "derecha" and x < -50) then
            enemy.body:destroy()
            table.remove(tiburones, i)
        end
    end
end

function love.draw()
    world:draw()

    local altoVentana = love.graphics.getHeight()
    local ySuperior = 100
    local yInferior = altoVentana - 100

    love.graphics.setColor(0, 0, 1)
    love.graphics.setLineWidth(2)
    love.graphics.line(0, ySuperior, love.graphics.getWidth(), ySuperior)
    love.graphics.line(0, yInferior, love.graphics.getWidth(), yInferior)


    for _, enemigo in ipairs(tiburones) do
        local x, y = enemigo.body:getPosition()
        love.graphics.setColor(1, 0, 0) 
        love.graphics.rectangle('fill', x - 20, y - 10, 40, 20)
    end

    love.graphics.setColor(1, 1, 1)
end