-- RARaid 模块定义，负责团队成员debuff扫描与记录
RARaid = AceLibrary("AceAddon-2.0"):new(
    "AceEvent-2.0",    -- 事件处理
    "AceComm-2.0",     -- 通信
    "AceDB-2.0",       -- 数据库
    "AceDebug-2.0",    -- 调试
    "AceConsole-2.0",  -- 命令行
    "AceHook-2.1"      -- 钩子
)

-- 获取本地化库实例
local L = AceLibrary("AceLocale-2.2"):new("RaidAlert")

-- 存储团队成员debuff信息，结构: [玩家名] = {debuff1, debuff2, ...}
RARaid.raidDebuffs = {}

-- 初始化 RARaid 模块（预留，当前未用）
function RARaid:OnInitialize()
    -- 创建 UI 框架 (如果尚未创建)
end

-- 扫描团队成员，检测是否中了指定debuff
-- targetDebuffs: 目标debuff名称（字符串或表）
function RARaid:Scan(targetDebuffs)
    local debuffList = {}
    -- 统一转换为表
    if type(targetDebuffs) == "table" then
        for _, v in ipairs(targetDebuffs) do
            table.insert(debuffList, v)
        end
    elseif type(targetDebuffs) == "string" and targetDebuffs ~= "" then
        table.insert(debuffList, targetDebuffs)
    end

    -- 遍历团队成员
    for i = 1, GetNumRaidMembers() do
        local name = GetRaidRosterInfo(i)
        local unit = "raid" .. i
        RARaid.raidDebuffs[name] = {}
        if getn(debuffList) > 0 then
            -- 检查buff（部分debuff也可能以buff形式存在）
            for _, debuffName in ipairs(debuffList) do
                if IsBuffActive(debuffName, unit) then
                    table.insert(RARaid.raidDebuffs[name], debuffName)
                end
            end
            -- 检查debuff
            local j = 1
            while true do
                local debuffName = UnitDebuff(unit, j)
                if not debuffName then break end
                for _, targetDebuff in ipairs(debuffList) do
                    if debuffName == targetDebuff then
                        table.insert(RARaid.raidDebuffs[name], debuffName)
                    end
                end
                j = j + 1
            end
        else
            RARaid.raidDebuffs[name] = {}
        end
    end
end
