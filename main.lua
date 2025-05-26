--[[ recreacion de seaquest ]]

local wf = require("lib/windfield")
local anim8 = require('lib/anim8/anim8')

function love.load()
    --[[ configuraciones basicas de la ventana y uso de fisicas ]]
    love.window.setTitle("Seaquest: Definitive Edition")
    world = wf.newWorld(0, 0, true)
    world:setQueryDebugDrawing(true)

    --[[ creacion de arreglos para enemigos, buzos, jugador,puntuacion y delay ]]
    tiburones = {}
    buzos = {}
    disparos = {}
    disparosJugador = {}
    enemigosDelay = {}
    puntuacion = 0

    --[[ variables de tiempo ]]
    tiempoEnemigo = 0
    tiempoEntrePatrones = 8 
    tiempoDesdeUltimoPatron = 0

    disparoCooldown = 0.4
    tiempoDesdeUltimoDisparo = disparoCooldown
   
    --[[ instancia de clases para hitbox de enemigos ]]
    world:addCollisionClass('Enemy')
    -- clase buzo
    world:addCollisionClass('buzo')
    world:addCollisionClass('DisparoJugador')
    world:addCollisionClass('DisparoEnemy')
    --[[ validacion: que las balas del enemigo no choquen con las del jugador y viceversa ]]
    world:collisionClassesSet('DisparoJugador', {ignores = {'DisparoJugador', 'DisparoEnemy'}})
    world:collisionClassesSet('DisparoEnemy', {ignores = {'DisparoEnemy', 'DisparoJugador'}})

    --[[ inicializacion de variables del jugador ]]
    player = {
        x = 400,
        y = 100,
        speed = 200,
        direccionDisparo = 1,
        vivo = true,
        vidas= 3
    }
    player.collider = world:newCircleCollider(player.x, player.y, 20)
    player.collider:setFixedRotation(true)

    buzoRecogido = nil
    puedeRecogerBuzo = true
    buzoRecogido = {}
    contadorBuzos = 0
    maxBuzos = 6

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
    - delay: para que los enemigos salgan al mismo tiempo
    orientacion: si aparecen en filas de manera horizontal,vertical o mixto
    enemigos: sub objeto para especificar que que tipos de enemgiso quiero en un patron
    movimientos:diferentes hechos patrones
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

    --[[ buzos ]]
    for i = #buzos, 1, -1 do
        buzos[i].body:destroy()
        table.remove(buzos, i)
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
                    orientacion = patron.orientacion,
                    movimiento = patron.movimiento or "lineal",
                    tiempo = 0,
                    baseX = x,
                    baseY = y,
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
                enemigo.movimiento = patron.movimiento or "lineal"
                enemigo.tiempo = 0
                enemigo.baseX = x
                enemigo.baseY = y
                
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

function SpawnBuzosPatron(patron)
    local anchoVentana = love.graphics.getWidth()
    local altoVentana = love.graphics.getHeight()
    local xInicio = patron.lado == "izquierda" and -40 or anchoVentana + 40
    local direccionX = patron.lado == "izquierda" and 1 or -1

    local totalAltura = 0
    if patron.orientacion == "vertical" and patron.enemigos then
        for _, grupo in ipairs(patron.enemigos) do
            totalAltura = totalAltura + grupo.cantidad * grupo.espacio + 20
        end
    elseif patron.orientacion == "vertical" then
        totalAltura = patron.cantidad * patron.espacio
    end

    local yActual = (altoVentana / 2) - (totalAltura / 2)

    for _, grupo in ipairs(patron.enemigos or {{tipo=patron.tipo, cantidad=patron.cantidad, espacio=patron.espacio}}) do
        if grupo.tipo ~= "buzo" then goto continue end
        local cantidad = grupo.cantidad
        local espacio = grupo.espacio

        if patron.orientacion == "mixto" then
            local totalDesplazamiento = (cantidad - 1) * espacio
            local xCentro = love.graphics.getWidth() / 2
            local yCentro = love.graphics.getHeight() / 2
            xInicio = xCentro - (totalDesplazamiento / 2) * direccionX
            yActual = yCentro - (totalDesplazamiento / 2)
        end

        for i = 0, cantidad - 1 do
            local x, y
            if patron.orientacion == "horizontal" then
                y = altoVentana / 2
                x = xInicio + i * espacio * direccionX
            elseif patron.orientacion == "vertical" then
                x = xInicio
                y = yActual + i * espacio
            elseif patron.orientacion == "mixto" then
                x = xInicio + i * espacio * direccionX
                y = yActual + i * espacio
            end

            local buzo = {}
            buzo.body = world:newRectangleCollider(x, y, 30, 20)
            buzo.body:setType('kinematic')
            buzo.body:setCollisionClass('buzo')
            buzo.speed = direccionX * 60
            buzo.lado = patron.lado
            buzo.recogido = false
            table.insert(buzos, buzo)
        end

        if patron.orientacion == "vertical" then
            yActual = yActual + cantidad * espacio + 20
        end
        ::continue::
    end
