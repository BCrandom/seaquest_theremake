local config = require("src/game/config")
local Enemies = require("src/game/enemies")
local Projectiles = require("src/game/projectiles")

local Patterns = {}

local BASE_PATTERNS = {
    { lado = "izquierda", cantidad = 3, espacio = 50, tipo = "buzo", delay = true, orientacion = "vertical", movimiento = 'zigzag' },
    { lado = "IgualLados", delay = true, orientacion = 'vertical', movimiento = "lineal", enemigos = { { tipo = "submarino", cantidad = 2, espacio = 40 }, { tipo = "tiburon", cantidad = 3, espacio = 40 } } },
    { lado = "derecha", orientacion = 'vertical', enemigos = { { tipo = "submarino", cantidad = 2, espacio = 60 }, { tipo = "tiburon", cantidad = 3, espacio = 50 } } },
    { lado = "derecha", cantidad = 3, espacio = 50, tipo = "buzo", delay = true, orientacion = "vertical", movimiento = 'espiral' },
    { lado = "izquierda", orientacion = 'vertical', enemigos = { { tipo = "submarino", cantidad = 3, espacio = 60 }, { tipo = "tiburon", cantidad = 3, espacio = 50 } } },
    { lado = "derecha", cantidad = 3, espacio = 50, tipo = "buzo", delay = true, orientacion = "vertical", movimiento = 'salto_tramos' },
    { lado = "ambos", orientacion = "vertical", enemigos = { { lado = "derecha", tipo = "submarino", cantidad = 3, espacio = 50, movimiento = 'zigzag' }, { lado = "izquierda", tipo = "tiburon", cantidad = 4, espacio = 40, movimiento = 'sinusoidal' } } },
    { lado = "IgualLados", orientacion = 'vertical', tipo = 'tiburon', cantidad = 4, espacio = 40 },
    { lado = "IgualLados", orientacion = 'vertical', tipo = 'submarino', cantidad = 4, espacio = 50 },
    { lado = "izquierda", cantidad = 3, espacio = 50, tipo = "buzo", delay = true, orientacion = "vertical", movimiento = 'espiral' },
    { lado = "IgualLados", delay = true, orientacion = 'vertical', tipo = 'submarino', cantidad = 2, espacio = 50 },
    { lado = "derecha", delay = true, orientacion = 'vertical', tipo = 'tiburon', cantidad = 4, espacio = 40 },
    { lado = "derecha", delay = true, orientacion = 'vertical', movimiento = 'zigzag', enemigos = { { tipo = "submarino", cantidad = 2, espacio = 60 }, { tipo = "tiburon", cantidad = 3, espacio = 50 } } },
    { lado = "derecha", cantidad = 3, espacio = 50, tipo = "buzo", delay = true, orientacion = "vertical", movimiento = 'subida_caida' },
}

local UNLOCKS = {
    [350] = {
        { lado = "derecha", cantidad = 3, espacio = 50, tipo = "buzo", delay = true, orientacion = "vertical", movimiento = 'espiral' }
    },
    [550] = {
        { lado = "izquierda", cantidad = 3, espacio = 50, tipo = "buzo", delay = true, orientacion = "vertical", movimiento = 'espiral' }
    },
    [600] = {
        { lado = "ambos", orientacion = "vertical", enemigos = { { lado = "derecha", tipo = "submarino", cantidad = 3, espacio = 50, movimiento = 'zigzag' }, { lado = "izquierda", tipo = "tiburon", cantidad = 4, espacio = 40, movimiento = 'sinusoidal' } } }
    },
    [700] = {
        { lado = "ambos", cantidad = 3, espacio = 50, tipo = "buzo", delay = true, orientacion = "vertical", movimiento = 'espiral' }
    },
    [800] = {
        { lado = "ambos", orientacion = "vertical", enemigos = { { lado = "derecha", tipo = "tiburon", cantidad = 3, espacio = 40, movimiento = 'zigzag' }, { lado = "izquierda", tipo = "tiburon", cantidad = 4, espacio = 50, movimiento = 'espiral' } } }
    },
    [1000] = {
        { lado = "ambos", orientacion = "vertical", delay = true, enemigos = { { lado = "derecha", tipo = "submarino", cantidad = 2, espacio = 40, movimiento = 'lineal' }, { lado = "izquierda", tipo = "submarino", cantidad = 4, espacio = 60, movimiento = 'lineal' } } }
    },
    [1500] = {
        { lado = "ambos", orientacion = "vertical", enemigos = { { lado = "derecha", tipo = "submarino", cantidad = 2, espacio = 40, movimiento = 's_shape' }, { lado = "izquierda", tipo = "tiburon", cantidad = 2, espacio = 40, movimiento = 'sinusoidal' } } }
    },
    [1700] = {
        { lado = "ambos", orientacion = "vertical", enemigos = { { lado = "derecha", tipo = "submarino", cantidad = 2, espacio = 50, movimiento = 'lineal' }, { lado = "izquierda", tipo = "tiburon", cantidad = 3, espacio = 60, movimiento = 's_shape' } } }
    },
    [2000] = {
        { lado = "ambos", orientacion = "vertical", enemigos = { { lado = "derecha", tipo = "submarino", cantidad = 2, espacio = 60, movimiento = 's_shape' }, { lado = "izquierda", tipo = "tiburon", cantidad = 4, espacio = 60, movimiento = 'espiral' } } }
    },
}

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}

    for key, item in pairs(value) do
        copy[key] = deepCopy(item)
    end

    return copy
