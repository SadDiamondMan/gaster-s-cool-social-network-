---@class UserNametag : Object
---@overload fun(...) : UserNametag
local UserNametag, super = Class(Object)

function UserNametag:init(player_character, name)
    super.init(self)

    self.poilet_caper = player_character

    self.name = name
    self.length = string.len(self.name)


    self.font = Assets.getFont("main")
    self.smallfont = Assets.getFont("main",16)
    self.connected = false

    self.heart_sprite = Assets.getTexture("player/heart")

end

function UserNametag:pc_force_move(x, y, room)

    if not room == false then

    end

    self.poilet_caper.x = x
    self.poilet_caper.y = y
end

function UserNametag:update()
    super.update(self)
    self.name = self.poilet_caper.name
end

function UserNametag:draw()
    love.graphics.setFont(self.font)

    love.graphics.scale(0.5, 0.5)
    Draw.setColor(0, 0, 0, 1)
    for x=-1, 1 do
        for y=-1, 1 do
        love.graphics.print(self.name, self.length *-self.length/2 + (x*2), -self.poilet_caper.actor.height/2 *2 + (y*2))
    end
    end

    if self.name == "Hyperboid" then
        Draw.setColor(1, 0, 0, 1)
    elseif self.name == "SadDiamondMan" then
        Draw.setColor(0, 0, 1, 1)
    elseif self.name == "HYPERBOID" then
        Draw.setColor(1, 0, 0, 1)
        local x, y = self.length *-self.length/2 - 20, -self.poilet_caper.actor.height/2 *2 + 8
        Draw.draw(self.heart_sprite, x, y - 2)
        Draw.draw(self.heart_sprite, x, y + 2)
        Draw.draw(self.heart_sprite, x + 2, y)
        Draw.draw(self.heart_sprite, x - 2, y)

        Draw.setColor(1, 0, 0, 1)

        Draw.draw(self.heart_sprite, x, y)
    else
        Draw.setColor(1, 1, 1, 1)
    end

    love.graphics.print(self.name, self.length *-self.length/2, -self.poilet_caper.actor.height/2 *2)
    if DEBUG_RENDER and self.poilet_caper.uuid then
        love.graphics.setFont(self.smallfont)
        love.graphics.print(self.poilet_caper.uuid, -105, (-self.poilet_caper.actor.height/2 *2) + 32)
    end

    Draw.setColor(1, 1, 1, 1)
    super.draw(self)
end
return UserNametag