end

function anyBuzoInPatron(grupos)
    for _, grupo in ipairs(grupos) do
        if grupo.tipo == "buzo" then return true end
    end
    return false
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

--[[creacion de cada patron del juego]]
function actualizarMovimientoEnemigo(enemy, dt)
    local x, y = enemy.body:getPosition()
    enemy.tiempo = (enemy.tiempo or 0) + dt
    local t = enemy.tiempo
    local speed = enemy.speed --[[velocidad del jugador]]
    local dir = enemy.lado == "izquierda" and 1 or -1

    if enemy.movimiento == "lineal" then --[[movimiento lineal]]
        x = x + speed * dt
    
    --[[Movimiento vertical
    oscilatorio con una función seno (oscilación vertical de ±40 píxeles) 
    para hacer un zigzag.]]
    elseif enemy.movimiento == "zigzag" then
        x = x + speed * dt
        y = enemy.baseY + math.sin(t * 5) * 40  
    
    --[[La posición final se calcula con coordenadas polares para que describa un círculo de 
    radio 60(coseno para x, seno para y), multiplicando la dirección horizontal por dir.]]
    elseif enemy.movimiento == "circular" then
    enemy.baseX = enemy.baseX + speed * dt
    x = enemy.baseX + math.cos(t * 2) * 60 * dir
    y = enemy.baseY + math.sin(t * 2) * 60

    elseif enemy.movimiento == "sinusoidal" then
        x = x + speed * dt
        y = enemy.baseY + math.sin(x / 50) * 30
    

    --[[Movimiento vertical que alterna entre dos posiciones (+60 o -60 píxeles respecto a la base)
    con un cambio determinado por el seno
    ]]
    elseif enemy.movimiento == "subida_caida" then
    x = x + speed * dt
    y = enemy.baseY + (math.abs(math.sin(t * 3)) > 0.5 and -60 or 60)
    
    --[[La posición va describiendo una espiral que se aleja del centro.]]
    elseif enemy.movimiento == "espiral" then
    enemy.baseX = enemy.baseX + speed * dt
    local radio = 10 + t * 5  -- [[Radio crece con el tiempo para espiral abierta]]
    x = enemy.baseX + math.cos(t * 4) * radio * dir
    y = enemy.baseY + math.sin(t * 4) * radio
    
    --[[Movimiento vertical con seno cuyo valor máximo (amplitud) varía entre 0 y 40 según otra función seno]]
    elseif enemy.movimiento == "osc_amplitud" then
    x = x + speed * dt
    local amp = 20 + 20 * math.sin(t)  -- amplitud varía entre 0 y 40
    y = enemy.baseY + math.sin(t * 5) * amp

    --[[Movimiento vertical oscilatorio complejo que combina tiempo y 
    posición horizontal para crear una forma tipo "S", utilizando
    nuevamente la funcion seno
    ]]
    elseif enemy.movimiento == "s_shape" then
    x = x + speed * dt
    y = enemy.baseY + math.sin(t * 10 + x / 30) * 40
    

    --[[Se divide el movimiento en 4 fases que corresponden a los 4 lados del cuadrado.
    En cada fase se mueve una coordenada manteniendo fija la otra.]]
    elseif enemy.movimiento == "cuadrado" then
    local lado = 100  -- [[tamaño del lado del cuadrado]]
    local fase = math.floor(t % 4)
    local progreso = (t % 1) * lado
    enemy.baseX = enemy.baseX + speed * dt
    if fase == 0 then
        x = enemy.baseX + progreso * dir
        y = enemy.baseY
    elseif fase == 1 then
        x = enemy.baseX + lado * dir
        y = enemy.baseY + progreso
    elseif fase == 2 then
        x = enemy.baseX + (lado - progreso) * dir
        y = enemy.baseY + lado
    else
        x = enemy.baseX
        y = enemy.baseY + (lado - progreso)
    end

    --[[Movimiento circular que cambia su radio periódicamente, generando una forma de flor, este cambio lo genera
    las funciones seno y coseno
    ]]
    elseif enemy.movimiento == "flor" then

    local r = 50 + 30 * math.sin(6 * t)  --[[ 6 pétalos]]
    enemy.baseX = enemy.baseX + speed * dt
    x = enemy.baseX + r * math.cos(t * 2) * dir
    y = enemy.baseY + r * math.sin(t * 2)
    
    

    elseif enemy.movimiento == "reloj" then
    local radio = 50
    local pasos = math.floor(t * 1.5) % 12  -- [[12 posiciones]]
    local angulo = pasos * (math.pi * 2 / 12)
        enemy.baseX = enemy.baseX + speed * dt
    x = enemy.baseX + math.cos(angulo) * radio * dir
    y = enemy.baseY + math.sin(angulo) * radio
    
    --[[
    El enemigo se mueve entre dos puntos definidos con interpolación lineal.
    Cada ciclo dura 2 segundos.
    Cambia entre los dos puntos alternadamente.
    ]]
    elseif enemy.movimiento == "patrulla" then
    enemy.baseX = enemy.baseX + speed * dt
    local puntos = {{x = enemy.baseX, y = enemy.baseY}, {x = enemy.baseX + 200 * dir, y = enemy.baseY + 100}}
    local duracion = 2
    local indice = math.floor(t / duracion) % 2 + 1
    local sig = (indice % 2) + 1
    local progreso = (t % duracion) / duracion
    x = puntos[indice].x + (puntos[sig].x - puntos[indice].x) * progreso
    y = puntos[indice].y + (puntos[sig].y - puntos[indice].y) * progreso

    --[[Salto vertical entre dos posiciones alternadas cada 0.5 segundos.]]
    elseif enemy.movimiento == "salto_tramos" then
    x = x + speed * dt
    y = enemy.baseY + ((math.floor(t * 2) % 2 == 0) and -50 or 50)

    --[[Su velocidad vertical vy es aleatoria y se mantiene,este
    Rebota en los límites superior e inferior de los limites establecidos.]]
    elseif enemy.movimiento == "aleatorio" then
    x = x + speed * dt

    if not enemy.vy then
        enemy.vy = (math.random() * 2 - 1) * 50 
    end
    y = y + enemy.vy * dt
    -- [[Limitar el movimiento vertical dentro del limite establecido]]
    local limiteSuperior = 120
    local limiteInferior = love.graphics.getHeight() - 120
    if y < limiteSuperior then
        y = limiteSuperior
        enemy.vy = -enemy.vy -- [[rebota invertido la velocidad vertical]]
    elseif y > limiteInferior then
        y = limiteInferior
        enemy.vy = -enemy.vy
    end
