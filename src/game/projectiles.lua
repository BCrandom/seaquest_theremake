local config = require("src/game/config")

local Projectiles = {}

local function playSource(source)
    source:stop()
    source:play()
end

function Projectiles.clear(G)
    for i = #G.disparos, 1, -1 do
        G.disparos[i].body:destroy()
        table.remove(G.disparos, i)
    end

    for i = #G.disparosJugador, 1, -1 do
        G.disparosJugador[i].body:destroy()
        table.remove(G.disparosJugador, i)
    end
end

function Projectiles.clearEnemyBullets(G)
    for i = #G.disparos, 1, -1 do
        G.disparos[i].body:destroy()
        table.remove(G.disparos, i)
    end
end

function Projectiles.spawnPlayer(G, x, y, direccion)
    local bullet = {
        direccion = direccion,
        speed = direccion * config.shooting.bulletSpeed,
        image = G.assets.playerBullet.image,
        anim = G.assets.playerBullet.anim:clone()
    }

    bullet.body = G.world:newRectangleCollider(x, y, config.shooting.bulletWidth, config.shooting.bulletHeight)
    bullet.body:setType("kinematic")
    bullet.body:setCollisionClass("DisparoJugador")

    table.insert(G.disparosJugador, bullet)
end

function Projectiles.spawnEnemy(G, x, y, direccion)
    local bulletAssets = G.oleadaJefeActiva and G.assets.bossBullet or G.assets.enemyBullet

    local bullet = {
        direccion = direccion,
        speed = direccion * config.shooting.bulletSpeed,
        image = bulletAssets.image,
        anim = bulletAssets.anim:clone()
    }

    bullet.body = G.world:newRectangleCollider(x, y, config.shooting.bulletWidth, config.shooting.bulletHeight)
    bullet.body:setType("kinematic")
    bullet.body:setCollisionClass("DisparoEnemy")

    table.insert(G.disparos, bullet)
end

local function updateBullet(bullet, dt)
    bullet.anim:update(dt)

    local x, y = bullet.body:getPosition()
    local newX = x + bullet.speed * dt
    bullet.body:setX(newX)

    return newX
end

function Projectiles.update(G, dt)
    local width = love.graphics.getWidth()

    for i = #G.disparos, 1, -1 do
        local bullet = G.disparos[i]
        local x = updateBullet(bullet, dt)

        if x < -20 or x > width + 20 then
            bullet.body:destroy()
            table.remove(G.disparos, i)
        end
    end

    for i = #G.disparosJugador, 1, -1 do
        local bullet = G.disparosJugador[i]
        local x, y = bullet.body:getPosition()
        local newX = x + bullet.speed * dt

        bullet.body:setX(newX)
        bullet.anim:update(dt)

        if newX < -20 or newX > width + 20 then
            bullet.body:destroy()
            table.remove(G.disparosJugador, i)
        else
            local colliders = G.world:queryRectangleArea(x - 5, y - 2, 10, 5, { 'Enemy' })
            local hit = false

            for _, collider in ipairs(colliders) do
                if not collider:isDestroyed() then
                    for j = #G.tiburones, 1, -1 do
                        local enemy = G.tiburones[j]

                        if enemy.body == collider then
                            enemy.body:destroy()
                            table.remove(G.tiburones, j)
                            playSource(G.assets.sounds.deadEnemy)
                            G.puntuacion = G.puntuacion + 20
                            hit = true
                            break
                        end
                    end
                end

                if hit then
                    break
                end
            end

            if hit then
                bullet.body:destroy()
                table.remove(G.disparosJugador, i)
            end
        end
    end
end

function Projectiles.draw(G)
    love.graphics.setColor(1, 1, 1)

    for _, bullet in ipairs(G.disparos) do
        local x, y = bullet.body:getPosition()
        bullet.anim:draw(bullet.image, x, y, 0, -bullet.direccion, 1, 24, 24)
    end

    for _, bullet in ipairs(G.disparosJugador) do
        local x, y = bullet.body:getPosition()
        bullet.anim:draw(bullet.image, x, y, 0, -bullet.direccion, 1, 24, 24)
    end
end

return Projectiles
