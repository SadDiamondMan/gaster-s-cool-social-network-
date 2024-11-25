---@class GCSNOptionsHandler : StateClass
---
---@field menu MainMenu
---
---@field state string
---@field state_manager StateManager
---
---@field options gcsnconfigoptions
---@field selected_option number
---
---@field id_adjusted boolean
---
---@field input_pos_x number
---@field input_pos_y number
---
---@overload fun(menu:MainMenu) : GCSNOptionsHandler
local GCSNOptionsHandler, super = Class(StateClass)

---@class gcsnconfigoptions
---@field domain {[1]: string}
---@field port {[1]: string}

function GCSNOptionsHandler:init(menu)
    self.menu = menu
    if Kristal.Config["plugins/gcsn"] == nil then
        Kristal.Config["plugins/gcsn"] = {
            domain = "serveo.net",
            port = 25574,
            chatBind = "/",
        }
    end
    self.plugconfig = Kristal.Config["plugins/gcsn"]
    self.state_manager = StateManager("NONE", self, true)

    self.options = {
        domain = {self.plugconfig.domain},
        port = {tostring(self.plugconfig.port)},
    }
    self.selected_option = 1

    self.input_pos_x = 0
    self.input_pos_y = 0
end

function GCSNOptionsHandler:registerEvents()
    self:registerEvent("enter", self.onEnter)
    self:registerEvent("keypressed", self.onKeyPressed)
    self:registerEvent("draw", self.draw)
end

-------------------------------------------------------------------------------
-- Callbacks
-------------------------------------------------------------------------------

function GCSNOptionsHandler:onEnter(old_state)
    if old_state == "MODCONFIG" then
        self.selected_option = 4

        local y_off = (4 - 1) * 32
        self.menu.heart_target_x = 45
        self.menu.heart_target_y = 147 + y_off

        return
    end

    self.options = {
        domain = {self.plugconfig.domain},
        port = {tostring(self.plugconfig.port)},
    }
    self.selected_option = 1

    self.input_pos_x = 0
    self.input_pos_y = 0

    self.menu.mod_config:registerOptions()

    self:setState("MENU")

    self.menu.heart_target_x = 45
    self.menu.heart_target_y = 147
end

function GCSNOptionsHandler:onKeyPressed(key, is_repeat)
    if self.state == "MENU" then
        if Input.isCancel(key) then
            self.menu:setState("plugins")
            Assets.stopAndPlaySound("ui_move")
            return
        end

        local old = self.selected_option
        if Input.is("up"   , key)                              then self.selected_option = self.selected_option - 1  end
        if Input.is("down" , key)                              then self.selected_option = self.selected_option + 1  end
        if Input.is("left" , key) and not Input.usingGamepad() then self.selected_option = self.selected_option - 1  end
        if Input.is("right", key) and not Input.usingGamepad() then self.selected_option = self.selected_option + 1  end
        if self.selected_option > 3 then self.selected_option = is_repeat and 3 or 1    end
        if self.selected_option < 1 then self.selected_option = is_repeat and 1 or 3    end

        local y_off = (self.selected_option - 1) * 32
        if self.selected_option >= 3 then
            y_off = y_off + 32
        end

        self.menu.heart_target_x = 45
        self.menu.heart_target_y = 147 + y_off

        if old ~= self.selected_option then
            Assets.stopAndPlaySound("ui_move")
        end

        if Input.isConfirm(key) then
            if self.selected_option == 1 then
                Assets.stopAndPlaySound("ui_select")
                self:setState("DOMAIN")

            elseif self.selected_option == 2 then
                Assets.stopAndPlaySound("ui_select")
                self:setState("PORT")

            elseif self.selected_option == 3 then
                Assets.stopAndPlaySound("ui_select")
                self.menu:setState("plugins")
            end
        end

    elseif self.state == "DOMAIN" then
        if key == "escape" then
            self:onInputCancel()
            self:setState("MENU")
            Assets.stopAndPlaySound("ui_move")
            return
        end

    elseif self.state == "PORT" then
        if key == "escape" then
            self:onInputCancel()
            self:setState("MENU")
            Assets.stopAndPlaySound("ui_move")
            return
        end
    end
end

