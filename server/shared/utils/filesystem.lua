local StringUtils = gcsnSharedRequire("utils.string")
---@class FilesystemUtils
local FilesystemUtils = {}

---@param file love.File
function FilesystemUtils.parseCSVWithHeader(file)
    local nextLine = file:lines() ---@type fun():string
    local header = nextLine()
    local separator = ","
    if header:find("\t") then
        separator = "\t"
    end
    local fields = StringUtils.split(header, separator)
    local entries = {}
    for line in nextLine do
        local split = StringUtils.split(line, separator)
        local entry = {}
        for i = 1, #fields do
            local str = (split[i] or "") ---@type string
            local value = str ---@type string|number
            if value:sub(1,2) == "0x" then
                value = tonumber(value:sub(3), 16) or value
            end
            value = tonumber(value) or value
            entry[fields[i]] = value
        end
        table.insert(entries, entry)
        while line and line:sub(1,1) == "#" do
            line = nextLine()
        end
    end
    return entries
end

return FilesystemUtils