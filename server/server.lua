---@class Server
local Server = {}
local TIMEOUT_THRESHOLD = 20

function Server:start()
    self.server = assert(Socket.bind("localhost", 25574))
    self.ip, self.port = self.server:getsockname()
    self.server:settimeout(0)
    print("Server started on " .. self.ip .. ":" .. self.port)
    
    self.clients = {}
    self.players = {}
    self.updateInterval = 0.1
    self.lastUpdateTime = Socket.gettime()
end

---Gets a player by their client
---@param client any -- The client to search for
---@return nil | table -- A player if one is found
function Server:getPlayerFromClient(client)
    for key, value in pairs(self.players) do
        if value.client == client then
            return value
        end
    end
end

---Sends data to the specified client, serializing if necessary.
---@param client any -- The client to send to
---@param data string|table
function Server:sendClientMessage(client, data)
    if client.client then -- Allow players to be passed here
        client = client.client
    end
    if type(data) == "table" then
        data = JSON.encode(data) .. "\n"
    end
    client:send(data)
end

function Server:shutdown(message)
    for _, client in ipairs(self.clients) do
        self:sendClientMessage(client, {
            command = "disconnect",
            message = message
        })
        client:close()
        self:removePlayer(client)
    end
    self.server:close()
end

local self = Server

math.randomseed(os.time())

local random = math.random
local function uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

--print(uuid())

-- Remove disconnected player
function Server:removePlayer(client)
    for i, c in ipairs(self.clients) do
        if c == client then
            table.remove(self.clients, i)
            break
        end
    end
    for id, player in pairs(self.players) do
        if player.client == client then
            print("Player " .. self.players[id].username .. " removed due to disconnection.")
            self.players[id] = nil
            break
        end
    end
end

-- Check for inactive players
function Server:checkForInactivePlayers()
    local currentTime = Socket.gettime()
    for id, player in pairs(self.players) do
        if currentTime - player.lastUpdate >= TIMEOUT_THRESHOLD then
            self:removePlayer(player.client)
        end
    end
end

function Server:sendUpdatesToClients()
    local updates = {}

    -- Collect updates per map
    for id, player in pairs(self.players) do
        if player.client and player.state == "world" then
            updates[player.map] = updates[player.map] or {}
            table.insert(updates[player.map], {
                uuid = id,
                username = player.username,
                x = player.x,
                y = player.y,
                actor = player.actor,
                sprite = player.sprite,
                map = player.map
            })
        end
    end

    -- Send updates only to players on the same map, excluding the player's own UUID
    for id, player in pairs(self.players) do
        if player.client and updates[player.map] then
            -- Filter out the player's own UUID
            local filteredUpdates = {}
            for _, update in ipairs(updates[player.map]) do
                if update.uuid ~= id then
                    table.insert(filteredUpdates, update)
                end
            end

            local updateMessage = {
                command = "update",
                players = filteredUpdates
            }
            self:sendClientMessage(player.client, updateMessage)
        end
    end
end

function Server:sendBattleUpdatesToClients()
    local updates = {}

    -- Collect updates per encountr

    for id, player in pairs(self.players) do
        if player.client and player.state == "battle" then
            updates[player.encounter] = updates[player.encounter] or {}
            table.insert(updates[player.encounter], {
                uuid = id,
                username = player.username,
                actor = player.actor,
                sprite = player.sprite,
                health = player.health,
                encounter = player.encounter
            })
        end
    end

    -- Send updates only to players on the same encounter, excluding the player's own UUID
    for id, player in pairs(self.players) do
        if player.client and updates[player.encounter] then
            -- Filter out the player's own UUID
            local filteredUpdates = {}
            for _, update in ipairs(updates[player.encounter]) do
                if update.uuid ~= id then
                    table.insert(filteredUpdates, update)
                end
            end

            local updateMessage = {
                command = "battle_update",
                players = filteredUpdates
            }
            self:sendClientMessage(player.client, updateMessage)
        end
    end
end

