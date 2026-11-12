local config = require("src/game/config")
local Projectiles = require("src/game/projectiles")

local Enemies = {}

local function playSource(source)
    source:stop()
    source:play()
end

local function chooseEnemyAssets(G, tipo)
    if tipo == "submarino" then
        return G.oleadaJefeActiva and G.assets.bossSubmarine or G.assets.enemySubmarine
    end

    if tipo == "tiburon" then
        return G.oleadaJefeActiva and G.assets.bossShark or G.assets.enemyShark
    end
end

local function createEnemy(G, x, y, lado, tipo, movimiento, image, anim)
    local enemy = {
        lado = lado,
        tipo = tipo,
        movimiento = movimiento or "lineal",
        tiempo = 0,
        baseX = x,
        baseY = y,
        speed = lado == "izquierda" and config.enemies.speed or -config.enemies.speed
    }

    enemy.body = G.world:newRectangleCollider(x, y, config.enemies.width, config.enemies.height)
    enemy.body:setCollisionClass('Enemy')
    enemy.body:setType('kinematic')

    if image and anim then
        enemy.image = image
        enemy.anim = anim
    else
        local enemyAssets = chooseEnemyAssets(G, tipo)
        enemy.image = enemyAssets.image
        enemy.anim = enemyAssets.anim:clone()
    end

    if tipo == "submarino" then
        enemy.tiempoDesdeUltimoDisparo = 0
        enemy.tiempoEntreDisparos = G.oleadaJefeActiva and config.enemies.bossFireInterval or config.enemies.fireInterval
    end

    table.insert(G.tiburones, enemy)
    return enemy
end

local function calculateTotalHeight(patron)
    local totalAltura = 0

    if patron.orientacion == "vertical" and patron.enemigos then
        for _, grupo in ipairs(patron.enemigos) do
            totalAltura = totalAltura + grupo.cantidad * grupo.espacio + 20
        end
    elseif patron.orientacion == "vertical" and patron.cantidad and patron.espacio then
        totalAltura = patron.cantidad * patron.espacio
    end

    return totalAltura
end

function Enemies.spawnPattern(G, patron)
    local anchoVentana = love.graphics.getWidth()
    local altoVentana = love.graphics.getHeight()
    local totalAltura = calculateTotalHeight(patron)
    local yActual = (altoVentana / 2) - (totalAltura / 2)

    local grupos = patron.enemigos or {
        { tipo = patron.tipo, cantidad = patron.cantidad, espacio = patron.espacio }
    }

    for _, grupo in ipairs(grupos) do
        if grupo.tipo ~= "buzo" and grupo.tipo ~= nil then
            local cantidad = grupo.cantidad
            local espacio = grupo.espacio
            local ladoGrupo = grupo.lado or patron.lado
            local movimientoGrupo = grupo.movimiento or patron.movimiento or "lineal"

            local lados
            if ladoGrupo == "ambos" or ladoGrupo == "IgualLados" then
                lados = { "izquierda", "derecha" }
            else
                lados = { ladoGrupo }
            end

            for _, lado in ipairs(lados) do
                local direccionX = lado == "izquierda" and 1 or -1
                local xInicio = lado == "izquierda" and -40 or anchoVentana + 40
                local yInicioGrupo = yActual

                if patron.orientacion == "mixto" then
                    local totalDesplazamiento = (cantidad - 1) * espacio
                    local xCentro = anchoVentana / 2
                    local yCentro = altoVentana / 2

                    xInicio = xCentro - (totalDesplazamiento / 2) * direccionX
                    yInicioGrupo = yCentro - (totalDesplazamiento / 2)
                end

                for i = 0, cantidad - 1 do
                    local x, y

                    if patron.orientacion == "horizontal" then
                        y = altoVentana / 2
                        x = xInicio + i * espacio * direccionX
                    elseif patron.orientacion == "mixto" then
                        x = xInicio + i * espacio * direccionX
                        y = yInicioGrupo + i * espacio
                    else
                        x = xInicio
                        y = yInicioGrupo + i * espacio
                    end

                    if patron.delay then
                        local enemyAssets = chooseEnemyAssets(G, grupo.tipo)

                        table.insert(G.enemigosDelay, {
                            x = x,
                            y = y,
                            lado = lado,
                            tipo = grupo.tipo,
                            tiempoRestante = i,
                            movimiento = movimientoGrupo,
                            image = enemyAssets.image,
                            anim = enemyAssets.anim:clone()
                        })
                    else
                        createEnemy(G, x, y, lado, grupo.tipo, movimientoGrupo)
                    end
                end
            end

            if patron.orientacion == "vertical" then
                yActual = yActual + cantidad * espacio + 20
            end
        end
    end
end

function Enemies.updatePending(G, dt)
    for i = #G.enemigosDelay, 1, -1 do
        local pending = G.enemigosDelay[i]
        pending.tiempoRestante = pending.tiempoRestante - dt

        if pending.tiempoRestante <= 0 then
            createEnemy(G, pending.x, pending.y, pending.lado, pending.tipo, pending.movimiento, pending.image, pending.anim)
            table.remove(G.enemigosDelay, i)
        end
    end
end

