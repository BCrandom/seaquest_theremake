local config = require("src/game/config")

local Powerups = {}

local TYPES = { "disparoRapido", "inmortal" }

function Powerups.spawn(G)
    local tipo = TYPES[love.math.random(#TYPES)]
    local powerupAssets = tipo == "disparoRapido" and G.assets.powerupFast or G.assets.powerupImmortal
    local frameWidth = powerupAssets.frameWidth
    local frameHeight = powerupAssets.frameHeight

    local minX = config.powerups.spawnMargin
    local maxX = math.max(minX, love.graphics.getWidth() - config.powerups.spawnMargin - frameWidth)
    local minY = config.bounds.topWall + 10
    local maxY = math.max(minY, love.graphics.getHeight() - config.bounds.bottomWallMargin - frameHeight)

    local x = love.math.random(minX, maxX)
    local y = love.math.random(minY, maxY)

    local radio = math.min(frameWidth, frameHeight) * config.powerups.radiusScale
    local centerX = x + frameWidth / 2
    local centerY = y + frameHeight / 2

    local powerup = {
        tipo = tipo,
        x = x,
        y = y,
        image = powerupAssets.image,
        anim = powerupAssets.anim:clone(),
        tiempoVida = config.powerups.lifetime
    }

    powerup.body = G.world:newRectangleCollider(
        centerX - radio,
        centerY - radio,
        radio * 2,
        radio * 2
    )
    powerup.body:setCollisionClass('PowerUp')
    powerup.body:setType("static")
    powerup.body:setObject(powerup)

    table.insert(G.powerUps, powerup)
end

function Powerups.update(G, dt)
    G.tiempoPowerUp = G.tiempoPowerUp + dt

    if G.tiempoPowerUp >= G.cooldownPowerUp then
        Powerups.spawn(G)
        G.tiempoPowerUp = 0
    end

    local colliders = {}

    if G.player.vivo then
        colliders = G.world:queryCircleArea(G.player.x, G.player.y, 21, { 'PowerUp' })
    end

    for i = #G.powerUps, 1, -1 do
        local powerup = G.powerUps[i]
        local collided = false

        powerup.anim:update(dt)

        for _, collider in ipairs(colliders) do
            if collider == powerup.body then
                collided = true
                break
            end
        end

        if collided then
            if powerup.tipo == "disparoRapido" then
                G.player.powerUps.disparoRapido = true
                G.player.powerUps.tiempoDisparoRapido = config.powerups.fastDuration
            elseif powerup.tipo == "inmortal" then
                G.player.powerUps.inmortal = true
                G.player.powerUps.tiempoInmortal = config.powerups.immortalDuration
            end

            powerup.body:destroy()
            table.remove(G.powerUps, i)
        else
            powerup.tiempoVida = powerup.tiempoVida - dt

            if powerup.tiempoVida <= 0 then
                powerup.body:destroy()
                table.remove(G.powerUps, i)
            end
        end
    end
end

function Powerups.clear(G)
    for i = #G.powerUps, 1, -1 do
        G.powerUps[i].body:destroy()
        table.remove(G.powerUps, i)
    end
end

function Powerups.draw(G)
    for _, powerup in ipairs(G.powerUps) do
        love.graphics.setColor(1, 1, 1)
        powerup.anim:draw(powerup.image, powerup.x, powerup.y)
    end
end

return Powerups
