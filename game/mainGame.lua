--[[ recreacion de seaquest ]]
local game = {}
local wf = require("lib/windfield")
local anim8 = require('lib/anim8/anim8')
local sti = require('lib/sti')

function game.load()
    --[[ configuraciones basicas de la ventana y uso de fisicas ]]
    love.window.setTitle("Seaquest: Definitive Edition")
    world = wf.newWorld(0, 0, true)
    world:setQueryDebugDrawing(true)
    love.graphics.setDefaultFilter("nearest", "nearest")
    --[[fuente tipo pixel art]]
    pixelFont = love.graphics.newFont("assets/fonts/PressStart2P-Regular.ttf", 16)

    --[[ mapa ]]
    
    gameMap = sti('assets/sprites/map/background.lua')

    oleada = 1

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
    game.player = {
        x = 400,
        y = 96,
        speed = 200,
        direccionDisparo = 1,
        vivo = true,
        vidas = 3,
        oxygen = 100,
        maxOxygen = 100
    }
    player = game.player
    player.tiempoMuerte = 0
    player.tiempoReaparicion = 1.1
    
    --[[sprite del jugador]]
    player.image = love.graphics.newImage("assets/sprites/player/jugador (1).png")
    local g = anim8.newGrid(64, 64, player.image:getWidth(), player.image:getHeight())
    player.anim = anim8.newAnimation(g(1, '1-5'), 0.1)
    player.collider = world:newCircleCollider(player.x, player.y, 18)
    player.collider:setFixedRotation(true)
    frameQuad = g(1, 1)[1] --[[para mostrar las vidas del jugador  pero solo el primer frame del sprite]]

    --[[sprite de muerte del jugador]]
    player.imageDead= love.graphics.newImage("assets/sprites/player/DeadPlayer.png")
    local Gdead=anim8.newGrid(64, 64,player.imageDead:getWidth(), player.imageDead:getHeight())
    player.animDead = anim8.newAnimation(Gdead(1, '1-12'), 0.1)

    --[[sprites del submarino enemigo]]
    submarinoImage = love.graphics.newImage("assets/sprites/enemy/submarinoEnemigo.png")
    submarinoGrid = anim8.newGrid(64, 64, submarinoImage:getWidth(), submarinoImage:getHeight())
    submarinoAnim = anim8.newAnimation(submarinoGrid(1,'1-5'), 0.1)

    --[[sprites de tiburon enemigo]]
    TiburonImage = love.graphics.newImage("assets/sprites/enemy/tiburones.png")
    TiburonGrid = anim8.newGrid(64, 64, TiburonImage:getWidth(), TiburonImage:getHeight())
    TiburonAnim = anim8.newAnimation(TiburonGrid(1,'1-5'), 0.1)
    
    --[[sprites de los buzos]]
    buzoImage=love.graphics.newImage("assets/sprites/buzos/buzos.png")
    buzosGrid=anim8.newGrid(64, 64,buzoImage:getWidth(), buzoImage:getHeight())
    buzosAnim=anim8.newAnimation(buzosGrid(1,'1-6'), 0.1)

    --[[buzos]]
    buzoRecogido = nil
    puedeRecogerBuzo = true
    buzoRecogido = {}
    contadorBuzos = 0
    maxBuzos = 6

    -- Creación de los bordes de la pantalla
    wall_top = world:newRectangleCollider(0, 0, love.graphics.getWidth(), 75)
    wall_bottom = world:newRectangleCollider(0, love.graphics.getHeight()-95, love.graphics.getWidth(), 1)
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
        {lado = "derecha", cantidad = 3, espacio = 50, tipo = "buzo",delay=true,orientacion = "vertical"},
        {lado = "ambos",delay=true,orientacion='vertical',movimiento="lineal",enemigos={{tipo = "submarino", cantidad = 2, espacio = 40},{tipo = "tiburon", cantidad = 3, espacio = 40}}},
    }
    indicePatronActual = 1
        desbloqueosRealizados = {} 
    --[[
    añadir patrones amedida que va aumentando de puntos
    ]]
    desbloqueosPorPuntuacion = {
    
    [50] = {
        {lado = "izquierda", cantidad = 5, espacio = 40, tipo = "submarino", delay=true, orientacion = "horizontal", movimiento = "lineal"}
    },
    [100] = {
        {lado = "derecha", cantidad = 6, espacio = 50, tipo = "tiburon", delay=true, orientacion = "vertical", movimiento = "zigzag"}
    },
    
    }
    --[[llevar el control de patrones desbloquados y evitar repetir desbloqueos]]
    desbloqueosRealizados = {}

    --[[ buzos: variales globales ]]
    buzos = {}
    tiempoBuzo = 0
    buzoCooldown = 0.1
    buzoSpeed = 30
    maxBuzosSpawn = 4
    buzoSize = 20

    entregandoBuzos = false
    animacionRescateTimer = 0
    mostrarAnimacionRescate = false

    tankImage = love.graphics.newImage("assets/sprites/oxygen/oxygentank.png")

    --[[sountrack y efectos]]
    MusicDisparoPlayer=love.audio.newSource("assets/sounds/disparo","static")
    MusicDisparoEnemy=love.audio.newSource("assets/sounds/disparo3","static")
    MusicDeadEnemy=love.audio.newSource("assets/sounds/deadenemy2","static")
    MusicDeadPlayer=love.audio.newSource("assets/sounds/explosionplayer","static")
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
    player.y = 96
    player.collider:setPosition(player.x, player.y)

    --[[resetear oxigeno]]
    player.oxygen = 100

    -- [[Resetear oleadas o patrón de aparición]]
    indicePatronActual = 1
    tiempoEnemigo = 0
    tiempoEntrePatrones = 8 
    tiempoDesdeUltimoPatron = 0

    disparoCooldown = 1
    tiempoDesdeUltimoDisparo = disparoCooldown

        --[[reinicio de patrones al morir]]
    patrones = {
    {lado = "ambos", delay = true, orientacion = 'vertical', movimiento = "lineal", enemigos = {
        {tipo = "submarino", cantidad = 2, espacio = 40},
        {tipo = "tiburon", cantidad = 3, espacio = 40}
    }}
}
    indicePatronActual = 1
    desbloqueosRealizados = {} -- reiniciar desbloqueos