end

    enemy.body:setPosition(x, y)
end


--[[funcion para clonar el patron, para que pueda salir de los dos lados]]
function cloneP(t)
    local copy = {} --[[crea una lista]]
    for k, v in pairs(t) do--[[rellena esa lista con el for](donde estan los enemigos)]]
        copy[k] = v
    end
    return copy --[[retorna esa lista]]
end


function love.update(dt)
    world:update(dt)

     player.oxigeno = player.oxigeno - dt * 2.8
    --[[agregar nuevos patrones por puntos]]
    
    for puntaje, nuevosPatrones in pairs(desbloqueosPorPuntuacion) do 
    --[[si puntuacion es menor al puntaje y no ha sido desbloqueado
    entonces inserta el nuevo patron a la lista de patrones
    ]]
    if puntuacion >= puntaje and not desbloqueosRealizados[puntaje] then
        for _, nuevoPatron in ipairs(nuevosPatrones) do
            table.insert(patrones, nuevoPatron)
        end
        desbloqueosRealizados[puntaje] = true
    end
end

    --[[manejo de aparicion de los enemigos pendientes]]
    for i = #enemigosDelay, 1, -1 do
        local e = enemigosDelay[i]
        e.tiempoRestante = e.tiempoRestante - dt
        if e.tiempoRestante <= 0 then
            local enemigo = {}
            local x, y
            if e.orientacion == "horizontal" or e.orientacion == "mixto" then
            x = e.x
            y = e.y
            else
            -- En vertical o zigzag, conserva la posición original guardada (e.x)
            -- para que no todos nazcan pegados al borde
            x = e.x
            y = e.y
