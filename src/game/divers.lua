local config = require("src/game/config")
local Player = require("src/game/player")

local Divers = {}

function Divers.spawnOne(G, x, y, lado, movimiento)
    local diver = {
        speed = config.divers.speed,
        lado = lado,
        direccion = lado == "izquierda" and "derecha" or "izquierda",
        recogido = false,
        image = G.assets.diver.image,
        anim = G.assets.diver.anim:clone(),
        movimiento = movimiento or "lineal",
        baseX = x,
        baseY = y,
        tiempo = 0
    }

    diver.body = G.world:newRectangleCollider(x, y, config.divers.width, config.divers.height)
    diver.body:setType('kinematic')
    diver.body:setCollisionClass('buzo')

    table.insert(G.buzos, diver)
    return diver
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

function Divers.spawnPattern(G, patron)
    local anchoVentana = love.graphics.getWidth()
    local altoVentana = love.graphics.getHeight()
    local totalAltura = calculateTotalHeight(patron)
    local yActual = (altoVentana / 2) - (totalAltura / 2)

    local grupos = patron.enemigos or {
        {
            tipo = patron.tipo,
            cantidad = patron.cantidad,
            espacio = patron.espacio,
            lado = patron.lado,
            movimiento = patron.movimiento
        }
    }

    for _, grupo in ipairs(grupos) do
        if grupo.tipo == "buzo" then
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
                        table.insert(G.buzosDelay, {
                            x = x,
                            y = y,
                            lado = lado,
                            movimiento = movimientoGrupo,
                            tiempoRestante = i
                        })
                    else
                        Divers.spawnOne(G, x, y, lado, movimientoGrupo)
                    end
                end
            end

            if patron.orientacion == "vertical" then
                yActual = yActual + cantidad * espacio + 20
            end
        end
    end
end

function Divers.updatePending(G, dt)
    for i = #G.buzosDelay, 1, -1 do
        local pending = G.buzosDelay[i]
        pending.tiempoRestante = pending.tiempoRestante - dt

        if pending.tiempoRestante <= 0 then
            Divers.spawnOne(G, pending.x, pending.y, pending.lado, pending.movimiento)
            table.remove(G.buzosDelay, i)
        end
    end
end

local function updateMovement(diver, dt)
    local x, y = diver.body:getPosition()
    local t = (diver.tiempo or 0) + dt
    diver.tiempo = t

    local dir = diver.direccion == "derecha" and 1 or -1
    local speed = diver.speed
    local movimiento = diver.movimiento

    if movimiento == "zigzag" then
        x = x + speed * dt * dir
        y = diver.baseY + math.sin(t * 5) * 30
    elseif movimiento == "sinusoidal" then
        x = x + speed * dt * dir
        y = diver.baseY + math.sin(x / 50) * 20
    elseif movimiento == "circular" then
        diver.baseX = diver.baseX + speed * dt * dir
        x = diver.baseX + math.cos(t * 2) * 60 * dir
        y = diver.baseY + math.sin(t * 2) * 60
    elseif movimiento == "subida_caida" then
        x = x + speed * dt * dir
        y = diver.baseY + (math.abs(math.sin(t * 3)) > 0.5 and -60 or 60)
    elseif movimiento == "espiral" then
        diver.baseX = diver.baseX + speed * dt * dir
        local radio = 10 + t * 5
        x = diver.baseX + math.cos(t * 4) * radio * dir
        y = diver.baseY + math.sin(t * 4) * radio
    elseif movimiento == "s_shape" then
        x = x + speed * dt * dir
        y = diver.baseY + math.sin(t * 10 + x / 30) * 40
    elseif movimiento == "salto_tramos" then
        x = x + speed * dt * dir
        y = diver.baseY + ((math.floor(t * 2) % 2 == 0) and -50 or 50)
    else
        x = x + speed * dt * dir
    end

    diver.body:setPosition(x, y)
end

