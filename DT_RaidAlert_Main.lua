local BASE_FRAME_HEIGHT = 200 -- 主框架基础高度

local statsFrame
local searchBox
local statsText
local cooldownSlider
-- 定时检测事件名
local DEBUFF_CHECK_EVENT = "RA_DebuffCheckEvent"
local currentDebuffName = nil

-- 定义 RAMain 模块表
RAMain = AceLibrary("AceAddon-2.0"):new(
    "AceEvent-2.0",      -- 事件处理
    "AceComm-2.0",       -- 插件间通信
    "AceDB-2.0",         -- 数据库 (保存配置)
    "AceDebug-2.0",      -- 调试工具
    "AceConsole-2.0",    -- 命令行接口
    "AceHook-2.1"        -- 函数钩子
)

-- 获取本地化库实例
local L = AceLibrary("AceLocale-2.2"):new("RaidAlert")

-- 私聊冷却表
local whisperCooldowns = {}

-- 初始化 RAMain 模块 (由 RaidBuff:OnInitialize 调用)
function RAMain:OnInitialize()
    -- 创建 UI 框架 (如果尚未创建)
    if not self.mf then self:SetUpMainFrame() end -- 主分配界面
end

-- 创建主分配界面 (mf: main frame)
function RAMain:SetUpMainFrame()
    if self.mf then return end -- 防止重复创建

    local f = CreateFrame("Frame", "RAMainFrame", UIParent)
    f:SetWidth(600)                                            -- 初始宽度，会动态调整
    f:SetHeight(BASE_FRAME_HEIGHT)                             -- 初始高度，会动态调整
    f:SetBackdrop({
        bgFile = "Interface\\RaidFrame\\UI-RaidFrame-GroupBg", -- 背景贴图
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",   -- 边框贴图
        edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }  -- 内边距
    })
    f:SetAlpha(0.7)                                            -- 透明度
    f:SetFrameStrata("LOW")                                    -- 框架层级

    -- 设置初始位置并允许拖动
    f:ClearAllPoints()
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0) -- 默认居中
    f:EnableMouse(true)
    f:SetClampedToScreen(true)                     -- 限制在屏幕内
    f:RegisterForDrag("LeftButton")
    f:SetMovable(true)
    f:SetScript("OnDragStart", function() f:StartMoving() end)
    f:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
    end)

    -- === 创建界面元素 ===
    f.textures = {} -- 存储纹理
    f.fontStrs = {} -- 存储字体串
    f.buttons = {}  -- 存储按钮

    -- --- 顶部标题栏 ---
    local headerTexture = f:CreateTexture(nil, "ARTWORK")
    headerTexture:SetTexture("Interface\\QuestFrame\\UI-HorizontalBreak") -- 水平分割线纹理
    headerTexture:SetPoint("TOP", f, "TOP", 0, -10)
    f.textures["head"] = headerTexture

    local headerText = f:CreateFontString(nil, "OVERLAY")
    headerText:SetFontObject("GameFontNormal")
    headerText:SetPoint("TOP", f, "TOP", 0, -10)
    headerText:SetText(L["标题"]) -- 使用本地化标题
    f.fontStrs["head"] = headerText

    local headerLine = f:CreateTexture(nil, "ARTWORK")
    headerLine:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-BarFill") -- 细线纹理
    headerLine:SetWidth(f:GetWidth() - 10)                                        -- 动态宽度
    headerLine:SetHeight(4)
    headerLine:SetPoint("BOTTOM", headerTexture, "BOTTOM", 0, 0)
    f.textures["headLine"] = headerLine

    -- 关闭按钮
    local closeButton = CreateFrame("Button", "RAMainCloseButton", f, "UIPanelCloseButton") -- 使用标准关闭按钮模板
    closeButton:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -7)
    closeButton:SetScript("OnClick", function() f:Hide() end)
    f.buttons["closeButton"] = closeButton

    -- 添加统计数据展示区域
    statsFrame = CreateFrame("Frame", "RAStatsFrame", f)
    statsFrame:SetPoint("TOP", headerLine, "BOTTOM", 0, -10)
    statsFrame:SetWidth(f:GetWidth() - 20)
    statsFrame:SetHeight(50)

    statsText = statsFrame:CreateFontString(nil, "OVERLAY")
    statsText:SetFontObject("GameFontNormal")
    statsText:SetPoint("LEFT", statsFrame, "LEFT", 10, 0)
    statsText:SetText(L["当前状态:"])
    statsFrame.text = statsText


    -- 队伍标题下的水平分割线
    local titleLine = f:CreateTexture(nil, "ARTWORK")
    titleLine:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-BarFill")
    titleLine:SetWidth(f:GetWidth() - 10) -- 动态宽度
    titleLine:SetHeight(4)
    titleLine:SetPoint("TOPLEFT", statsText, "BOTTOMLEFT", 4, 0)
    f.textures["titleLine"] = titleLine


    -- 创建搜索框
    searchBox = CreateFrame("EditBox", nil, f,
        "InputBoxTemplate")
    searchBox:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 10)
    searchBox:SetWidth(200)
    searchBox:SetHeight(30)
    searchBox:SetAutoFocus(false)
    searchBox:SetText(L["输入debuff名称"])

    -- 创建查询按钮
    local searchButton = CreateFrame("Button", nil, f,
        "UIPanelButtonTemplate")
    searchButton:SetPoint("LEFT", searchBox, "RIGHT", 10, 0)
    searchButton:SetWidth(80)
    searchButton:SetHeight(30)
    searchButton:SetText(L["开启检测"])
    searchButton:SetScript("OnClick", function()
        local query = searchBox:GetText()
        RAMain:UpdateCheckDebuff(query)
    end)

    -- 重置查询按钮
    local resetButton = CreateFrame("Button", nil, f,
        "UIPanelButtonTemplate")
    resetButton:SetPoint("LEFT", searchButton, "RIGHT", 10, 0)
    resetButton:SetWidth(80)
    resetButton:SetHeight(30)
    resetButton:SetText(L["停止"])
    resetButton:SetScript("OnClick", function()
        RAMain:UpdateCheckDebuff()
    end)

    -- 关闭按钮
    closeButton = CreateFrame("Button", nil, f,
        "UIPanelButtonTemplate")
    closeButton:SetPoint("LEFT", resetButton, "RIGHT", 10, 0)
    closeButton:SetWidth(80)
    closeButton:SetHeight(30)
    closeButton:SetText(L["关闭"])
    closeButton:SetScript("OnClick", function()
        RAMain:UpdateCheckDebuff()
        f:Hide()
    end)

    -- 添加冷却时间滑块
    cooldownSlider = CreateFrame("Slider", "RAStatsCooldownSlider", f, "OptionsSliderTemplate")
    cooldownSlider:SetOrientation("HORIZONTAL")
    cooldownSlider:SetWidth(180)
    cooldownSlider:SetHeight(20)
    cooldownSlider:SetPoint("BOTTOMLEFT", searchBox, "TOPLEFT", 0, 20)
    cooldownSlider:SetMinMaxValues(1, 60)
    cooldownSlider:SetValueStep(1)
    cooldownSlider:SetValue(RaidAlert and RaidAlert.notificationCooldownSeconds or 15)
    cooldownSlider:SetScript("OnValueChanged", function()
        if RaidAlert then
            RaidAlert.notificationCooldownSeconds = arg1
        end
        _G[cooldownSlider:GetName() .. 'Text']:SetText(L["通知间隔:"] .. " " .. arg1 .. L["秒"])
    end)
    _G[cooldownSlider:GetName() .. 'Low']:SetText("1")
    _G[cooldownSlider:GetName() .. 'High']:SetText("60")
    _G[cooldownSlider:GetName() .. 'Text']:SetText(L["通知间隔:"] .. " " .. cooldownSlider:GetValue() .. L["秒"])

    f:Hide()
    self.mf = f -- 将创建好的框架赋值给 self.mf