end

function reiniciarOleadaEnemigos()
    -- Generar nueva oleada
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
    puntuacion = puntuacion

    -- [[Resetear jugador al centro arriba]]
    player.x = 400
    player.y = 96
    player.collider:setPosition(player.x, player.y)

    --[[resetear oxigeno]]
    player.oxygen = 100

    -- [[Resetear oleadas o patrón de aparición]]
    indicePatronActual = 1
    tiempoEnemigo = 0
    tiempoEntrePatrones = 8 
    tiempoDesdeUltimoPatron = 0

    disparoCooldown = 1
    tiempoDesdeUltimoDisparo = disparoCooldown

    --[[reinicio de patrones al morir]]
    patrones = {
        {lado = "ambos", delay = true, orientacion = 'vertical', movimiento = "lineal", enemigos = {
            {tipo = "submarino", cantidad = 2, espacio = 40},
            {tipo = "tiburon", cantidad = 3, espacio = 40}
        }}
    }
    indicePatronActual = 1

    oleada = oleada + 1
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
        body = world:newRectangleCollider(x, y, buzoSize, buzoSize),
        temporizador = 0,
        image = buzoImage,
        anim = buzosAnim:clone()
    }

    buzo.body:setCollisionClass("buzo")
    buzo.body:setObject(buzo)

    buzo.body:setPreSolve(function(collider_1, collider_2, contact)
        local buzoCollider = nil
        local otherCollider = nil

        if collider_1.collision_class == "buzo" then
            buzoCollider = collider_1
            otherCollider = collider_2
        elseif collider_2.collision_class == "buzo" then
            buzoCollider = collider_2
            otherCollider = collider_1
        end

        if buzoCollider and otherCollider and otherCollider.collision_class == "Enemy" then
            contact:setEnabled(false)

            -- Destruir el buzo si toca a un enemigo
            local buzoObj = buzoCollider:getObject()
            if buzoObj and buzoObj.body and not buzoObj.body:isDestroyed() then
                buzoObj.body:destroy()

                -- Remover de la lista de buzos
                for i = #buzos, 1, -1 do
                    if buzos[i] == buzoObj then
                        table.remove(buzos, i)
                        break
                    end
                end
            end
        end
    end)

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
                    image=TiburonImage,
                    anim= TiburonAnim:clone()
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
                enemigo.image =TiburonImage
                enemigo.anim = TiburonAnim:clone()
                
                --[[ 
                si el enemigo es un submarino, este debe disparar
                aqui se inicializan las variables del tiempo para disparos
                ]]
                if enemigo.tipo == "submarino" then
                    enemigo.tiempoDesdeUltimoDisparo = 0
                    enemigo.tiempoEntreDisparos = 2
                    enemigo.image = submarinoImage
                    enemigo.anim = submarinoAnim:clone()
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
            buzo.image=buzoImage
            buzo.anim= buzosAnim:clone()
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


