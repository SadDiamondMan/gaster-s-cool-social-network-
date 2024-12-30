---@class ChatInputBox : Object
---@overload fun(...) : ChatInputBox
local ChatInputBox, super = Class(Object)
function ChatInputBox:init(x,y)
    super.init(self, x, y, SCREEN_WIDTH, SCREEN_HEIGHT)
    self.is_open = false
    self.layer = 10000000 - 1

    self.font_size = 16
    self.font_name = "main_mono"

    self.font = Assets.getFont(self.font_name, self.font_size)
    self.input = {""}
    ---@type {sender:string, content:string[], timestamp: number?}[]
    self.chat_history = {}
    ---@type Component
    self.ui = self:addChild(Component(FixedSizing(SCREEN_WIDTH-12, SCREEN_HEIGHT - self.font_size)))
    self.ui.x = 12
    self.ui:setLayout(VerticalLayout({align = "end"}))
end

function ChatInputBox:updateSizing()
---@diagnostic disable-next-line: inject-field
    self.ui.y_sizing.height = SCREEN_HEIGHT - (#self.input * self.font_size) - 10
end

---@param msg {sender:string, content:string[], timestamp: number?}
function ChatInputBox:push(msg)
    -- table.insert(self.chat_history, msg)
    local text = string.format(GCSN.getConfig("chat_format"), msg.sender) .. msg.content
    ---@type boolean, Text
    local ok, obj = pcall(Text, text, nil,nil,nil,nil, {
        font = "main_mono",
        -- font_size = self.font_size,
    })
    if not ok then return end
    obj:setScale(.5)
    obj:resetState()
    obj:addFX(TextFadeoutFX(self))
    print(obj.font_size)
    self.ui:addChild(obj)
end

function ChatInputBox:onRemoveFromStage()
    TextInput.endInput()
end

function ChatInputBox:draw()
    local line_y = self.height-(self.font_size*#self.input)
    if self.is_open then
        love.graphics.line(0,line_y, self.width,line_y)
        TextInput.draw({
            prefix_width = self.font:getWidth("> "),
            get_prefix = function(place)
                if place == "start"  then return " " end
                if place == "middle" then return " " end
                if place == "end"    then return " " end
                if place == "single" then return " " end
                return " "
            end,
            x = -4,
            y = SCREEN_HEIGHT - (self.font_size*#self.input),
            print = function (text, x, y)
                love.graphics.setFont(self.font)
                love.graphics.print(text, x, y)
            end,
            font = self.font
        })
    end
    Draw.setColor()
    local y = line_y - (self.font_size / 4)
    for i=#self.chat_history, 1, -1 do
        local item = self.chat_history[i]
        love.graphics.setFont(self.font)
        local prefix = string.format(GCSN.getConfig("chat_format"), item.sender)
        for j=#item.content, 1, -1 do
            y = y - self.font_size
            local jtem = item.content[j]
            local sender = (j == 1) and prefix or string.rep(" ", #prefix)
            Draw.printShadow(sender .. jtem, 12, y)
        end
        if not self.is_open then break end
    end
    super.draw(self)
end

function ChatInputBox:close()
    self.is_open = false
    TextInput.endInput()
end

function ChatInputBox:onAdd(parent)
    super.onAdd(self, parent)
end

function ChatInputBox:open()
    self.is_open = true
    TextInput.attachInput(self.input, {
        multiline = true,
        enter_submits = true,
        text_restriction = function (char)
            return (#self.input < 30 or char ~= "\n")
        end,
    })
    TextInput.submit_callback = function() self:onSubmit() end
end

function ChatInputBox:onSubmit()
    Say(table.concat(self.input, "\n"))
    self:close()
end

function ChatInputBox:update()
    super.update(self)
    self:updateSizing()
end

return ChatInputBox