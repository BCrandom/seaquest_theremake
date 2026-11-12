local config = require("src/game/config")
local Assets = require("src/game/assets")
local WorldSetup = require("src/game/world")
local Player = require("src/game/player")
local Enemies = require("src/game/enemies")
local Divers = require("src/game/divers")
local Projectiles = require("src/game/projectiles")
local Powerups = require("src/game/powerups")
local Patterns = require("src/game/patterns")
local Hud = require("src/game/hud")
local sti = require('src/lib/sti')

local game = {}

local G = nil

local function createState()
    local assets = Assets.load()
    local world, walls = WorldSetup.create()

    local state = {
        config = config,
        assets = assets,
        world = world,
        walls = walls,
        map = sti('src/assets/sprites/map/background.lua'),

        tiburones = {},
        buzos = {},
        disparos = {},
        disparosJugador = {},
        enemigosDelay = {},
        buzosDelay = {},
        powerUps = {},

        puntuacion = 0,
        oleada = 1,

        tiempoEnemigo = 0,
        tiempoEntrePatrones = config.patterns.initialInterval,
        tiempoDesdeUltimoPatron = 0,
        disparoCooldown = config.shooting.cooldown,
        tiempoDesdeUltimoDisparo = config.shooting.cooldown,

        oleadaJefeActiva = false,
        avisoOleadaJefe = false,
        puntosUltimaOleadaJefe = 0,
        nivelOleadaJefe = 0,
        puntosEntreOleadas = config.boss.scoreInterval,
        tiempoOleadaJefe = 0,
        duracionOleadaJefe = config.boss.duration,
        tiempoAvisoJefe = 0,

        patrones = Patterns.getInitial(),
        indicePatronActual = 1,
        desbloqueosRealizados = {},
        ultimoPuntajePatron = 0,
        intervaloPuntajePatron = config.patterns.randomInterval,

        tiempoSpawnBuzoOleada = 0,
        cooldownBuzoOleada = config.diverWave.cooldown,

        tiempoPowerUp = 0,
        cooldownPowerUp = config.powerups.cooldown,

        contadorBuzos = 0,
        buzoRecogido = {},
        maxBuzos = config.divers.max,
        entregandoBuzos = false,
        buzosEntregados = false,
        bajoSinBuzos = false,
        animacionRescateTimer = 0,
        mostrarAnimacionRescate = false,
        tiempoEntregaBuzo = 0,
        pendingWaveRestart = false,

        easterEggPlayed = false
    }

    state.player = Player.new(state)

    return state
end

local function clearEntities(state)
    Enemies.clear(state)
    Divers.clear(state)
    Projectiles.clear(state)
    Powerups.clear(state)
end

local function resetPatterns(state)
    state.patrones = Patterns.getInitial()
    state.indicePatronActual = 1
    state.desbloqueosRealizados = {}
    state.ultimoPuntajePatron = 0
    state.intervaloPuntajePatron = config.patterns.randomInterval
    state.tiempoDesdeUltimoPatron = 0
    state.tiempoEntrePatrones = config.patterns.initialInterval
    state.tiempoEnemigo = 0
end

local function resetBoss(state, baseScore)
    state.oleadaJefeActiva = false
    state.avisoOleadaJefe = false
    state.nivelOleadaJefe = 0
    state.puntosEntreOleadas = config.boss.scoreInterval
    state.puntosUltimaOleadaJefe = baseScore or 0
    state.tiempoOleadaJefe = 0
    state.duracionOleadaJefe = config.boss.duration
    state.tiempoAvisoJefe = 0

    state.assets.sounds.boss:stop()
end

local function resetTimers(state)
    state.disparoCooldown = config.shooting.cooldown
    state.tiempoDesdeUltimoDisparo = state.disparoCooldown
    state.tiempoSpawnBuzoOleada = 0
    state.cooldownBuzoOleada = config.diverWave.cooldown
    state.tiempoPowerUp = 0
    state.cooldownPowerUp = config.powerups.cooldown
end

