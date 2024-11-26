---@class ChatBubble: Object
local ChatBubble, super = Class(Object)

function ChatBubble:init(actor, text, x, y)
    super.init(self,x,y)
    self.origin_x = 0.5
    local x_offset = actor.width * 2
    local y_offset = -actor.height
    local ok
    ok, self.text = pcall(Text, text, x_offset, y_offset, SCREEN_WIDTH * 2, SCREEN_HEIGHT * 2, {
        align = "center",
        font = "main_mono"
    })
    if (not ok) or (({self.text:getSize()})[1] == 0) then
        text = "[color:red](Invalid)"
        self.text = Text(text, x_offset, y_offset, SCREEN_WIDTH * 2, SCREEN_HEIGHT * 2, {
            align = "center",
            font = "main_mono"
        })
    end
    local w,h = self.text:getSize()
    self.text.width, self.text.height = math.max(4, w), math.max(4, h)
    self.width, self.height = math.max(4, w), math.max(4, h)
    self.text:setText(text)
    self.lifetime = 11
    self.rectangle = Rectangle(x_offset, y_offset, self.text:getSize())
    self:addChild(self.rectangle)
    self:addChild(self.text)
    self.alphafx = self:addFX(AlphaFX(1))
    self.text.debug_select = false
    self.rectangle.debug_select = false
    self.rectangle.alpha = 0.5
    self.rectangle.color = {0.2,0.2,0.2}
end

function ChatBubble:getDebugRectangle()
    return {0, 0, self.text:getSize()}
end

function ChatBubble:update()
    super.update(self)
    self.lifetime = self.lifetime - DT
    if self.lifetime < 0 then return self:remove() end
    if self.lifetime < 1 then
        self.alphafx.alpha = self.lifetime
    end
end


return ChatBubble