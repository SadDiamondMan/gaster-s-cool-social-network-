---@class Other_Battler : Character
---@overload fun(...) : Other_Battler
local Other_Battler, super = Class(Character)

function Other_Battler:init(chara, x, y, name, uuid)
    super.init(self, chara, x, y)
    self.name = name
    self.x = x or 0
    self.y = y or 0
    self.uuid = uuid
    self.chara = self

    self.alpha = 0
    self.fadingOut = false
    self.nametag = UserNametag(self, self.name)
    self:addChild(self.nametag)
end

function Other_Battler:getName()
    return self.name
end

function Other_Battler:getHealth()
    return self.health[1]
end

function Other_Battler:heal(heal_amount)
    --send the heal_amount to the server
    local updateMessage = {
        command = "battle",
        subCommand = "heal",
        heal_who = self.uuid,
        amount = heal_amount
    }
    Game:sendToServer(Game.client, updateMessage)
end

function Other_Battler:getStat(stat)
    if stat == "health" then
        return self.health[2] or "0"
    elseif stat == "health_def" then
        return self.health[2] or "0"
    end
end

function Other_Battler:getDebugInfo()
    local info = super.getDebugInfo(self)
    table.insert(info, "player: " .. self.name)
    if self.health then
        table.insert(info, "health: " .. self.health[1] .."/".. self.health[2])
    end
    return info
end

function Other_Battler:setActor(actor)
    super.setActor(self, actor)
end

function Other_Battler:handleMovement()
end

-- Example of updating sprite animation in Other_Battler class
function Other_Battler:update(...)
    if self.fadingOut then
        self.alpha = math.max(0, self.alpha - (DT * 4))
        if self.alpha <= 0 then
            self:remove()
        end
    else
        self.alpha = math.min(1, self.alpha + (DT * 4))
    end
    super.update(self, ...)
end


function Other_Battler:draw()
    -- Draw the player
    super.draw(self)
	local y_val = -8
	love.graphics.setColor({0.5, 0, 0, 1})
	love.graphics.rectangle("fill", -10, y_val, 40, 4)
	love.graphics.setColor({76/255, 1, 0, 1})
	if self.health then
		love.graphics.rectangle("fill", -10, y_val, 40 * (self.health[1] / self.health[2]), 4)
	else
		love.graphics.rectangle("fill", -10, y_val, 40, 4)
	end
end

return Other_Battler
