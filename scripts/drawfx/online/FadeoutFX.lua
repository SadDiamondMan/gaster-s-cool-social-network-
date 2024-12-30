---@class FadeoutFX : FXBase
local FadeoutFX, super = Class(FXBase)

function FadeoutFX:init(target)
    super.init(self)
    self.startTime = RUNTIME
    self.target = target
end

function FadeoutFX:draw(texture)
    Draw.setColor(COLORS.white(self:getAlpha()))
    Draw.draw(texture)
end

function FadeoutFX:getAlpha()
    if self.target.is_open then
        return 1
    else
        return 7 - (Kristal.getTime() - self.startTime)
    end
end

return FadeoutFX