---@class NetPlayer: Class
local NetPlayer, super = Class(nil, "NetPlayer")

function NetPlayer:init(message, client, id)
    self.client = client
    self.actor = message.actor or "dummy"
    self.x = 0.0
    self.y = 0.0
    self.map = "room1"
    self.uuid = id
    -- TODO: rename to last_update
    self.lastUpdate = love.timer.getTime()
end

function NetPlayer:sendSystemMessage(content)
    self:send {
        command = "systemmessage",
        content = content,
    }
end

function NetPlayer:send(data)
    self.client:send(JSON.encode(data) .. "\n")
end

return NetPlayer