function GCSNOptionsHandler:draw()
    love.graphics.setFont(Assets.getFont("main"))
    Draw.printShadow("Gaster's Cool Social Network", 0, 48, 2, "center", 640)

    local menu_x = 64
    local menu_y = 128

    self:drawInputLine("Domain: ",          menu_x, menu_y + (32 * 0), "domain")
    self:drawInputLine("Port:   ",          menu_x, menu_y + (32 * 1), "port")
    Draw.printShadow(  "Done",          menu_x, menu_y + (32 * 3))

    local off = 256

    if TextInput.active and (self.state ~= "MENU") then
        TextInput.draw({
            x = self.input_pos_x,
            y = self.input_pos_y,
            font = Assets.getFont("main"),
            print = function(text, x, y) Draw.printShadow(text, x, y) end,
        })
    end
end

-------------------------------------------------------------------------------
-- Class Methods
-------------------------------------------------------------------------------

function GCSNOptionsHandler:setState(state, ...)
    self.state_manager:setState(state, ...)
end

function GCSNOptionsHandler:onStateChange(old_state, state)
    if state == "MENU" then
        self.menu.heart_target_x = 45
    elseif state == "DOMAIN" then
        self.menu.heart_target_x = 45 + 167
        self:openInput("domain")
    elseif state == "PORT" then
        self.menu.heart_target_x = 45 + 167
        self:openInput("port", function(letter)
            local allowed = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"}
            if not Utils.containsValue(allowed, letter) then
                return false
            end
            if letter == " "  then return "_" end
            return letter:lower()
        end)
    end
end

function GCSNOptionsHandler:onInputCancel()
    TextInput.input = {""}
    TextInput.endInput()
    self:setState("MENU")
end

function GCSNOptionsHandler:onInputSubmit(id)
    Assets.stopAndPlaySound("ui_select")
    TextInput.input = {""}
    TextInput.endInput()

    if id == "port" then
        self.plugconfig["port"] = tonumber(self.options.port[1])
    elseif id == "domain" then
        self.plugconfig["domain"] = self.options.domain[1]
    end

    Input.clear("return")

    self:setState("MENU")
end

function GCSNOptionsHandler:openInput(id, restriction)
    TextInput.attachInput(self.options[id], {
        multiline = false,
        enter_submits = true,
        clear_after_submit = false,
        text_restriction = restriction,
    })
    TextInput.submit_callback = function() self:onInputSubmit(id) end
    TextInput.text_callback = nil
end

function GCSNOptionsHandler:drawSelectionField(x, y, id, options, state)
    Draw.printShadow(options[self.options[id]], x, y)

    if self.state == state then
        Draw.setColor(COLORS.white)
        local off = (math.sin(Kristal.getTime() / 0.2) * 2) + 2
        Draw.draw(Assets.getTexture("kristal/menu_arrow_left"), x - 16 - 8 - off, y + 4, 0, 2, 2)
        Draw.draw(Assets.getTexture("kristal/menu_arrow_right"), x + 16 + 8 - 4 + off, y + 4, 0, 2, 2)
    end
end

function GCSNOptionsHandler:drawCheckbox(x, y, id)
    x = x - 8
    local checked = self.options[id]
    love.graphics.setLineWidth(2)
    Draw.setColor(COLORS.black)
    love.graphics.rectangle("line", x + 2 + 2, y + 2 + 2, 32 - 4, 32 - 4)
    Draw.setColor(checked and COLORS.white or COLORS.silver)
    love.graphics.rectangle("line", x + 2, y + 2, 32 - 4, 32 - 4)
    if checked then
        Draw.setColor(COLORS.black)
        love.graphics.rectangle("line", x + 6 + 2, y + 6 + 2, 32 - 12, 32 - 12)
        Draw.setColor(COLORS.aqua)
        love.graphics.rectangle("fill", x + 6, y + 6, 32 - 12, 32 - 12)
    end
end

function GCSNOptionsHandler:drawInputLine(name, x, y, id)
    Draw.printShadow(name, x, y)
    love.graphics.setLineWidth(2)
    local line_x  = x + 128 + 32 + 16
    local line_x2 = line_x + 416 - 32
    local line_y = 32 - 4 - 1 + 2
    Draw.setColor(0, 0, 0)
    love.graphics.line(line_x + 2, y + line_y + 2, line_x2 + 2, y + line_y + 2)
    Draw.setColor(COLORS.silver)
    love.graphics.line(line_x, y + line_y, line_x2, y + line_y)
    Draw.setColor(1, 1, 1)

    if self.options[id] ~= TextInput.input then
        Draw.printShadow(self.options[id][1], line_x, y)
    else
        self.input_pos_x = line_x
        self.input_pos_y = y
    end
end

return GCSNOptionsHandler