end

            --[[creacion de estos enemigos]]
            enemigo.body = world:newRectangleCollider(x, y, 40, 20)
            enemigo.speed = e.lado == "izquierda" and 100 or -100
            enemigo.lado = e.lado
            enemigo.tipo = e.tipo
            enemigo.body:setCollisionClass('Enemy')
            enemigo.body:setType('kinematic')
            enemigo.movimiento = e.movimiento or "lineal"
            enemigo.tiempo = 0
            enemigo.baseX = e.x
            enemigo.baseY = e.y

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
        actualizarMovimientoEnemigo(enemy, dt)
        


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

    for i = #buzos, 1, -1 do
        local buzo = buzos[i]
        if not buzo.recogido then
            local x, y = buzo.body:getPosition()
            buzo.body:setX(x + buzo.speed * dt)
            if (buzo.lado == "izquierda" and x > love.graphics.getWidth() + 50) or
            (buzo.lado == "derecha" and x < -50) then
                buzo.body:destroy()
                table.remove(buzos, i)
            end
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
    -- Recolección de buzos
    for i = #buzos, 1, -1 do
        local buzo = buzos[i]
    
        if buzo.body and not buzo.body:isDestroyed() and contadorBuzos < maxBuzos then
            local bx, by = buzo.body:getPosition()
            local bw, bh = 30, 20 
    
            local px, py = player.collider:getPosition()
            local pw, ph = 40, 20 
    
            local paddingX = 15 
            local paddingY = 10 
    
            if math.abs(bx - px) < (bw + pw) / 2 + paddingX and
               math.abs(by - py) < (bh + ph) / 2 + paddingY then
    
                -- Recoger buzo
                table.insert(buzoRecogido, {
                    offsetX = (#buzoRecogido - 2) * 10,
                    offsetY = -30
                })
                contadorBuzos = contadorBuzos + 1
    
                buzo.body:destroy()
                table.remove(buzos, i)
    
                break 
            end
        end
    end         

    -- Entregar buzos al llegar a la superficie
    if contadorBuzos > 0 then
        local _, jugadorY = player.collider:getPosition()
        if jugadorY <= 50 then
            contadorBuzos = contadorBuzos - 1
            buzoRecogido = {}
            player.oxygen = player.maxOxygen
        end
        if (jugadorY <= 50) and contadorBuzos == maxBuzos then
            contadorBuzos = contadorBuzos - 1
            buzoRecogido = {}
            player.oxygen = player.maxOxygen
            puntuacion = puntuacion + (maxBuzos * 200) --[[ el puntaje aun no funca, funcaba antes pero cuando era de a uno ]]
        end
    end
    
    --[[ oxigeno ]] 
    if player.y > 100 then
        player.oxygen = player.oxygen - dt * 4
        if player.oxygen <= 0 then
            reset()
            player.vidas = player.vidas - 1
            if player.vidas <= 0 then
                love.event.quit()
            end
        end
    end
    
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

    for _, buzo in ipairs(buzos) do
        if not buzo.recogido then
            local x, y = buzo.body:getPosition()
            love.graphics.setColor(0, 0.7, 1)
            love.graphics.rectangle('fill', x - 15, y - 10, 30, 20)
        end
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

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Submarino recogidos: " .. contadorBuzos .. "/" .. maxBuzos, 20, 30, love.graphics.getWidth(), "center")

end
end -- de donde es este fokin end???? [[ increible como todo el juego depende de un end]]
--[[ al quitarlo genera un error en el update, wtf ]]