-- 定义 RARaid 模块表
RARaid = AceLibrary("AceAddon-2.0"):new(
    "AceEvent-2.0",      -- 事件处理
    "AceComm-2.0",       -- 插件间通信
    "AceDB-2.0",         -- 数据库 (保存配置)
    "AceDebug-2.0",      -- 调试工具
    "AceConsole-2.0",    -- 命令行接口
    "AceHook-2.1"        -- 函数钩子
)


-- 获取本地化库实例
local L = AceLibrary("AceLocale-2.2"):new("RaidAlert")

-- 存储团队成员debuff信息
RARaid.raidDebuffs = {}

-- 初始化 RAMain 模块 (由 RaidBuff:OnInitialize 调用)
function RARaid:OnInitialize()
    -- 创建 UI 框架 (如果尚未创建)

end

-- 扫描团队成员信息，更新
function RARaid:Scan(targetDebuffs)
    -- targetDebuffs: table 或 string
    local debuffList = {}
    if type(targetDebuffs) == "table" then
        for _, v in ipairs(targetDebuffs) do
            table.insert(debuffList, v)
        end
    elseif type(targetDebuffs) == "string" and targetDebuffs ~= "" then
        table.insert(debuffList, targetDebuffs)
    end

    for i = 1, GetNumRaidMembers() do
        local name = GetRaidRosterInfo(i)
        local unit = "raid"..i
        RARaid.raidDebuffs[name] = {}
        if getn(debuffList) > 0 then
            -- 检查buff
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
