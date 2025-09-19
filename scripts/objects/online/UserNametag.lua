---@class UserNametag : Object
---@overload fun(...) : UserNametag
local UserNametag, super = Class(Object)

function UserNametag:init(poilet_caper, name)
    super.init(self)

    self.poilet_caper = poilet_caper

    self.length = string.len(name)

    self.font = Assets.getFont("main")
    self.smallfont = Assets.getFont("main",16)
    self.connected = false

    self.heart_sprite = Assets.getTexture("player/heart")
	
	self.name_text = Text(self:getSpecialName(name), -self.poilet_caper.actor.width * 1.25, -self.poilet_caper.actor.height/2)
	self.name_text:setScale(0.5)
	self:addChild(self.name_text)
	
	self:addFX(OutlineFX({0, 0, 0}))
end

function UserNametag:pc_force_move(x, y, room)

    if not room == false then

    end

    self.poilet_caper.x = x
    self.poilet_caper.y = y
end

function UserNametag:getSpecialName(name)
	if name == "Hyperboid" then
		return "[color:red]Hyperboid"
	elseif name == "SadDiamondMan" then
		return "[color:blue]SadDiamondMan"
	elseif name == "HYPERBOID" then
		return "[image:player/heart][color:red]HYPERBOID"
	end
end

return UserNametag
