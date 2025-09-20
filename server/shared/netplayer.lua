---@class NetPlayer: Class
local NetPlayer, super = Class(nil, "NetPlayer")

function NetPlayer:init(message, client, id)
    self.client = client
    self.actor = message.actor or "dummy"
    self.x = 0.0
    self.y = 0.0
    self.map = "room1"
    self.uuid = id
    self.username = message.username or "User"
    -- TODO: rename to last_update
    self.lastUpdate = love.timer.getTime()
    -- If the client is localhost, consider this player an admin.
    self.admin = (tostring(client):sub(1,4) == "127.")
end

function NetPlayer:sendSystemMessage(message)
    self:send {
        command = "systemmessage",
        message = message,
    }
end

function NetPlayer:send(data)
    self.client:send(JSON.encode(data) .. "\n")
end

return NetPlayer