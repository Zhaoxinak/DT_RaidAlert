-- 数字补零（个位数前补0）
function DV_FixZero(num)
    return num < 10 and "0" .. num or tostring(num)
end

-- 获取当前日期时间字符串（格式: yy-mm-dd hh:mm:ss）
function DV_Date()
    local t = date("*t")
    return strsub(t.year, 3) .. "-" .. DV_FixZero(t.month) .. "-" .. DV_FixZero(t.day)
        .. " " .. DV_FixZero(t.hour) .. ":" .. DV_FixZero(t.min) .. ":" .. DV_FixZero(t.sec)
end

-- 将表序列化为字符串（递归支持嵌套表）
function tableToString(tbl)
    local function serialize(value)
        if type(value) == "table" then
            return tableToString(value)
        elseif type(value) == "string" then
            return "'" .. string.gsub(value, "'", "\\'") .. "'"
        else
            return tostring(value)
        end
    end
    local entries = {}
    for k, v in pairs(tbl) do
        local escapedK = string.gsub(k, "'", "\\'")
        table.insert(entries, string.format("['%s'] = %s", escapedK, serialize(v)))
    end
    return "{" .. table.concat(entries, ", ") .. "}"
end

-- 将字符串反序列化为表（支持嵌套）
function stringToTable(s)
    local function deserialize(value)
        if string.sub(value, 1, 1) == "{" and string.sub(value, -1) == "}" then
            return stringToTable(value)
        elseif string.sub(value, 1, 1) == "'" and string.sub(value, -1) == "'" then
            return string.gsub(string.sub(value, 2, -2), "\\'", "'")
        else
            return tonumber(value) or value
        end
    end
    local t = {}
    local entries = string.match(s, "{(.*)}")
    for k, v in string.gmatch(entries, "%['(.-)'%] = ([^,]+)") do
        local key = string.gsub(k, "\\'", "'")
        t[key] = deserialize(v)
    end
    return t
end

-- 检查列表中是否包含指定元素
function contains(list, value)
    if not list then return false end
    for _, v in ipairs(list) do
        if v == value then return true end
    end
    return false
end

-- 检查表中是否包含某个值（仅遍历数组部分）
function tableContainsValue(tbl, item)
    if not tbl then return false end
    for _, value in ipairs(tbl) do
        if value == item then return true end
    end
    return false
end

-- 检查表中是否包含某个键
function tableContainsKey(tbl, key)
    if not tbl then return false end
    return tbl[key] ~= nil
end

-- 获取表的大小（键值对数量）
function getTableSize(tbl)
    if not tbl then return 0 end
    local size = 0
    for _ in pairs(tbl) do
        size = size + 1
    end
    return size
end