local function updateMovement(enemy, dt)
    local x, y = enemy.body:getPosition()
    enemy.tiempo = enemy.tiempo + dt
    local t = enemy.tiempo
    local speed = enemy.speed
    local dir = enemy.lado == "izquierda" and 1 or -1
    local movimiento = enemy.movimiento

    if movimiento == "lineal" then
        x = x + speed * dt
    elseif movimiento == "zigzag" then
        x = x + speed * dt
        y = enemy.baseY + math.sin(t * 5) * 40
    elseif movimiento == "circular" then
        enemy.baseX = enemy.baseX + speed * dt
        x = enemy.baseX + math.cos(t * 2) * 60 * dir
        y = enemy.baseY + math.sin(t * 2) * 60
    elseif movimiento == "sinusoidal" then
        x = x + speed * dt
        y = enemy.baseY + math.sin(x / 50) * 30
    elseif movimiento == "subida_caida" then
        x = x + speed * dt
        y = enemy.baseY + (math.abs(math.sin(t * 3)) > 0.5 and -60 or 60)
    elseif movimiento == "espiral" then
        enemy.baseX = enemy.baseX + speed * dt
        local radio = 10 + t * 5
        x = enemy.baseX + math.cos(t * 4) * radio * dir
        y = enemy.baseY + math.sin(t * 4) * radio
    elseif movimiento == "osc_amplitud" then
        x = x + speed * dt
        local amp = 20 + 20 * math.sin(t)
        y = enemy.baseY + math.sin(t * 5) * amp
    elseif movimiento == "s_shape" then
        x = x + speed * dt
        y = enemy.baseY + math.sin(t * 10 + x / 30) * 40
    elseif movimiento == "cuadrado" then
        local lado = 100
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
    elseif movimiento == "flor" then
        local r = 50 + 30 * math.sin(6 * t)
        enemy.baseX = enemy.baseX + speed * dt
        x = enemy.baseX + r * math.cos(t * 2) * dir
        y = enemy.baseY + r * math.sin(t * 2)
    elseif movimiento == "reloj" then
        local radio = 50
        local pasos = math.floor(t * 1.5) % 12
        local angulo = pasos * (math.pi * 2 / 12)
        enemy.baseX = enemy.baseX + speed * dt
        x = enemy.baseX + math.cos(angulo) * radio * dir
        y = enemy.baseY + math.sin(angulo) * radio
    elseif movimiento == "patrulla" then
        enemy.baseX = enemy.baseX + speed * dt
        local puntos = {
            { x = enemy.baseX, y = enemy.baseY },
            { x = enemy.baseX + 200 * dir, y = enemy.baseY + 100 }
        }
        local duracion = 2
        local indice = math.floor(t / duracion) % 2 + 1
        local siguiente = (indice % 2) + 1
        local progreso = (t % duracion) / duracion

        x = puntos[indice].x + (puntos[siguiente].x - puntos[indice].x) * progreso
        y = puntos[indice].y + (puntos[siguiente].y - puntos[indice].y) * progreso
    elseif movimiento == "salto_tramos" then
        x = x + speed * dt
        y = enemy.baseY + ((math.floor(t * 2) % 2 == 0) and -50 or 50)
    elseif movimiento == "aleatorio" then
        x = x + speed * dt

        if not enemy.vy then
            enemy.vy = (math.random() * 2 - 1) * 50
        end

        y = y + enemy.vy * dt

        local limiteSuperior = 120
        local limiteInferior = love.graphics.getHeight() - 120

        if y < limiteSuperior then
            y = limiteSuperior
            enemy.vy = -enemy.vy
        elseif y > limiteInferior then
            y = limiteInferior
            enemy.vy = -enemy.vy
        end
    end

    enemy.body:setPosition(x, y)
end

function Enemies.update(G, dt)
    local width = love.graphics.getWidth()

    for i = #G.tiburones, 1, -1 do
        local enemy = G.tiburones[i]
        local x, y = enemy.body:getPosition()

        updateMovement(enemy, dt)
        enemy.anim:update(dt)

        if enemy.tipo == "submarino" then
            enemy.tiempoDesdeUltimoDisparo = enemy.tiempoDesdeUltimoDisparo + dt

            if enemy.tiempoDesdeUltimoDisparo >= enemy.tiempoEntreDisparos then
                local dir = enemy.lado == "izquierda" and 1 or -1
                Projectiles.spawnEnemy(G, x, y, dir)
                playSource(G.assets.sounds.shootEnemy)
                enemy.tiempoDesdeUltimoDisparo = 0
            end
        end

        if (enemy.lado == "izquierda" and x > width + 50) or (enemy.lado == "derecha" and x < -50) then
            enemy.body:destroy()
            table.remove(G.tiburones, i)
        end
    end
end

function Enemies.clear(G)
    for i = #G.tiburones, 1, -1 do
        G.tiburones[i].body:destroy()
        table.remove(G.tiburones, i)
    end

    for i = #G.enemigosDelay, 1, -1 do
        table.remove(G.enemigosDelay, i)
    end
end

function Enemies.draw(G)
    for _, enemy in ipairs(G.tiburones) do
        local x, y = enemy.body:getPosition()
        love.graphics.setColor(1, 1, 1)
        enemy.anim:draw(enemy.image, x, y, 0, enemy.lado == "izquierda" and -1 or 1, 1, 32, 32)
    end
end

return Enemies