end

function Patterns.getInitial()
    return deepCopy(BASE_PATTERNS)
end

Patterns.clone = deepCopy

function Patterns.next(G)
    local patron = G.patrones[G.indicePatronActual]
    G.indicePatronActual = G.indicePatronActual % #G.patrones + 1
    return patron
end

function Patterns.random()
    local lados = { "izquierda", "derecha", 'IgualLados', 'ambos' }
    local orientaciones = { "horizontal", "vertical" }
    local movimientos = {
        "lineal", "zigzag", "circular", "sinusoidal", "subida_caida", "espiral",
        "osc_amplitud", "s_shape", "cuadrado", "flor", "reloj", "patrulla",
        "salto_tramos", "aleatorio"
    }
    local tipos = { "tiburon", "submarino" }

    return {
        lado = lados[math.random(#lados)],
        orientacion = orientaciones[math.random(#orientaciones)],
        delay = math.random() < 0.7,
        movimiento = movimientos[math.random(#movimientos)],
        enemigos = {
            {
                tipo = tipos[math.random(#tipos)],
                cantidad = math.random(4, 8),
                espacio = math.random(40, 80)
            }
        }
    }
end

function Patterns.randomDiverWave()
    return {
        lado = (math.random() < 0.5) and "izquierda" or "derecha",
        orientacion = "vertical",
        delay = true,
        movimiento = "zigzag",
        enemigos = {
            {
                tipo = "buzo",
                cantidad = math.random(2, 5),
                espacio = math.random(40, 80)
            }
        }
    }
end

function Patterns.updateScorePatterns(G)
    if G.puntuacion >= G.ultimoPuntajePatron + G.intervaloPuntajePatron then
        table.insert(G.patrones, Patterns.random())
        G.ultimoPuntajePatron = G.ultimoPuntajePatron + G.intervaloPuntajePatron
    end

    for puntaje, nuevosPatrones in pairs(UNLOCKS) do
        if G.puntuacion >= puntaje and not G.desbloqueosRealizados[puntaje] then
            for _, nuevoPatron in ipairs(nuevosPatrones) do
                table.insert(G.patrones, deepCopy(nuevoPatron))
            end

            G.desbloqueosRealizados[puntaje] = true
        end
    end
end

function Patterns.bossGroups(nivel)
    local movimientosDisponibles = {
        "lineal", "zigzag", "circular", "sinusoidal", "subida_caida", "espiral",
        "osc_amplitud", "s_shape", "cuadrado", "flor", "reloj", "patrulla",
        "salto_tramos", "aleatorio"
    }
    local ladosDisponibles = { "izquierda", "derecha" }
    local tiposDisponibles = { "submarino", "tiburon" }

    local cantidadGrupos = love.math.random(1, 3)
    local espacio = math.max(20, 50 - nivel * 5)
    local grupos = {}

    for _ = 1, cantidadGrupos do
        table.insert(grupos, {
            tipo = tiposDisponibles[love.math.random(#tiposDisponibles)],
            lado = ladosDisponibles[love.math.random(#ladosDisponibles)],
            movimiento = movimientosDisponibles[love.math.random(#movimientosDisponibles)],
            cantidad = love.math.random(1, 3 + nivel),
            espacio = espacio
        })
    end

    return {
        delay = true,
        orientacion = 'vertical',
        enemigos = grupos
    }
end

function Patterns.updateBoss(G, dt)
    if G.avisoOleadaJefe then
        G.tiempoAvisoJefe = G.tiempoAvisoJefe - dt

        if G.tiempoAvisoJefe <= 0 then
            G.avisoOleadaJefe = false
        end
    end

    if G.puntuacion >= G.puntosUltimaOleadaJefe + G.puntosEntreOleadas and not G.oleadaJefeActiva then
        G.oleadaJefeActiva = true
        G.avisoOleadaJefe = true
        G.tiempoEntrePatrones = config.boss.patternInterval
        G.tiempoAvisoJefe = config.boss.warning
        G.nivelOleadaJefe = G.nivelOleadaJefe + 1
        G.tiempoOleadaJefe = 0
        G.puntosUltimaOleadaJefe = G.puntuacion

        G.assets.sounds.background:stop()
        G.assets.sounds.boss:play()

        Enemies.clear(G)
        Projectiles.clearEnemyBullets(G)
        G.tiempoDesdeUltimoPatron = 0

        Enemies.spawnPattern(G, Patterns.bossGroups(G.nivelOleadaJefe))
    end

    if G.oleadaJefeActiva then
        G.tiempoOleadaJefe = G.tiempoOleadaJefe + dt

        if G.tiempoOleadaJefe >= G.duracionOleadaJefe then
            G.oleadaJefeActiva = false
            G.tiempoEntrePatrones = config.boss.patternInterval
            G.assets.sounds.boss:stop()
            G.assets.sounds.background:play()
            G.puntosEntreOleadas = G.puntosEntreOleadas * 2
        end
    end
end

return Patterns
