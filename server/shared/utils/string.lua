---@class StringUtils
local StringUtils = {}

function StringUtils.sub(input, from, to)
    if (from == nil) then
        from = 1
    end

    if (to == nil) then
        to = -1
    end

    if from < 1 or to < 1 then
        local length = Utils.len(input)
        if not length then error("Invalid UTF-8 string.") end
        if from < 0 then from = length + 1 + from end
        if to < 0 then to = length + 1 + to end
        if from < 0 then from = 1 end
        if to < 0 then to = 1 end
        if to < from then return "" end
        if from > length then from = length end
        if to > length then to = length end
    end

    if to < from then
        return ""
    end

    local offset_from = utf8.offset(input, from) --[[@as integer?]]
    local offset_to = utf8.offset(input, to + 1) --[[@as integer?]]

    if offset_from and offset_to then
        return string.sub(input, offset_from, offset_to - 1)
    elseif offset_from then
        return string.sub(input, offset_from)
    else
        return ""
    end
end

function StringUtils.split(str, sep, remove_empty)
    local t = {}
    local i = 1
    local s = ""
    -- Loop through each character in the string.
    while i <= utf8.len(str) do
        -- If the current character matches the separator, add the
        -- current string to the table, and reset the current string.
        if StringUtils.sub(str, i, i + (utf8.len(sep) - 1)) == sep then
            -- If the string is empty, and empty strings shouldn't be included, skip it.
            if not remove_empty or s ~= "" then
                table.insert(t, s)
            end
            s = ""
            -- Skip the separator.
            i = i + (#sep - 1)
        else
            -- Add the character to the current string.
            s = s .. StringUtils.sub(str, i, i)
        end
        i = i + 1
    end
    -- Add the last string to the table.
    if not remove_empty or s ~= "" then
        table.insert(t, s)
    end
    return t
end

return StringUtils