function Divers.update(G, dt)
    local width = love.graphics.getWidth()
    local player = G.player

    for i = #G.buzos, 1, -1 do
        local diver = G.buzos[i]

        if diver.body and not diver.body:isDestroyed() then
            diver.anim:update(dt)

            local bx, by = diver.body:getPosition()
            local enemiesNear = G.world:queryRectangleArea(
                bx,
                by,
                config.divers.width + 10,
                config.divers.height + 10,
                { 'Enemy' }
            )

            if #enemiesNear > 0 then
                local ex = enemiesNear[1]:getPosition()
                local dir = bx < ex and -1 or 1

                bx = bx + dir * config.divers.fleeSpeed * dt
                diver.body:setX(bx)
                diver.direccion = dir == 1 and "derecha" or "izquierda"
            else
                updateMovement(diver, dt)
                bx, by = diver.body:getPosition()
            end

            if (diver.direccion == "derecha" and bx > width + 50)
                or (diver.direccion == "izquierda" and bx < -50) then
                diver.body:destroy()
                table.remove(G.buzos, i)
            elseif G.contadorBuzos < config.divers.max then
                local px, py = player.collider:getPosition()
                local distanciaX = math.abs(bx - px)
                local distanciaY = math.abs(by - py)
                local limiteX = (config.divers.width + config.divers.pickupWidth) / 2 + config.divers.pickupPaddingX
                local limiteY = (config.divers.height + config.divers.pickupHeight) / 2 + config.divers.pickupPaddingY

                if distanciaX < limiteX and distanciaY < limiteY then
                    table.insert(G.buzoRecogido, {
                        offsetX = (#G.buzoRecogido - 2) * 10,
                        offsetY = -30
                    })
                    G.contadorBuzos = G.contadorBuzos + 1

                    diver.body:destroy()
                    table.remove(G.buzos, i)
                end
            end
        end
    end
end

function Divers.deliver(G, dt)
    local player = G.player

    if not player.vivo then
        return
    end

    local _, jugadorY = player.collider:getPosition()

    if jugadorY > config.bounds.noDiversDepth and G.contadorBuzos == 0
        and not G.bajoSinBuzos and not G.buzosEntregados then
        G.bajoSinBuzos = true
    end

    if jugadorY <= config.bounds.surfaceY and G.bajoSinBuzos
        and G.contadorBuzos == 0 and not G.buzosEntregados then
        Player.loseLife(G)
        G.bajoSinBuzos = false
        return
    end

    if jugadorY <= config.bounds.surfaceY then
        if G.contadorBuzos > 0 then
            if not G.entregandoBuzos and not G.buzosEntregados then
                G.entregandoBuzos = true
                G.tiempoEntregaBuzo = 0
            end

            if G.entregandoBuzos then
                G.tiempoEntregaBuzo = G.tiempoEntregaBuzo + dt

                if G.tiempoEntregaBuzo >= 0.2 then
                    G.tiempoEntregaBuzo = 0

                    if G.contadorBuzos < config.divers.max then
                        G.contadorBuzos = G.contadorBuzos - 1
                        table.remove(G.buzoRecogido)
                        player.oxygen = player.maxOxygen
                        G.puntuacion = G.puntuacion + 200
                        G.buzosEntregados = true
                        G.entregandoBuzos = false
                    elseif G.contadorBuzos == config.divers.max then
                        G.contadorBuzos = 0
                        G.buzoRecogido = {}
                        G.puntuacion = G.puntuacion + 1000
                        player.oxygen = player.maxOxygen
                        G.mostrarAnimacionRescate = true
                        G.animacionRescateTimer = 2
                        G.entregandoBuzos = false
                        G.bajoSinBuzos = false
                        G.buzosEntregados = true
                        G.pendingWaveRestart = true
                    end
                end
            end
        end
    else
        G.entregandoBuzos = false
        G.buzosEntregados = false
    end

    if G.mostrarAnimacionRescate then
        G.animacionRescateTimer = G.animacionRescateTimer - dt

        if G.animacionRescateTimer <= 0 then
            G.mostrarAnimacionRescate = false
        end
    end
end

function Divers.clear(G)
    for i = #G.buzos, 1, -1 do
        G.buzos[i].body:destroy()
        table.remove(G.buzos, i)
    end

    for i = #G.buzosDelay, 1, -1 do
        table.remove(G.buzosDelay, i)
    end
end

function Divers.resetState(G)
    G.contadorBuzos = 0
    G.buzoRecogido = {}
    G.entregandoBuzos = false
    G.buzosEntregados = false
    G.bajoSinBuzos = false
    G.tiempoEntregaBuzo = 0
    G.pendingWaveRestart = false
end

function Divers.draw(G)
    for _, diver in ipairs(G.buzos) do
        if not diver.recogido then
            local x, y = diver.body:getPosition()
            love.graphics.setColor(1, 1, 1)
            diver.anim:draw(diver.image, x, y, 0, diver.lado == "izquierda" and -1 or 1, 1, 15, 10)
        end
    end
end

return Divers