-- Handle client messages
function Server:processClientMessage(client, data)
    local ok, message = pcall(JSON.decode, data)
    if not ok then return print(message) end
    local command = message.command
    local subCommand = message.subCommand

    if command == "register" then
        local id = message.uuid or uuid()
        self.players[id] = {
            username = message.username,
            x = 0, y = 0, actor = message.actor or "dummy",
            sprite = message.sprite or "walk/down", 
            map = message.map or "default", 
            uuid = id,
            client = client,
            lastUpdate = Socket.gettime()
        }
        print("Player " .. message.username .. "(uuid=" .. id .. ") registered with actor: " .. self.players[id].actor)
        self:sendClientMessage(client, {
            command = "register",
            uuid = id
        })

    elseif command == "world" then 
        if subCommand == "update" then
            local player = self:getPlayerFromClient(client)
            if player then
                player.username = message.username
                player.x = message.x
                player.y = message.y
                player.map = message.map or player.map
                player.actor = message.actor
                player.sprite = message.sprite
                player.lastUpdate = Socket.gettime()
                player.state = "world"
            end
        elseif subCommand == "inMap" then
            local id = message.uuid
            local clientPlayers = message.players
            local player = self:getPlayerFromClient(client)

            if player then
                local actualMapPlayers = {}
                for otherId, otherPlayer in pairs(self.players) do
                    if otherPlayer.map == player.map then
                        actualMapPlayers[otherId] = true
                    end
                end

                -- Determine which players to remove
                local playersToRemove = {}
                for _, clientPlayer in ipairs(clientPlayers) do
                    if not actualMapPlayers[clientPlayer] then
                        table.insert(playersToRemove, clientPlayer)
                    end
                end

                -- Send removal message if needed
                if #playersToRemove > 0 then
                    local removeMessage = {
                        command = "RemoveOtherPlayersFromMap",
                        players = playersToRemove
                    }
                    self:sendClientMessage(player.client, removeMessage)
                end
            end
        elseif subCommand == "chat" then
            local id = message.uuid
            if #message.message == 0 then return end
            local sender = self.players[id]
            if sender then
                print(sender.username, message.message)
            else
                print("unknown", message.message)
            end
            for _, reciever in pairs(self.players) do
                
                if reciever.map == sender.map then
                    self:sendClientMessage(reciever.client, {
                        command = "chat",
                        uuid = id,
                        message = message.message
                    })
                end
            end
        end
    elseif command == "battle" then
        if subCommand == "update" then
            local player = self:getPlayerFromClient(client)
            if player then
                player.username = message.username
                player.encounter = message.encounter or player.encounter
                player.actor = message.actor
                player.sprite = message.sprite
                player.lastUpdate = Socket.gettime()
                player.health = message.health
                player.state = "battle"
            end
        elseif subCommand == "heal" then
            local target = message.heal_who
            
            local player = self.players[message.heal_who]

            local heal = {
                command = "heal",
                amount = message.amount
            }
            if player then
                self:sendClientMessage(player.client, heal)
            end
        elseif subCommand == "inParty" then
            local id = message.uuid
            local clientPlayers = message.players
            local player = self:getPlayerFromClient(client)

            if player then
                local actualMapPlayers = {}
                for otherId, otherPlayer in pairs(self.players) do
                    if otherPlayer.encounter == player.encounter then
                        actualMapPlayers[otherId] = true
                    end
                end

                -- Determine which players to remove
                local playersToRemove = {}
                for _, clientPlayer in ipairs(clientPlayers) do
                    if not actualMapPlayers[clientPlayer] then
                        table.insert(playersToRemove, clientPlayer)
                    end
                end

                -- Send removal message if needed
                if #playersToRemove > 0 then
                    local removeMessage = {
                        command = "remove_battlers",
                        players = playersToRemove
                    }
                    self:sendClientMessage(player.client, removeMessage)
                end
            end
        end
    elseif command == "disconnect" then
        print("Player " .. self:getPlayerFromClient(client).username .. " disconnected")
        self:removePlayer(client)
    elseif command == "heartbeat" then
        local player = self:getPlayerFromClient(client)
        if player then
            player.lastUpdate = Socket.gettime()
        end
    else
        print("Unhandled command:".. command)
        print(data)
    end
end

-- Main server loop
function Server:tick()
    local client = self.server:accept()
    if client then
        client:settimeout(0)
        table.insert(self.clients, client)
        print("New client connected")
    end

    local readable, _, _ = Socket.select(self.clients, nil, 0)
    for _, client in ipairs(readable) do
        local data, err = client:receive()
        if data then
            self:processClientMessage(client, data)
        elseif err == "closed" then
            self:removePlayer(client)
            print("Client disconnected")
        end
    end

    local currentTime = Socket.gettime()
    if (currentTime - self.lastUpdateTime) >= self.updateInterval then
        self:sendUpdatesToClients()
        self:sendBattleUpdatesToClients()
        self.lastUpdateTime = currentTime
    end

    -- Check for inactive players
    self:checkForInactivePlayers()
end

return Server