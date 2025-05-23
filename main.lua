--[[ recreacion de seaquest ]]

local wf = require("lib/windfield")
local anim8 = require('lib/anim8/anim8')

function love.load()
    --[[ configuraciones basicas de la ventana y uso de fisicas ]]
    love.window.setTitle("Seaquest: Definitive Edition")
    world = wf.newWorld(0, 0, true)
    world:setQueryDebugDrawing(true)

    --[[ creacion de arreglos para enemigos, jugador,puntuacion y delay ]]
    tiburones = {}
    disparos = {}
    disparosJugador = {}
    enemigosDelay = {}
    puntuacion = 0

    --[[ variables de tiempo ]]
    tiempoEnemigo = 0
    tiempoEntrePatrones = 8 
    tiempoDesdeUltimoPatron = 0

    disparoCooldown = 1
    tiempoDesdeUltimoDisparo = disparoCooldown
   
    --[[ instancia de clases para hitbox de enemigos ]]
    world:addCollisionClass('Enemy')
    world:addCollisionClass('DisparoJugador')
    world:addCollisionClass('DisparoEnemy')
    --[[ validacion: que las balas del enemigo no choquen con las del jugador y viceversa ]]
    world:collisionClassesSet('DisparoJugador', {ignores = {'DisparoJugador', 'DisparoEnemy'}})
    world:collisionClassesSet('DisparoEnemy', {ignores = {'DisparoEnemy', 'DisparoJugador'}})

    --[[ inicializacion de variables del jugador ]]
    player = {
        x = 200,
        y = 200,
        speed = 200,
        direccionDisparo = 1,
        vivo = true,
        vidas= 3
    }
    player.collider = world:newCircleCollider(player.x, player.y, 20)
    player.collider:setFixedRotation(true)

    -- Creación de los bordes de la pantalla
    wall_top = world:newRectangleCollider(0, 0, love.graphics.getWidth(), 1)
    wall_bottom = world:newRectangleCollider(0, love.graphics.getHeight()-1, love.graphics.getWidth(), 1)
    wall_left = world:newRectangleCollider(0, 0, 1, love.graphics.getHeight())
    wall_right = world:newRectangleCollider(love.graphics.getWidth()-1, 0, 1, love.graphics.getHeight())

    -- Hacer que los bordes sean estáticos (no se muevan)
    wall_top:setType("static")
    wall_bottom:setType("static")
    wall_left:setType("static")
    wall_right:setType("static")

    --[[ 
    variables para patrones de aparicion de enemgios:
    - lado: de donde va a salir
    - cantidad: cuantos van a salir en la oleada
    - espacio: separacion vertical entre ellos
    - tipo: que enemigo es el que va salir, para poder asignar caracteristicas segun cual sea
    -delay: para que los enemigos salgan al mismo tiempo
    orientacion: si aparecen en filas de manera horizontal,vertical o mixto
    enemigos: sub objeto para especificar que que tipos de enemgiso quiero en un patron
    ]]
    patrones = {
        {lado = "izquierda",delay=true,orientacion='vertical',enemigos={{tipo = "submarino", cantidad = 2, espacio = 60},{tipo = "tiburon", cantidad = 3, espacio = 50}}},
        {lado = "derecha", cantidad = 5, espacio = 80, tipo = "tiburon",orientacion = "mixto"},
        {lado = "derecha", cantidad = 3, espacio = 50, tipo = "submarino",delay=true,orientacion = "vertical"},
        {lado = "izquierda", cantidad = 6, espacio = 50, tipo = "submarino",orientacion = "horizontal"},
        {lado = "izquierda", cantidad = 4, espacio = 70, tipo = "tiburon",orientacion = "vertical"},
        {lado = "derecha", cantidad = 7, espacio = 50, tipo = "tiburon",orientacion = "vertical"},
    }
    indicePatronActual = 1

    --[[ buzos: variales globales ]]
    buzos = {}
    tiempoBuzo = 0
    buzoCooldown = 5
    buzoSpeed = 30
    maxBuzosSpawn = 4
    buzoSize = 20

end

--[[funcion para resetear cuando el jugador pierde una vida]]
function reset()
    -- [[Borrar enemigos]]
    for i = #tiburones, 1, -1 do
        tiburones[i].body:destroy()
        table.remove(tiburones, i)
    end

    -- [[Borrar balas]]
    for i = #disparos, 1, -1 do
        disparos[i].body:destroy()
        table.remove(disparos, i)
    end

    -- [[Resetear puntuación]]
    puntuacion = 0

    -- [[Resetear jugador al centro arriba]]
    player.x = 400
    player.y = 100
    player.collider:setPosition(player.x, player.y)

    -- [[Resetear oleadas o patrón de aparición]]
    indicePatronActual = 1
    tiempoEnemigo = 0
    tiempoEntrePatrones = 8 
    tiempoDesdeUltimoPatron = 0

    disparoCooldown = 1
    tiempoDesdeUltimoDisparo = disparoCooldown
end

