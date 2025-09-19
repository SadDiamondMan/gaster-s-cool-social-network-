---@class UserNametag : Object
---@overload fun(...) : UserNametag
local UserNametag, super = Class(Object)

function UserNametag:init(pc, name)
    super.init(self)

    self.pc = pc

    self.name = name
    self.length = string.len(self.name)


    self.font = Assets.getFont("main")
    self.smallfont = Assets.getFont("main",16)
    self.connected = false

    self.heart_sprite = Assets.getTexture("player/heart")
	
	self:specialNames()
	
	self.name_text = Text(self.name, -self.pc.actor.width * 1.25, -self.pc.actor.height/2)
	self.name_text:setScale(0.5)
	self:addChild(self.name_text)
	
	self:addFX(OutlineFX({0, 0, 0}))
end

function UserNametag:pc_force_move(x, y, room)

    if not room == false then

    end

    self.pc.x = x
    self.pc.y = y
end

function UserNametag:specialNames()
	if self.name == "Hyperboid" then
		self.name = "[color:red]Hyperboid"
	elseif self.name == "SadDiamondMan" then
		self.name = "[color:blue]SadDiamondMan"
	elseif self.name == "HYPERBOID" then
		self.name = "[image:player/heart][color:red]HYPERBOID"
	end
end

function UserNametag:update()
    super.update(self)
    self.name = self.pc.name
	
	self:specialNames()
	
	self.name_text:setText(self.name)
end

return UserNametag
