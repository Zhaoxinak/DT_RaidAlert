function DV_FixZero(num)
    if (num < 10) then
        return "0" .. num;
    else
        return num;
    end
end

function DV_Date()
    local t = date("*t");

    return strsub(t.year, 3) ..
        "-" ..
        DV_FixZero(t.month) ..
        "-" .. DV_FixZero(t.day) .. " " .. DV_FixZero(t.hour) .. ":" .. DV_FixZero(t.min) .. ":" .. DV_FixZero(t.sec);
end

function tableToString(t)
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
    for k, v in pairs(t) do
        local escapedK = string.gsub(k, "'", "\\'")
        table.insert(entries, string.format("['%s'] = %s", escapedK, serialize(v)))
    end
    return "{" .. table.concat(entries, ", ") .. "}"
end

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
function contain(v, l)
    if not l then
        return false
    end
    local n = getn(l)
    if n > 0 then
        for i = 1, n do
            local lv = l[i]
            if v == lv then
                return true
            end
        end
    end
    return false
end

-- 检查 Lua 表 (数组形式) 中是否包含某个值
-- tbl: 要检查的表
-- item: 要查找的值
-- 返回: true 或 false
function tableContainsValue(tbl, item)
    if not tbl then return false end
    for _, value in ipairs(tbl) do
        if value == item then
            return true
        end
    end
    return false
end

-- 检查 Lua 表中是否包含某个键
-- tbl: 要检查的表
-- key: 要查找的键
-- 返回: true 或 false
function tableContainsKey(tbl, key)
    if not tbl then return false end
    return tbl[key] ~= nil
end

-- 获取 Lua 表的大小 (适用于包含非数字键的表)
-- tbl: 要计算大小的表
-- 返回: 键值对的数量
function getTableSize(tbl)
    if not tbl then return 0 end
    local size = 0
    for _ in pairs(tbl) do
        size = size + 1
    end
    return size
end