end

function RAMain:UpdateCheckDebuff(debuffName)
    -- 停止旧的检测
    self:CancelScheduledEvent(DEBUFF_CHECK_EVENT)
    currentDebuffName = nil

    if not debuffName or debuffName == "" or debuffName == L["输入debuff名称"] then
        self:UpdateStats(false, nil)
        return
    end

    currentDebuffName = debuffName
    -- 使用 AceEvent 的定时器，每秒检测一次
    self:ScheduleRepeatingEvent(DEBUFF_CHECK_EVENT, function()
        RARaid:Scan(currentDebuffName)
        RAMain:CheckAndWhisper(currentDebuffName)
    end, 1)

    self:UpdateStats(true, debuffName)
end

function RAMain:CheckAndWhisper(debuffName)
    for name, debuffs in pairs(RARaid.raidDebuffs) do
        local hasDebuff = false
        for _, d in ipairs(debuffs) do
            if d == debuffName then
                hasDebuff = true
                break
            end
        end
        if hasDebuff then
            local now = GetTime()
            if not whisperCooldowns[name] or now - whisperCooldowns[name] > RaidAlert.notificationCooldownSeconds then
                SendChatMessage("你中了debuff: "..debuffName .. "  (时间: " .. DV_Date() .. ")", "WHISPER", nil, name)
                whisperCooldowns[name] = now
            end
        end
    end
end

-- 更新统计数据
function RAMain:UpdateStats(isOpen, debuffName)

    local open = L["未检测"]
    if isOpen == true then
        open = L["正在检测"]
    else
        open = L["未检测"]
    end

    statsText:SetText(string.format(L["当前状态: %s, 当前检测名称: %s"], open, debuffName or L["无"]))
    statsFrame.text = statsText
end

-- 注册监听聊天事件
function RAMain:RegisterChatEvents()
    self:RegisterEvent("CHAT_MSG_RAID", "HandleChatMessage")
    self:RegisterEvent("CHAT_MSG_RAID_LEADER", "HandleChatMessage")
    self:RegisterEvent("CHAT_MSG_SYSTEM", "HandleChatMessage")

end

function RAMain:HandleChatMessage(msg, sender)
    -- 这里可以根据需要处理聊天消息
    DEFAULT_CHAT_FRAME:AddMessage("收到聊天消息: " .. tostring(msg) .. " 来自: " .. tostring(sender))
    if msg == "你加入了一个团队。" then
    end
end
