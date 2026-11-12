local config = {}

config.width = 800
config.height = 600

config.player = {
    startX = 400,
    startY = 96,
    speed = 200,
    lives = 3,
    oxygen = 100,
    radius = 18,
    respawnDelay = 1.1
}

config.bounds = {
    surfaceY = 100,
    noDiversDepth = 115,
    topWall = 74,
    bottomWallMargin = 95
}

config.shooting = {
    cooldown = 0.4,
    fastCooldown = 0.15,
    bulletSpeed = 300,
    bulletWidth = 6,
    bulletHeight = 3
}

config.enemies = {
    width = 40,
    height = 20,
    speed = 100,
    fireInterval = 2,
    bossFireInterval = 0.7
}

config.divers = {
    width = 30,
    height = 20,
    max = 6,
    speed = 60,
    fleeSpeed = 120,
    pickupWidth = 40,
    pickupHeight = 20,
    pickupPaddingX = 15,
    pickupPaddingY = 10
}

config.powerups = {
    cooldown = 18,
    lifetime = 10,
    fastDuration = 6,
    immortalDuration = 5,
    radiusScale = 0.3,
    spawnMargin = 20
}

config.patterns = {
    initialInterval = 4,
    waveRestartInterval = 8,
    randomInterval = 450
}

config.boss = {
    scoreInterval = 3000,
    duration = 15,
    warning = 3,
    patternInterval = 5
}

config.diverWave = {
    cooldown = 30
}

return config