function matarJugador()
    if player.vivo then
        player.vivo = false
        player.tiempoMuerte = 0
        player.oxygen=100
        MusicDeadPlayer:stop()
        MusicDeadPlayer:play()
    end
end

function game.update(dt)
    world:update(dt)

    --[[actualizacion de sprites]]
    player.anim:update(dt)

    --[[easter egg]]
    if puntuacion == 50000 then
        MusicDeadEnemy=love.audio.newSource("assets/sounds/aester egg.mp3","static")
        end
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
            enemigo.image =TiburonImage
            enemigo.anim = TiburonAnim:clone()

            if enemigo.tipo == "submarino" then
                enemigo.tiempoDesdeUltimoDisparo = 0
                enemigo.tiempoEntreDisparos = 2
                enemigo.image = submarinoImage
                enemigo.anim = submarinoAnim:clone()
            end
            --[[se agrega a la lista de tiburones(la activa de los enemigos) y se remueve
            de los enemigos pendientes
            ]]
            table.insert(tiburones, enemigo)
            table.remove(enemigosDelay, i)
        end
    end

        if not player.vivo then
        player.animDead:update(dt)
        player.tiempoMuerte = player.tiempoMuerte + dt

        if player.tiempoMuerte >= player.tiempoReaparicion then
            -- [[Reaparecer jugador]]
            player.vivo = true
            player.vidas = player.vidas - 1
            reset()
        end

        return -- [[Salir del update para evitar que el jugador haga otras acciones]]
    end

    --[[ variables para manejar el disparo del jugador ]]
    tiempoDesdeUltimoDisparo = tiempoDesdeUltimoDisparo + dt
    tiempoDesdeUltimoPatron = tiempoDesdeUltimoPatron + dt

    --[[ instancia del disparo del jugador ]]
    if love.keyboard.isDown("space") and tiempoDesdeUltimoDisparo >= disparoCooldown then
        local offsetX = player.direccionDisparo * 20
        SpawnDisparo(player.x + offsetX, player.y, player.direccionDisparo, 'DisparoJugador')
        MusicDisparoPlayer:stop()
        MusicDisparoPlayer:play()
        tiempoDesdeUltimoDisparo = 0
    end

    if tiempoDesdeUltimoPatron >= tiempoEntrePatrones then
        local patron = patrones[indicePatronActual]
    
        if patron.lado == "ambos" then
        -- [[Crear dos clones del patrón, uno por cada lado y se le asigna ese lado]]
        local patronIzq = cloneP(patron)
        patronIzq.lado = "izquierda"
        local patronDer = cloneP(patron)
        patronDer.lado = "derecha"
        --[[se invoca al Spawn de los enemigos 2 para los dos lados]]
        SpawnTiburonesPatron(patronIzq)
        SpawnTiburonesPatron(patronDer)
    else
        SpawnTiburonesPatron(patron)--[[en caso de que sea solamente izquierdo o derecho]]
        SpawnBuzosPatron(patron)
    end

        indicePatronActual = indicePatronActual % #patrones + 1
        tiempoDesdeUltimoPatron = 0
    end

    for i = #tiburones, 1, -1 do
        local enemy = tiburones[i]
        local x, y = enemy.body:getPosition()
        actualizarMovimientoEnemigo(enemy, dt)
        
        if enemy.tipo == "tiburon" and enemy.anim then
        enemy.anim:update(dt)
        end

        if enemy.tipo == "submarino" then
            enemy.tiempoDesdeUltimoDisparo = enemy.tiempoDesdeUltimoDisparo + dt
            if enemy.tiempoDesdeUltimoDisparo >= enemy.tiempoEntreDisparos then
                local dir = enemy.lado == "izquierda" and 1 or -1
                SpawnDisparo(x, y, dir, 'DisparoEnemy')
                MusicDisparoEnemy:stop()
                MusicDisparoEnemy:play()
                enemy.tiempoDesdeUltimoDisparo = 0
            end
        end
        
        if enemy.tipo == "submarino" and enemy.anim then
        enemy.anim:update(dt)
        end

        if (enemy.lado == "izquierda" and x > love.graphics.getWidth() + 50) or
           (enemy.lado == "derecha" and x < -50) then
            enemy.body:destroy()
            table.remove(tiburones, i)
        end
    end

    --[[ dibujo de los buzos ]]
    for i = #buzos, 1, -1 do
        local buzo = buzos[i]
        buzo.anim:update(dt)
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
                        MusicDeadEnemy:stop()
                        MusicDeadEnemy:play()
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

        matarJugador()
        if player.vidas <= 0 then
            love.event.quit()
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

        matarJugador()
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
        
            -- Detectar enemigos cercanos para huir
            local enemigosCerca = world:queryRectangleArea(bx, by, bw + 10, bh + 10, {'Enemy'})

            local velocidad = 60
            if #enemigosCerca > 0 then
                local enemigo = enemigosCerca[1]
                local ex, _ = enemigo:getPosition()
                local dir = bx < ex and -1 or 1
                buzo.body:setX(bx + dir * velocidad * 2 * dt)
                -- Actualizar dirección según huida
                buzo.direccion = dir == 1 and "derecha" or "izquierda"
            else
                -- Movimiento lateral simple y cambio de dirección en bordes
                local dir = buzo.direccion == "derecha" and 1 or -1
                local nuevoX = bx + dir * velocidad * dt

                if nuevoX < 40 then
                    buzo.direccion = "derecha"
                    nuevoX = 40
                elseif nuevoX > love.graphics.getWidth() - 40 then
                    buzo.direccion = "izquierda"
                    nuevoX = love.graphics.getWidth() - 40
                end

                buzo.body:setX(nuevoX)
            end

            -- Destruir buzo si toca enemigos o sale de pantalla
            --[[ local enemigosTocando = world:queryRectangleArea(bx, by, bw, bh, {'Enemy'})
            if #enemigosTocando > 0 or bx < -50 or bx > love.graphics.getWidth() + 50 then
                buzo.body:destroy()
                table.remove(buzos, i)
            end ]]

    
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

    -- entregar buzos a la superficie
    if contadorBuzos > 0 then
        local _, jugadorY = player.collider:getPosition()
        
        if jugadorY <= 100 then
            -- Al comenzar la entrega
            if not entregandoBuzos then
                entregandoBuzos = true
                vidasAntesEntrega = vidas
            end
    
            contadorBuzos = contadorBuzos - 1
            table.remove(buzoRecogido)  -- Asegúrate de usar remove para quitar un buzo
            player.oxygen = player.maxOxygen
            puntuacion = puntuacion + 200
    
            -- Si entregó todos los buzos (6)
            if contadorBuzos == 0 and #buzoRecogido == 0 then
                entregandoBuzos = false
    
                if maxBuzos == 6 then
                    -- BONUS POR RESCATE COMPLETO
                    puntuacion = puntuacion + 1000  -- Bonus extra
                    player.oxygen = player.maxOxygen
                    mostrarAnimacionRescate = true
                    animacionRescateTimer = 2 -- Duración en segundos
    
                    -- Reiniciar oleada de enemigos
                    reiniciarOleadaEnemigos()
                end
            end
        end
    end

    if mostrarAnimacionRescate then
        animacionRescateTimer = animacionRescateTimer - dt
        if animacionRescateTimer <= 0 then
            mostrarAnimacionRescate = false
        end
    end
    
    --[[ oxigeno ]] 
    if player.y > 100 then
        player.oxygen = player.oxygen - dt * 4
        if player.oxygen <= 0 then
            matarJugador()
            if player.vidas <= 0 then
                love.event.quit()
            end
        end
    end
    
