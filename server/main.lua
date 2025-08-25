enet = require("enet")
JSON = require("json")
NBT = require("shared.nbt")
---@type Server
local Server = require("server")

---@type Server
local server = setmetatable({},{__index = Server})
server:start()

function love.update(dt)
    local success, value = xpcall(server.tick, debug.traceback, server) -- Call the main server function once per update
    if not success then
        print(value)
        server:shutdown(value)
        love.timer.sleep(5)
        print("restarting...")
        server = setmetatable({},{__index = Server})
        server:start()
    end
end

function love.draw()
    love.graphics.setColor(1, 1, 1)  -- Set color to white
    love.graphics.printf("Connected Players:\n", 10, 10, love.graphics.getWidth(), "left")
    
    local yOffset = 30
    local function line(text)
        love.graphics.printf(text, 10, yOffset, love.graphics.getWidth(), "left")
        yOffset = yOffset + 15
    end
    for _, player in pairs(server.players) do
        if player.state == "battle" and player.username and player.uuid and player.encounter and player.actor and player.sprite and player.health then
            line("Player: " .. player.username)
            line("UUID: " .. player.uuid)
            line("Actor: " .. player.actor)
            line("Sprite: " .. player.sprite)
            line("Encounter: " .. player.encounter)
            line("Health: " .. player.health[1] .." / ".. player.health[2])
            yOffset = yOffset + 10
        elseif player.state == "world" and player.username and player.uuid and player.map and player.actor and player.x and player.y then
            line("Player: " .. player.username)
            line("UUID: " .. player.uuid)
            line("Actor: " .. player.actor)
            line("Sprite: " .. player.sprite)
            line("Map: " .. player.map)
            line("X: " .. player.x .. ", Y: " .. player.y)
            yOffset = yOffset + 10
        end
    end
end