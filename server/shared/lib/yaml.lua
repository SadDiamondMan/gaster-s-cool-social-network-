-- yaml.lua v0.1
-- https://github.com/rogvc/lua-yaml

local yaml = {
    __license = [[
MIT License

Copyright (c) 2025 Rogerio Cruz

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.]]
-- I had to manually add the license here lol -hyperboid
}

-- Helper function to convert value types
local function convert_value(value)
    if value == "true" then
        return true
    elseif value == "false" then
        return false
    elseif tonumber(value) then
        return tonumber(value)
    else
        return value
    end
end

-- Recursive function to parse YAML content
local function parse_yaml(lines, indent_level, start_index)
    local data = {}
    local i = start_index or 1

    while i <= #lines do
        local line = lines[i]

        -- Skip comments and empty lines
        if line:match("^#") or line:match("^%s*$") then
            i = i + 1
        else
            -- Determine the current line's indentation level
            local indent = line:match("^(%s*)")
            local current_indent_level = #indent / 2

            if current_indent_level < indent_level then
                -- End of current indentation level, return to previous level
                return data, i
            end

            -- Handle sequence items
            if line:match("^%s*-%s*(.*)%s*$") then
                local item = line:match("^%s*-%s*(.*)%s*$")
                local sub_data = {}

                -- Check if the item itself is a key-value pair
                local sub_key, sub_value = item:match("^%s*([^:]+)%s*:%s*(.*)%s*$")
                if sub_key then
                    sub_value = convert_value(sub_value)
                    sub_data[sub_key] = sub_value

                    -- Parse nested items
                    local nested_data, next_i = parse_yaml(lines, current_indent_level + 1, i + 1)
                    if next_i > i then
                        for k, v in pairs(nested_data) do
                            sub_data[k] = v
                        end
                        i = next_i
                    else
                        i = i + 1
                    end
                    table.insert(data, sub_data)
                else
                    item = convert_value(item)

                    -- Parse nested items
                    local nested_data, next_i = parse_yaml(lines, current_indent_level + 1, i + 1)
                    if next_i > i then
                        table.insert(data, nested_data)
                        i = next_i
                    else
                        table.insert(data, item)
                        i = i + 1
                    end
                end
            else
                -- Handle key-value pairs
                local key, value = line:match("^%s*([^:]+)%s*:%s*(.*)%s*$")
                if key then
                    value = convert_value(value)

                    if value == "" then
                        -- If the value is empty, it might be a nested table or sequence
                        local sub_data, next_i = parse_yaml(lines, current_indent_level + 1, i + 1)
                        data[key] = sub_data
                        i = next_i
                    else
                        data[key] = value
                        i = i + 1
                    end
                else
                    i = i + 1
                end
            end
        end
    end

    return data, i
end

-- Function to parse the entire YAML file
function yaml.parseFile(file_path)
    local file, err = io.open(file_path, "r")
    if not file then
        return nil, "File not found: " .. err
    end

    local yaml_str = file:read("*all")
    file:close()

    return yaml.parseString(yaml_str)

end

function yaml.parseString(yaml_str)
    -- Split the file content into lines
    local lines = {}
    for line in yaml_str:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end

    return yaml.parseLines(lines)

end

function yaml.parseLines(lines)
    
    -- Parse the YAML content starting from the top level
    local data, _ = parse_yaml(lines, 0, 1)

    return data
end

return yaml
