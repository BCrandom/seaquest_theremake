local anim8 = require('src/lib/anim8/anim8')

local assets = {}

assets.active = nil

local function newAnimation(path, frameWidth, frameHeight, frames, frameTime)
    local image = love.graphics.newImage(path)
    local grid = anim8.newGrid(frameWidth, frameHeight, image:getWidth(), image:getHeight())

    return {
        image = image,
        grid = grid,
        anim = anim8.newAnimation(grid(1, frames), frameTime or 0.1),
        frameWidth = frameWidth,
        frameHeight = frameHeight
    }
end

function assets.stopAll()
    if not assets.active then
        return
    end

    for _, name in ipairs({ "background", "boss", "deadPlayer", "shootPlayer", "shootEnemy", "deadEnemy", "easterEgg" }) do
        local source = assets.active.sounds[name]
        if source then
            source:stop()
        end
    end
end

function assets.load()
    assets.stopAll()

    love.graphics.setDefaultFilter("nearest", "nearest")

    local A = {}

    A.font = love.graphics.newFont("src/assets/fonts/PressStart2P-Regular.ttf", 16)

    A.player = newAnimation("src/assets/sprites/player/jugador (1).png", 64, 64, '1-5')
    A.player.quad = A.player.grid(1, 1)[1]

    A.playerDead = newAnimation("src/assets/sprites/player/DeadPlayer.png", 64, 64, '1-12')
    A.playerBullet = newAnimation("src/assets/sprites/player/misilPlayer.png", 48, 48, '1-2')

    A.enemySubmarine = newAnimation("src/assets/sprites/enemy/submarinoEnemigo.png", 64, 64, '1-5')
    A.enemyShark = newAnimation("src/assets/sprites/enemy/tiburones.png", 64, 64, '1-5')
    A.enemyBullet = newAnimation("src/assets/sprites/enemy/misilEnemy.png", 48, 48, '1-2')

    A.bossSubmarine = newAnimation("src/assets/sprites/Boss/submarinoEnemigoBoss.png", 64, 64, '1-6')
    A.bossShark = newAnimation("src/assets/sprites/Boss/tiburonBoss.png", 64, 64, '1-5')
    A.bossBullet = newAnimation("src/assets/sprites/Boss/misilEnemyBoss.png", 48, 48, '1-2')

    A.diver = newAnimation("src/assets/sprites/buzos/buzos.png", 64, 64, '1-6')
    A.diver.quad = A.diver.grid(1, 1)[1]

    A.powerupFast = newAnimation("src/assets/sprites/power Ups/DisparoRapido.png", 64, 64, '1-2')
    A.powerupImmortal = newAnimation("src/assets/sprites/power Ups/inmortal.png", 64, 64, '1-2')

    A.oxygenTank = love.graphics.newImage("src/assets/sprites/oxygen/oxygentank.png")

    A.sounds = {
        shootPlayer = love.audio.newSource("src/assets/sounds/disparo", "static"),
        shootEnemy = love.audio.newSource("src/assets/sounds/disparo3", "static"),
        deadEnemy = love.audio.newSource("src/assets/sounds/deadenemy2", "static"),
        deadPlayer = love.audio.newSource("src/assets/sounds/explosionplayer", "static"),
        easterEgg = love.audio.newSource("src/assets/sounds/aester egg.mp3", "static"),
        background = love.audio.newSource(
            "src/assets/sounds/A Night Of Dizzy Spells  NO COPYRIGHT 8-bit Music  Background.mp3",
            "stream"
        ),
        boss = love.audio.newSource(
            "src/assets/sounds/Joshua McLean - Mountain Trials  NO COPYRIGHT 8-bit Music.mp3",
            "stream"
        )
    }

    A.sounds.background:setLooping(true)
    A.sounds.background:setVolume(0.3)
    A.sounds.boss:setLooping(true)
    A.sounds.boss:setVolume(0.3)

    assets.active = A
    return A
end

return assets
