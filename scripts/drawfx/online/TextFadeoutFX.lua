---@class FadeoutFX : FXBase
local FadeoutFX, super = Class(FXBase)

function FadeoutFX:init(target)
    super.init(self)
    self.startTime = RUNTIME
    self.target = target
end

function FadeoutFX:draw(texture)
    Draw.setColor(COLORS.black(self:getAlpha() * 0.2))
    Draw.rectangle("fill", self.parent.x,self.parent.y, SCREEN_WIDTH, self.parent:getTextHeight()/2)
    Draw.setColor(COLORS.white(self:getAlpha()))
    Draw.draw(texture)
end

function FadeoutFX:getAlpha()
    if self.target.is_open then
        return 1
    else
        return Utils.clamp(7 - (Kristal.getTime() - self.startTime), 0, 1)
    end
end

return FadeoutFX