local buffer = require("string.buffer")
local StringUtils = require("server.utils.string")
---@class Logger: Class
local Logger, super = class("Logger")

Logger.FG_COLOR_PATTERN = "\x1b[38;2;%d;%d;%dm"
Logger.BG_COLOR_PATTERN = "\x1b[38;2;%d;%d;%dm"

function Logger:init(name, options)
    self.name = name
end

---@param message string
function Logger:_write(message, severity)
    local format_message = ("[%s] [%s] %s"):format(self.name, severity, message)
    local term_message = buffer.new(#format_message)
    local text = {}
    local current = ""
    local in_modifier = false
    local modifier_text = ""
    --- Basically stolen from Kristal's Console:push
    for char in format_message:gmatch(utf8.charpattern) do
        if char == "[" then
            table.insert(text, current)
            current = ""
            in_modifier = true
        elseif char == "]" and in_modifier then
            current = ""
            in_modifier = false
            local modifier = StringUtils.split(modifier_text, ":", false)
            if modifier[1] == "color" then
                local color = {1.0, 1.0, 1.0, 1.0}
                if modifier[2] then
                    if modifier[2]:sub(1,1) == "#" then
                        local hex = modifier[2]
                        color = {tonumber(string.sub(hex, 2, 3), 16)/255, tonumber(string.sub(hex, 4, 5), 16)/255, tonumber(string.sub(hex, 6, 7), 16)/255, 1}
                    elseif modifier[2] == "cyan" then
                        color = {0.5, 1, 1, 1}
                    elseif modifier[2] == "white" then
                        color = {1, 1, 1, 1}
                    elseif modifier[2] == "yellow" then
                        color = {1, 1, 0.5, 1}
                    elseif modifier[2] == "red" then
                        color = {1, 0.5, 0.5, 1}
                    elseif modifier[2] == "gray" then
                        color = {0.8, 0.8, 0.8, 1}
                    end
                end
                table.insert(text, color)
                local r,g,b = color[1]*255, color[2]*255, color[3]*255
                term_message:put(string.format(Logger.FG_COLOR_PATTERN,r,g,b))
            else
                modifier_text = "[" .. modifier_text .. "]"
                term_message:put(modifier_text)
                table.insert(text, modifier_text)
            end
            modifier_text = ""
        elseif in_modifier then
            modifier_text = modifier_text .. char
        else
            current = current .. char
            term_message:put(char)
        end
    end
    term_message:put("\n\x1b[0m")
    io.stdout:write(term_message)
    io.stdout:flush()
end

---@param message string
---@param ... any
function Logger:debug(message, ...)
    message = string.format(message, ...)
    self:_write(message, "DEBUG")
end

---@param message string
---@param ... any
function Logger:info(message, ...)
    message = string.format(message, ...)
    self:_write(message, "INFO")
end

---@param message string
---@param ... any
function Logger:error(message, ...)
    message = string.format(message, ...)
    self:_write(message, "ERROR")
end

return Logger