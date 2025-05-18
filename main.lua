--[[ recreacion de seaquest ]]
local wf = require("lib/windfield")
local anim8 = require('lib/anim8/anim8')

function love.load()
    love.window.setTitle("Seaquest: Definitive Edition")
    world = wf.newWorld(0, 0, true)
    world:setQueryDebugDrawing(true)

    tiburones = {}
    disparos = {}
    disparosJugador = {}
    puntuacion = 0

    tiempoEnemigo = 0
    tiempoEntrePatrones = 8 
    tiempoDesdeUltimoPatron = 0

    disparoCooldown = 1
    tiempoDesdeUltimoDisparo = disparoCooldown
    


world:addCollisionClass('Enemy')
world:addCollisionClass('DisparoJugador')
world:addCollisionClass('DisparoEnemy')

world:collisionClassesSet('DisparoJugador', {ignores = {'DisparoJugador', 'DisparoEnemy'}})
world:collisionClassesSet('DisparoEnemy', {ignores = {'DisparoEnemy', 'DisparoJugador'}})


    player = {
        x = 200,
        y = 200,
        speed = 200,
        direccionDisparo = 1,
        vivo = true
    }
    player.collider = world:newCircleCollider(player.x, player.y, 20)
    player.collider:setFixedRotation(true)

    patrones = {
        {lado = "izquierda", cantidad = 4, espacio = 60, tipo = "submarino"},
        {lado = "derecha", cantidad = 5, espacio = 80, tipo = "tiburon"},
        {lado = "derecha", cantidad = 3, espacio = 50, tipo = "submarino"},
        {lado = "izquierda", cantidad = 6, espacio = 50, tipo = "submarino"},
        {lado = "izquierda", cantidad = 4, espacio = 70, tipo = "tiburon"},
        {lado = "derecha", cantidad = 7, espacio = 60, tipo = "tiburon"},
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
        enemigo.tipo = patron.tipo
        enemigo.body:setCollisionClass('Enemy')
        enemigo.body:setType('kinematic')

        if enemigo.tipo == "submarino" then
            enemigo.tiempoDesdeUltimoDisparo = 0
            enemigo.tiempoEntreDisparos = 2 
        end

        table.insert(tiburones, enemigo)
    end
end

function SpawnDisparo(x, y, direccion, clase)
    local disparo = {}
    disparo.body = world:newRectangleCollider(x, y, 6, 3)
    disparo.body:setType('kinematic')
    disparo.body:setCollisionClass(clase)
    disparo.speed = direccion * 300 

    if clase == 'DisparoJugador' then
        table.insert(disparosJugador, disparo)
    else
        table.insert(disparos, disparo)
    end
end

function love.update(dt)
    world:update(dt)


    tiempoDesdeUltimoDisparo = tiempoDesdeUltimoDisparo + dt
    tiempoDesdeUltimoPatron = tiempoDesdeUltimoPatron + dt


    if love.keyboard.isDown("space") and tiempoDesdeUltimoDisparo >= disparoCooldown then
    local offsetX = player.direccionDisparo * 20
    SpawnDisparo(player.x + offsetX, player.y, player.direccionDisparo, 'DisparoJugador')
    tiempoDesdeUltimoDisparo = 0
end


    if tiempoDesdeUltimoPatron >= tiempoEntrePatrones then
        local patron = patrones[indicePatronActual]
        SpawnTiburonesPatron(patron)
        indicePatronActual = indicePatronActual % #patrones + 1
        tiempoDesdeUltimoPatron = 0
    end

    for i = #tiburones, 1, -1 do
        local enemy = tiburones[i]
        local x, y = enemy.body:getPosition()
        enemy.body:setX(x + enemy.speed * dt)

        if enemy.tipo == "submarino" then
            enemy.tiempoDesdeUltimoDisparo = enemy.tiempoDesdeUltimoDisparo + dt
            if enemy.tiempoDesdeUltimoDisparo >= enemy.tiempoEntreDisparos then
                local dir = enemy.lado == "izquierda" and 1 or -1
                SpawnDisparo(x, y, dir, 'DisparoEnemy')
                enemy.tiempoDesdeUltimoDisparo = 0
            end
        end

        if (enemy.lado == "izquierda" and x > love.graphics.getWidth() + 50) or
           (enemy.lado == "derecha" and x < -50) then
            enemy.body:destroy()
            table.remove(tiburones, i)
        end
    end

    for i = #disparos, 1, -1 do
        local d = disparos[i]
        local x, y = d.body:getPosition()
        d.body:setX(x + d.speed * dt)
        if x < -20 or x > love.graphics.getWidth() + 20 then
            d.body:destroy()
            table.remove(disparos, i)
        end
        local collider=world:queryRectangleArea(x-5, y-2, 10, 5, {'Enemy'})
    end

    for i = #disparosJugador, 1, -1 do
        local d = disparosJugador[i]
        local x, y = d.body:getPosition()
        d.body:setX(x + d.speed * dt)
        if x < -20 or x > love.graphics.getWidth() + 20 then
            d.body:destroy()
            table.remove(disparosJugador, i)
        else
            local colliders = world:queryRectangleArea(x-5, y-2, 10, 5, {'Enemy'})
            for _, c in ipairs(colliders) do
                for j = #tiburones, 1, -1 do
                    if tiburones[j].body == c then
                        c:destroy()
                        table.remove(tiburones, j)
                        puntuacion = puntuacion + 20
                        break
                    end
                end
                d.body:destroy()
                table.remove(disparosJugador, i)
                break
            end
        end
    end


    local vx, vy = 0, 0
    if love.keyboard.isDown("right") then vx = player.speed player.direccionDisparo = 1 end
    if love.keyboard.isDown("left") then vx = -player.speed  player.direccionDisparo = -1 end
    if love.keyboard.isDown("up") then vy = -player.speed end
    if love.keyboard.isDown("down") then vy = player.speed end

    player.collider:setLinearVelocity(vx, vy)
    player.x = player.collider:getX()
    player.y = player.collider:getY()

    if player.vivo then

    local colisionEnemigos = world:queryCircleArea(player.x, player.y, 20, {'Enemy'})
    if #colisionEnemigos > 0 then
        love.event.quit()
    end

    local colisionBalas = world:queryCircleArea(player.x, player.y, 20, {'DisparoEnemy'})
    if #colisionBalas > 0 then
        love.event.quit()
    end
end
end



function love.draw()
    world:draw()

    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", player.x, player.y, 20)

    love.graphics.setColor(0, 0, 1)
    love.graphics.setLineWidth(2)
    love.graphics.line(0, 100, love.graphics.getWidth(), 100)
    love.graphics.line(0, love.graphics.getHeight() - 100, love.graphics.getWidth(), love.graphics.getHeight() - 100)

    for _, enemigo in ipairs(tiburones) do
        local x, y = enemigo.body:getPosition()
        if enemigo.tipo == "tiburon" then
            love.graphics.setColor(1, 0, 0)
        elseif enemigo.tipo == "submarino" then
            love.graphics.setColor(0.5, 0, 0.5)
        end
        love.graphics.rectangle('fill', x - 20, y - 10, 40, 20)
    end

    love.graphics.setColor(1, 1, 0)
    for _, d in ipairs(disparos) do
        local x, y = d.body:getPosition()
        love.graphics.rectangle('fill', x - 5, y - 2, 10, 5)
    end
    for _, d in ipairs(disparosJugador) do
        local x, y = d.body:getPosition()
        love.graphics.rectangle('fill', x - 3, y - 1.5, 6, 3)
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Puntos: " .. puntuacion, 0, 20, love.graphics.getWidth(), "center")
end