end

function game.draw()

    gameMap:drawLayer(gameMap.layers["notwater"])
    gameMap:drawLayer(gameMap.layers["realwater"])

    world:draw()

    --[[ dibujo del jugador y su muerte]]
    if player.vivo then
        player.anim:draw(player.image, player.x, player.y, 0, -player.direccionDisparo, 1, 32, 32)
    else
        player.animDead:draw(player.imageDead, player.x, player.y, 0, -player.direccionDisparo, 1, 32, 32)
    end
    --[[dibujos de vida del jugador]]
    if player.vivo then
        for i = 1, player.vidas do
            local vidaX = 250 + (i - 1) * 40 
            local vidaY = 10
            love.graphics.draw(player.image,frameQuad,vidaX, vidaY, 0, -0.5, 0.5)
        end
    end

    gameMap:drawLayer(gameMap.layers["realwaterwave"])
    gameMap:drawLayer(gameMap.layers["sand"])

    --[[ dibujo de limites del mapa ]]
    --[[ love.graphics.setColor(0, 0, 1)
    love.graphics.setLineWidth(2)
    love.graphics.line(0, 100, love.graphics.getWidth(), 100)
    love.graphics.line(0, love.graphics.getHeight() - 100, love.graphics.getWidth(), love.graphics.getHeight() - 100) ]]

    --[[ dibujo de enemigos, ambos rectangulos pero se distinguen por color ]]
    for _, enemigo in ipairs(tiburones) do
        local x, y = enemigo.body:getPosition()
        if enemigo.tipo == "tiburon" then
        love.graphics.setColor(1, 1, 1) 
        enemigo.anim:draw(enemigo.image, x,y, 0, enemigo.lado == "izquierda" and -1 or 1, 1, 32,32)
        end
        if enemigo.tipo == "submarino"  then
            love.graphics.setColor(1, 1, 1) 
         enemigo.anim:draw(enemigo.image, x,y, 0, enemigo.lado == "izquierda" and -1 or 1, 1, 32,32)
        end
    end

    for _, buzo in ipairs(buzos) do
        if not buzo.recogido then
            local x, y = buzo.body:getPosition()
            love.graphics.setColor(1, 1, 1) 
            buzo.anim:draw(buzo.image,x,y,0, buzo.lado == "izquierda" and -1 or 1, 1, 32,32)
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
    love.graphics.setFont(pixelFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(puntuacion, 0, 20, love.graphics.getWidth(), "center")

    --[[ contador de buzos ]]
    for i = 1, contadorBuzos do
        local buzoX = 500 + (i - 1) * 40
        local buzoY = 10
        love.graphics.draw(buzoImage, frameQuad, buzoX, buzoY, 0, -0.5, 0.5)
    end

    --[[ barra de oxigeno ]]
    local tankX = 30
    local tankY = 1
    local scale = 3

    local tankWidth = tankImage:getWidth() * scale - 1
    local tankHeight = tankImage:getHeight() * scale - 45

    local padding = 3 * scale
    local fillWidth = tankWidth - padding * 2
    local fillHeight = tankHeight - padding * 2

    local oxygenRatio = player.oxygen / player.maxOxygen

    -- Dibujo del relleno
    love.graphics.setColor(0.8, 0.8, 1)
    love.graphics.rectangle(
        "fill",
        tankX + padding - 9,
        tankY + padding * 2,
        fillWidth * oxygenRatio,
        fillHeight
    )

    -- Dibujo de la imagen del tanque encima
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(tankImage, tankX, tankY - 12, 0, scale, scale)

    if mostrarAnimacionRescate then
        love.graphics.setColor(1, 1, 0) -- Amarillo
        love.graphics.printf("¡RESCATE COMPLETO!", 0, love.graphics.getHeight()/2 - 20, love.graphics.getWidth(), "center")
        love.graphics.setColor(1, 1, 1)
    end

end

end -- de donde es este fokin end???? [[ increible como todo el juego depende de un end]]
--[[ recordatorio: estar pendiente si vamos a modular,
porque ese end jode todo el fakin codigo ]]
--[[ al quitarlo genera un error en el update, wtf ]]

return game