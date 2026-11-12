local Hud = {}

function Hud.draw(G)
    local assets = G.assets
    local player = G.player
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()

    if G.avisoOleadaJefe then
        love.graphics.setFont(assets.font)
        love.graphics.setColor(1, 0, 0)
        love.graphics.printf("¡ALERTA: OLEADA DE JEFE INMINENTE!", 0, height / 2 - 20, width, "center")
    end

    love.graphics.setFont(assets.font)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(tostring(G.puntuacion), 0, 20, width, "center")

    if player.vivo then
        for i = 1, player.vidas do
            local vidaX = 250 + (i - 1) * 40
            love.graphics.draw(assets.player.image, assets.player.quad, vidaX, 10, 0, -0.5, 0.5)
        end
    end

    for i = 1, G.contadorBuzos do
        local buzoX = 500 + (i - 1) * 40
        love.graphics.draw(assets.diver.image, assets.diver.quad, buzoX, 10, 0, -0.5, 0.5)
    end

    local tankX = 30
    local tankY = 1
    local scale = 3

    local tankWidth = assets.oxygenTank:getWidth() * scale - 1
    local tankHeight = assets.oxygenTank:getHeight() * scale - 45

    local padding = 3 * scale
    local fillWidth = tankWidth - padding * 2
    local fillHeight = tankHeight - padding * 2
    local oxygenRatio = player.oxygen / player.maxOxygen

    love.graphics.setColor(0.8, 0.8, 1)
    love.graphics.rectangle(
        "fill",
        tankX + padding - 9,
        tankY + padding * 2,
        fillWidth * oxygenRatio,
        fillHeight
    )

    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(assets.oxygenTank, tankX, tankY - 12, 0, scale, scale)

    if G.mostrarAnimacionRescate then
        love.graphics.setColor(1, 1, 0)
        love.graphics.printf("¡RESCATE COMPLETO!", 0, height / 2 - 20, width, "center")
    end

    love.graphics.setColor(1, 1, 1)
end

return Hud