--[[ manejo de aparicion de buzos ]]
function spawnBuzos(x, y)
    local buzo = {
        x = x,
        y = y,
        w = buzoSize,
        h = buzoSize,
        speed = buzoSpeed,
        state = "normal",
        direction = -1,
        collider = world:newRectangleCollider(x, y, buzoSize, buzoSize),
        temporizador = 0
    }
    buzo.collider:setCollisionClass("buzo")
    buzo.collider:setObject(buzo)
    table.insert(buzos, buzo)
end

--[[ manejo de oleadas de buzos ]]
function spawnBuzosOlas()
    local filas = {60, 90, 120, 150}
    for i = 1, maxBuzosSpawn do
        spawnBuzos(420, rows[i])
    end
end

--[[ manejo de aparicion de enemigos ]]
function SpawnTiburonesPatron(patron)
        --[[ 
    variables para obtener las dimensiones de la ventana
        su funcion aqui es delimitar hasta donde pueden aparecer los enemigos en lo alto y ancho de la misma
    ]]
    local anchoVentana = love.graphics.getWidth()
    local altoVentana = love.graphics.getHeight()
    local xInicio = patron.lado == "izquierda" and -40 or anchoVentana + 40
    local direccionX = patron.lado == "izquierda" and 1 or -1

    -- [[Calcular la altura total que ocuparán los enemigos en vertical]]
    local totalAltura = 0
    if patron.orientacion == "vertical" and patron.enemigos then
        -- [[Sumamos el espacio que ocuparán todos los enemigos en el patrón]]
        for _, grupo in ipairs(patron.enemigos) do
            totalAltura = totalAltura + grupo.cantidad * grupo.espacio + 20
        end
    elseif patron.orientacion == "vertical" and patron.cantidad and patron.espacio then
        totalAltura = patron.cantidad * patron.espacio
    end
    
    -- Posición vertical inicial para que los enemigos queden centrados
    local yActual = (altoVentana / 2) - (totalAltura / 2)
        
    for _, grupo in ipairs(patron.enemigos or {{tipo=patron.tipo, cantidad=patron.cantidad, espacio=patron.espacio}}) do
        local cantidad = grupo.cantidad
        local espacio = grupo.espacio
        -- [[Corrige el centrado para mixto]]
    if patron.orientacion == "mixto" then
        local totalDesplazamiento = (cantidad - 1) * espacio
        local xCentro = love.graphics.getWidth() / 2
        local yCentro = love.graphics.getHeight() / 2

        xInicio = xCentro - (totalDesplazamiento / 2) * direccionX
        yActual = yCentro - (totalDesplazamiento / 2)
    end
        for i = 0, grupo.cantidad - 1 do
            local x, y
            --[[Según la orientación del patrón, se calculan las coordenadas x e y de cada enemigo]]
            
            --[[
            si es Horizontal todos los enemigos 
            tienen la misma y (en el centro vertical de la ventana) y se separan en x 
            según el espacio y la dirección.
            ]]
            
            if patron.orientacion == "horizontal" then
                y = altoVentana / 2
                x = xInicio + i * grupo.espacio * direccionX

            --[[si es vertical caso conrrario al horizontal ]]
            elseif patron.orientacion == "vertical" then
                x = xInicio
                y = yActual + i * grupo.espacio
            --[[si es mixto  aumenta x e y ]]
            elseif patron.orientacion == "mixto" then
            x = xInicio + i * espacio * direccionX
            y = yActual + i * espacio
        end
            
            --[[ condicional del delay donde se agrega a la lista 
        los enemigos pendiente y el tiempo de salida que va a 
        ver entre ellos,asi como su patron y tipo  ]]

            if patron.delay then
                --[[ Guardamos para spawn futuro con delay]]
                local delay = i * 1 -- [[1 segundos entre enemigos]]
                table.insert(enemigosDelay, {
                    x = x,
                    y = y,
                    lado = patron.lado,
                    tipo = grupo.tipo,
                    tiempoRestante = delay,
                    orientacion = patron.orientacion
                })
            else
                local enemigo = {}
                --[[ control de direccion de los colliders de los enemigos ]]
                enemigo.body = world:newRectangleCollider(x, y, 40, 20)
                enemigo.speed = patron.lado == "izquierda" and 100 or -100
                
                --[[
        envio de direccion y tipo de enemigo de acuerdo al patron
        instancia de la colicion para los enemigos
        ]]
                enemigo.lado = patron.lado
                enemigo.tipo = grupo.tipo
                enemigo.body:setCollisionClass('Enemy')
                enemigo.body:setType('kinematic')
                
                --[[ 
                si el enemigo es un submarino, este debe disparar
                aqui se inicializan las variables del tiempo para disparos
                ]]
                if enemigo.tipo == "submarino" then
                    enemigo.tiempoDesdeUltimoDisparo = 0
                    enemigo.tiempoEntreDisparos = 2
                end
                --[[ se inserta en la lista]]
                table.insert(tiburones, enemigo)
            end
        end
        --[[esto es que si hay muchos grupos vertical estos sagan mas abajo]]
        if patron.orientacion == "vertical" then
            yActual = yActual + grupo.cantidad * grupo.espacio + 20
        end
    end
end

