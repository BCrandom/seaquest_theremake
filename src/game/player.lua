local config = require("src/game/config")
local Projectiles = require("src/game/projectiles")

local Player = {}

local function playSource(source)
    source:stop()
    source:play()
end

function Player.new(G)
    local A = G.assets

    local player = {
        x = config.player.startX,
        y = config.player.startY,
        speed = config.player.speed,
        direccionDisparo = 1,
        vivo = true,
        vidas = config.player.lives,
        oxygen = config.player.oxygen,
        maxOxygen = config.player.oxygen,
        dead = false,
        tiempoMuerte = 0,
        tiempoReaparicion = config.player.respawnDelay,
        powerUps = {
            disparoRapido = false,
            inmortal = false,
            tiempoDisparoRapido = 0,
            tiempoInmortal = 0
        }
    }

    player.anim = A.player.anim:clone()
    player.animDead = A.playerDead.anim:clone()
    player.collider = G.world:newCircleCollider(player.x, player.y, config.player.radius)
    player.collider:setFixedRotation(true)
    player.collider:setCollisionClass("Player")

    return player
end

function Player.resetPowerUps(player)
    player.powerUps.disparoRapido = false
    player.powerUps.inmortal = false
    player.powerUps.tiempoDisparoRapido = 0
    player.powerUps.tiempoInmortal = 0
end

function Player.resetAfterRespawn(G)
    local player = G.player

    player.x = config.player.startX
    player.y = config.player.startY
    player.direccionDisparo = 1
    player.oxygen = player.maxOxygen
    player.tiempoMuerte = 0
    player.collider:setPosition(player.x, player.y)
    player.collider:setLinearVelocity(0, 0)

    player.animDead = G.assets.playerDead.anim:clone()
    Player.resetPowerUps(player)
end

function Player.updateAnimation(G, dt)
    local player = G.player

    if player.vivo then
        player.anim:update(dt)
    else
        player.animDead:update(dt)
    end
end

function Player.loseLife(G)
    local player = G.player

    if not player.vivo then
        return
    end

    player.vivo = false
    player.tiempoMuerte = 0
    player.oxygen = player.maxOxygen
    player.vidas = player.vidas - 1

    playSource(G.assets.sounds.deadPlayer)

    if player.vidas <= 0 then
        player.vidas = 0
        player.dead = true
        G.assets.sounds.background:stop()
        G.assets.sounds.boss:stop()
    end
end

function Player.checkDamage(G)
    local player = G.player

    if not player.vivo or player.powerUps.inmortal then
        return
    end

    local enemies = G.world:queryCircleArea(player.x, player.y, 21, { 'Enemy' })

    for _, collider in ipairs(enemies) do
        if not collider:isDestroyed() then
            for i = #G.tiburones, 1, -1 do
                if G.tiburones[i].body == collider then
                    collider:destroy()
                    table.remove(G.tiburones, i)
                    break
                end
            end

            Player.loseLife(G)
            return
        end
    end

    local bullets = G.world:queryCircleArea(player.x, player.y, 21, { 'DisparoEnemy' })

    if #bullets > 0 then
        for _, collider in ipairs(bullets) do
            for i = #G.disparos, 1, -1 do
                if G.disparos[i].body == collider then
                    collider:destroy()
                    table.remove(G.disparos, i)
                    break
                end
            end
        end

        Player.loseLife(G)
    end
end

function Player.update(G, dt)
    local player = G.player

    local vx, vy = 0, 0

    if love.keyboard.isDown("right") then
        vx = player.speed
        player.direccionDisparo = 1
    end

    if love.keyboard.isDown("left") then
        vx = -player.speed
        player.direccionDisparo = -1
    end

    if love.keyboard.isDown("up") then
        vy = -player.speed
    end

    if love.keyboard.isDown("down") then
        vy = player.speed
    end

    player.collider:setLinearVelocity(vx, vy)
    player.x = player.collider:getX()
    player.y = player.collider:getY()

    G.tiempoDesdeUltimoDisparo = G.tiempoDesdeUltimoDisparo + dt

    local cooldown = player.powerUps.disparoRapido and config.shooting.fastCooldown or G.disparoCooldown

    if love.keyboard.isDown("space") and G.tiempoDesdeUltimoDisparo >= cooldown then
        local offsetX = player.direccionDisparo * 20
        Projectiles.spawnPlayer(G, player.x + offsetX, player.y, player.direccionDisparo)
        playSource(G.assets.sounds.shootPlayer)
        G.tiempoDesdeUltimoDisparo = 0
    end

    if player.powerUps.disparoRapido then
        player.powerUps.tiempoDisparoRapido = player.powerUps.tiempoDisparoRapido - dt

        if player.powerUps.tiempoDisparoRapido <= 0 then
            player.powerUps.disparoRapido = false
        end
    end

    if player.powerUps.inmortal then
        player.powerUps.tiempoInmortal = player.powerUps.tiempoInmortal - dt

        if player.powerUps.tiempoInmortal <= 0 then
            player.powerUps.inmortal = false
        end
    end

    Player.checkDamage(G)
end

function Player.updateOxygen(G, dt)
    local player = G.player

    if not player.vivo then
        return
    end

    if player.y > config.bounds.surfaceY then
        player.oxygen = player.oxygen - dt * 3

        if player.oxygen <= 0 then
            player.oxygen = 0
            Player.loseLife(G)
        end
    end
end

function Player.draw(G)
    local player = G.player

    if player.vivo then
        player.anim:draw(G.assets.player.image, player.x, player.y, 0, -player.direccionDisparo, 1, 32, 32)
    else
        player.animDead:draw(G.assets.playerDead.image, player.x, player.y, 0, -player.direccionDisparo, 1, 32, 32)
    end
end

return Player
