---@class ClassSystem
---@field CLASS_MT metatable
local ClassSystem = {}

ClassSystem.CLASS_MT = {
    __call = function (class, ...)
        local t = {}
        setmetatable(t, class)
        if not t.init then
            error("Class "..class.classname.." has no init somehow")
        end
        t:init(...)
        return t
    end,
}

---@class Class
ClassSystem.BASE_CLASS = {}

ClassSystem.CLASS_INCLUDE_SKIP_FIELDS = {
    ["classname"] = true,
}

function ClassSystem.BASE_CLASS:init() end

---@param classname string
---@param include table?
---@param newclass table?
function ClassSystem.new(classname, include, newclass)
    newclass = newclass or {}
    include = include or ClassSystem.BASE_CLASS
    for key, value in pairs(include) do
        if newclass[key] == nil and not ClassSystem.CLASS_INCLUDE_SKIP_FIELDS[key] then
            newclass[key] = value
        end
    end
    newclass.classname = classname
    newclass.__index = newclass
    setmetatable(newclass, ClassSystem.CLASS_MT)
    return newclass, include
end

---@diagnostic disable-next-line: lowercase-global
class = ClassSystem.new

-- Kristal class function, for classes shared between client and server
function Class(include, classname)
    return ClassSystem.new(classname, include)
end

return ClassSystem