local function resetAfterLifeLost(state)
    clearEntities(state)
    state.puntuacion = 0

    Player.resetAfterRespawn(state)
    resetPatterns(state)
    resetTimers(state)
    resetBoss(state, 0)
    Divers.resetState(state)
    state.mostrarAnimacionRescate = false
    state.animacionRescateTimer = 0
    state.easterEggPlayed = false

    state.assets.sounds.boss:stop()
    state.assets.sounds.background:play()
end

local function restartEnemyWave(state)
    clearEntities(state)
    Player.resetAfterRespawn(state)

    state.indicePatronActual = 1
    state.tiempoEnemigo = 0
    state.tiempoEntrePatrones = state.oleadaJefeActiva
        and config.boss.patternInterval
        or config.patterns.waveRestartInterval
    state.tiempoDesdeUltimoPatron = 0
    Divers.resetState(state)

    state.disparoCooldown = config.shooting.cooldown
    state.tiempoDesdeUltimoDisparo = state.disparoCooldown
    state.tiempoSpawnBuzoOleada = 0
    state.cooldownBuzoOleada = config.diverWave.cooldown
    state.tiempoPowerUp = 0
    state.cooldownPowerUp = config.powerups.cooldown

    state.oleada = state.oleada + 1

    if not state.oleadaJefeActiva then
        state.assets.sounds.background:play()
    end
end

function game.load()
    love.window.setTitle("Seaquest: Definitive Edition")

    G = createState()
    game.player = G.player

    G.assets.sounds.background:play()
end

function game.update(dt)
    if not G then
        return
    end

    G.world:update(dt)
    Player.updateAnimation(G, dt)

    if G.player.dead then
        return
    end

    if not G.player.vivo then
        G.player.tiempoMuerte = G.player.tiempoMuerte + dt

        if G.player.tiempoMuerte >= G.player.tiempoReaparicion then
            G.player.vivo = true
            resetAfterLifeLost(G)
        end

        return
    end

    if G.puntuacion >= 50000 and not G.easterEggPlayed then
        G.easterEggPlayed = true
        G.assets.sounds.easterEgg:play()
    end

    Patterns.updateScorePatterns(G)
    Patterns.updateBoss(G, dt)
    Enemies.updatePending(G, dt)
    Divers.updatePending(G, dt)

    G.tiempoSpawnBuzoOleada = G.tiempoSpawnBuzoOleada + dt

    if G.tiempoSpawnBuzoOleada >= G.cooldownBuzoOleada then
        Divers.spawnPattern(G, Patterns.randomDiverWave())
        G.tiempoSpawnBuzoOleada = 0
    end

    G.tiempoDesdeUltimoPatron = G.tiempoDesdeUltimoPatron + dt

    if G.tiempoDesdeUltimoPatron >= G.tiempoEntrePatrones then
        if G.oleadaJefeActiva then
            Enemies.spawnPattern(G, Patterns.bossGroups(G.nivelOleadaJefe))
        else
            local patron = Patterns.next(G)

            if patron.lado == "IgualLados" then
                for _, lado in ipairs({ "izquierda", "derecha" }) do
                    local copia = Patterns.clone(patron)
                    copia.lado = lado
                    Enemies.spawnPattern(G, copia)
                    Divers.spawnPattern(G, copia)
                end
            else
                Enemies.spawnPattern(G, patron)
                Divers.spawnPattern(G, patron)
            end
        end

        G.tiempoDesdeUltimoPatron = 0
    end

    Powerups.update(G, dt)
    Player.update(G, dt)
    Enemies.update(G, dt)
    Projectiles.update(G, dt)
    Divers.update(G, dt)
    Divers.deliver(G, dt)

    if G.pendingWaveRestart then
        G.pendingWaveRestart = false
        restartEnemyWave(G)
    end

    if G.player.vivo then
        Player.updateOxygen(G, dt)
    end
end

function game.getState()
    return G
end

function game.draw()
    if not G then
        return
    end

    local map = G.map
    map:drawLayer(map.layers["notwater"])
    map:drawLayer(map.layers["realwater"])
    map:drawLayer(map.layers["clouds"])

    Player.draw(G)

    map:drawLayer(map.layers["realwaterwave"])
    map:drawLayer(map.layers["sand"])

    Enemies.draw(G)
    Divers.draw(G)
    Projectiles.draw(G)
    Powerups.draw(G)

    Hud.draw(G)
end

return game