--[[ creacion de hitbox de disparo ]]
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
    --[[manejo de aparicion de los enemigos pendientes]]
    for i = #enemigosDelay, 1, -1 do
        local e = enemigosDelay[i]
        e.tiempoRestante = e.tiempoRestante - dt
        if e.tiempoRestante <= 0 then
            local enemigo = {}
            local x, y
            if e.orientacion == "horizontal" then
                x = e.x
                y = e.y
            else
                x = e.lado == "izquierda" and -40 or love.graphics.getWidth() + 40
                y = e.y
            end
            --[[creacion de estos enemigos]]
            enemigo.body = world:newRectangleCollider(x, y, 40, 20)
            enemigo.speed = e.lado == "izquierda" and 100 or -100
            enemigo.lado = e.lado
            enemigo.tipo = e.tipo
            enemigo.body:setCollisionClass('Enemy')
            enemigo.body:setType('kinematic')

            if enemigo.tipo == "submarino" then
                enemigo.tiempoDesdeUltimoDisparo = 0
                enemigo.tiempoEntreDisparos = 2
            end
            --[[se agrega a la lista de tiburones(la activa de los enemigos) y se remueve
            de los enemigos pendientes
            ]]
            table.insert(tiburones, enemigo)
            table.remove(enemigosDelay, i)
        end
    end

    --[[ variables para manejar el disparo del jugador ]]
    tiempoDesdeUltimoDisparo = tiempoDesdeUltimoDisparo + dt
    tiempoDesdeUltimoPatron = tiempoDesdeUltimoPatron + dt

    --[[ instancia del disparo del jugador ]]
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

    --[[ manejo de como los disparos del jugador pueden eliminar enemigos ]]
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

    --[[ movimiento del jugador ]]
    local vx, vy = 0, 0
    if love.keyboard.isDown("right") then vx = player.speed player.direccionDisparo = 1 end
    if love.keyboard.isDown("left") then vx = -player.speed  player.direccionDisparo = -1 end
    if love.keyboard.isDown("up") then vy = -player.speed end
    if love.keyboard.isDown("down") then vy = player.speed end

    player.collider:setLinearVelocity(vx, vy)
    player.x = player.collider:getX()
    player.y = player.collider:getY()

    --[[ creacion de colision en las balas del enemigo ]]
    if player.vivo then
        local colisionEnemigos = world:queryCircleArea(player.x, player.y, 21, {'Enemy'})
          for _, c in ipairs(colisionEnemigos) do
        -- [[Eliminar enemigo que colisionó]]
        for i = #tiburones, 1, -1 do
            if tiburones[i].body == c then
                c:destroy()
                table.remove(tiburones, i)
                break
            end
        end

        player.vidas = player.vidas - 1
        if player.vidas <= 0 then
        love.event.quit()
        else
        reset()
        end

        break --[[esto para romper el for ya que 
                solo se cuenta una colisión por frame]]
    end


        local colisionBalas = world:queryCircleArea(player.x, player.y, 21, {'DisparoEnemy'})

        for _, c in ipairs(colisionBalas) do
        -- [[Eliminar bala enemiga que colisionó]]
        for i = #disparos, 1, -1 do
            if disparos[i].body == c then
                c:destroy()
                table.remove(disparos, i)
                break
            end
        end

        player.vidas = player.vidas - 1
        reset()
        if player.vidas <= 0 then
            love.event.quit()
        end

        break -- [[mismo caso que con el enemigo]]
    end

    --[[ buzos ]]
    
end

function love.draw()
    world:draw()

    --[[ dibujo del jugador ]]
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", player.x, player.y, 20)

    --[[ dibujo de seguidilla de circulos que se crean detras del jugador para generar movimiento ]]
    love.graphics.setColor(0, 0, 1)
    love.graphics.setLineWidth(2)
    love.graphics.line(0, 100, love.graphics.getWidth(), 100)
    love.graphics.line(0, love.graphics.getHeight() - 100, love.graphics.getWidth(), love.graphics.getHeight() - 100)

    --[[ dibujo de enemigos, ambos rectangulos pero se distinguen por color ]]
    for _, enemigo in ipairs(tiburones) do
        local x, y = enemigo.body:getPosition()
        if enemigo.tipo == "tiburon" then
            love.graphics.setColor(1, 0, 0)
        elseif enemigo.tipo == "submarino" then
            love.graphics.setColor(0.5, 0, 0.5)
        end
        love.graphics.rectangle('fill', x - 20, y - 10, 40, 20)
    end

    --[[ dibujo de disparos ]]
    love.graphics.setColor(1, 1, 0)
    for _, d in ipairs(disparos) do
        local x, y = d.body:getPosition()
        love.graphics.rectangle('fill', x - 5, y - 2, 10, 5)
    end
    for _, d in ipairs(disparosJugador) do
        local x, y = d.body:getPosition()
        love.graphics.rectangle('fill', x - 3, y - 1.5, 6, 3)
    end

    --[[ dibujo de marcador de puntos ]]
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Puntos: " .. puntuacion, 0, 20, love.graphics.getWidth(), "center")
end
end -- de donde es este fokin end????
--[[ al quitarlo genera un error en el update, wtf ]]