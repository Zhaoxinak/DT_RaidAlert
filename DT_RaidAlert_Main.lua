-- 主界面相关常量
local FRAME_HEIGHT = 180      -- 主界面高度
local FRAME_WIDTH = 400       -- 主界面宽度

-- 主界面及其控件引用
local statsFrame, searchBox, statsText, cooldownSlider
local miniButton, miniButtonDragFrame

-- 定时检测事件名
local DEBUFF_CHECK_EVENT = "RA_DebuffCheckEvent"
local activeDebuffNames = nil -- 当前激活的debuff名称列表

-- RAMain 模块定义，继承 Ace2 多个库
RAMain = AceLibrary("AceAddon-2.0"):new(
    "AceEvent-2.0",    -- 事件处理
    "AceComm-2.0",     -- 通信
    "AceDB-2.0",       -- 数据库
    "AceDebug-2.0",    -- 调试
    "AceConsole-2.0",  -- 命令行
    "AceHook-2.1"      -- 钩子
)

-- 获取本地化库实例
local L = AceLibrary("AceLocale-2.2"):new("RaidAlert")
local whisperCooldowns = {} -- 记录每个玩家上次提醒时间，防止刷屏

-- 插件初始化，创建主界面
function RAMain:OnInitialize()
    if not self.mainFrame then self:CreateMainFrame() end
end

-- 创建主界面及其所有控件
function RAMain:CreateMainFrame()
    if self.mainFrame then return end -- 已创建则跳过

    -- 创建主Frame
    local frame = CreateFrame("Frame", "RAMainFrame", UIParent)
    frame:SetWidth(FRAME_WIDTH)
    frame:SetHeight(FRAME_HEIGHT)
    frame:SetBackdrop({
        bgFile = "Interface\\RaidFrame\\UI-RaidFrame-GroupBg",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    frame:SetAlpha(0.7)
    frame:SetFrameStrata("MEDIUM")
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetMovable(true)
    frame:SetScript("OnDragStart", function() frame:StartMoving() end)
    frame:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)

    -- 存储控件引用
    frame.textures, frame.fontStrs, frame.buttons = {}, {}, {}

    -- 标题栏纹理
    local headerTex = frame:CreateTexture(nil, "ARTWORK")
    headerTex:SetTexture("Interface\\QuestFrame\\UI-HorizontalBreak")
    headerTex:SetPoint("TOP", frame, "TOP", 0, -10)
    frame.textures["header"] = headerTex

    -- 标题文字
    local headerText = frame:CreateFontString(nil, "OVERLAY")
    headerText:SetFontObject("GameFontNormal")
    headerText:SetPoint("TOP", frame, "TOP", 0, -10)
    headerText:SetText(L["标题"])
    frame.fontStrs["header"] = headerText

    -- 标题下分割线
    local headerLine = frame:CreateTexture(nil, "ARTWORK")
    headerLine:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-BarFill")
    headerLine:SetWidth(frame:GetWidth() - 10)
    headerLine:SetHeight(4)
    headerLine:SetPoint("BOTTOM", headerTex, "BOTTOM", 0, 0)
    frame.textures["headerLine"] = headerLine

    -- 关闭按钮（右上角）
    local closeBtn = CreateFrame("Button", "RAMainCloseButton", frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -7)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)
    frame.buttons["close"] = closeBtn

    -- 统计区域Frame
    statsFrame = CreateFrame("Frame", "RAStatsFrame", frame)
    statsFrame:SetPoint("TOP", headerLine, "BOTTOM", 0, 0)
    statsFrame:SetWidth(frame:GetWidth() - 10)
    statsFrame:SetHeight(50)

    -- 统计区域文字
    statsText = statsFrame:CreateFontString(nil, "OVERLAY")
    statsText:SetFontObject("GameFontNormal")
    statsText:SetPoint("LEFT", statsFrame, "LEFT", 2, 0)
    statsText:SetText(L["当前状态:"])
    statsFrame.text = statsText

    -- 统计区域下分割线
    local titleLine = frame:CreateTexture(nil, "ARTWORK")
    titleLine:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-BarFill")
    titleLine:SetWidth(frame:GetWidth() - 10)
    titleLine:SetHeight(4)
    titleLine:SetPoint("TOPLEFT", statsText, "BOTTOMLEFT", 0, 2)
    frame.textures["titleLine"] = titleLine

    -- 搜索框（输入debuff名称）
    searchBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    searchBox:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 5)
    searchBox:SetWidth(150)
    searchBox:SetHeight(30)
    searchBox:SetAutoFocus(false)
    searchBox:SetText(L["输入debuff名称"])

    -- 查询按钮（开启检测）
    local searchBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    searchBtn:SetPoint("LEFT", searchBox, "RIGHT", 5, 0)
    searchBtn:SetWidth(70)
    searchBtn:SetHeight(30)
    searchBtn:SetText(L["开启检测"])
    searchBtn:SetScript("OnClick", function()
        local query = searchBox:GetText()
        RAMain:StartDebuffCheck(query)
        searchBox:ClearFocus()
    end)

    -- 停止按钮
    local stopBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    stopBtn:SetPoint("LEFT", searchBtn, "RIGHT", 5, 0)
    stopBtn:SetWidth(60)
    stopBtn:SetHeight(30)
    stopBtn:SetText(L["停止"])
    stopBtn:SetScript("OnClick", function()
        RAMain:StartDebuffCheck()
    end)

    -- 关闭按钮（隐藏界面）
    local hideBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    hideBtn:SetPoint("LEFT", stopBtn, "RIGHT", 10, 0)
    hideBtn:SetWidth(60)
    hideBtn:SetHeight(30)
    hideBtn:SetText(L["关闭"])
    hideBtn:SetScript("OnClick", function()
        RAMain:StartDebuffCheck()
        frame:Hide()
    end)

    -- 冷却时间滑块（设置通知间隔）
    cooldownSlider = CreateFrame("Slider", "RAStatsCooldownSlider", frame, "OptionsSliderTemplate")
    cooldownSlider:SetOrientation("HORIZONTAL")
    cooldownSlider:SetWidth(180)
    cooldownSlider:SetHeight(20)
    cooldownSlider:SetPoint("BOTTOMLEFT", searchBox, "TOPLEFT", 0, 20)
    cooldownSlider:SetMinMaxValues(1, 60)
    cooldownSlider:SetValueStep(1)
    cooldownSlider:SetValue(RaidAlert and RaidAlert.notificationCooldownSeconds or 15)
    cooldownSlider:SetScript("OnValueChanged", function()
        -- arg1为当前滑块值
        if RaidAlert then
            RaidAlert.notificationCooldownSeconds = arg1
        end
        _G[cooldownSlider:GetName() .. 'Text']:SetText(L["通知间隔:"] .. " " .. arg1 .. L["秒"])
    end)
    _G[cooldownSlider:GetName() .. 'Low']:SetText("1")
    _G[cooldownSlider:GetName() .. 'High']:SetText("60")
    _G[cooldownSlider:GetName() .. 'Text']:SetText(L["通知间隔:"] .. " " .. cooldownSlider:GetValue() .. L["秒"])

    -- 缩小按钮（主界面变为小按钮）
    local minimizeBtn = CreateFrame("Button", "RAMainMinimizeButton", frame, "UIPanelButtonTemplate")
    minimizeBtn:SetPoint("RIGHT", closeBtn, "LEFT", -5, 0)
    minimizeBtn:SetWidth(60)
    minimizeBtn:SetHeight(30)
    minimizeBtn:SetText(L["缩小"])
    minimizeBtn:SetScript("OnClick", function()
        -- 记录当前主界面位置，将小按钮放到同一位置
        local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
        if miniButtonDragFrame then
            miniButtonDragFrame:ClearAllPoints()
            miniButtonDragFrame:SetPoint(point or "CENTER", relativeTo or UIParent, relativePoint or "CENTER", xOfs or 0, yOfs or 0)
            miniButtonDragFrame:Show()
        end
        frame:Hide()
    end)
    frame.buttons["minimize"] = minimizeBtn

    frame:Hide()
    self.mainFrame = frame

    -- 小按钮外层Frame（用于缩小模式）
    if not miniButton then
        miniButtonDragFrame = CreateFrame("Frame", "RAMainMiniButtonDragFrame", UIParent)
        miniButtonDragFrame:SetWidth(90)
        miniButtonDragFrame:SetHeight(50)
        miniButtonDragFrame:SetMovable(true)
        miniButtonDragFrame:EnableMouse(true)
        miniButtonDragFrame:RegisterForDrag("LeftButton")
        miniButtonDragFrame:SetClampedToScreen(true)
        miniButtonDragFrame:SetScript("OnDragStart", function() miniButtonDragFrame:StartMoving() end)
        miniButtonDragFrame:SetScript("OnDragStop", function() miniButtonDragFrame:StopMovingOrSizing() end)
        miniButtonDragFrame:Hide()
        miniButtonDragFrame:SetBackdrop({
            bgFile = "Interface\\RaidFrame\\UI-RaidFrame-GroupBg",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 16,
            insets = { left = 5, right = 5, top = 5, bottom = 5 }
        })
        miniButtonDragFrame:SetAlpha(0.7)
        miniButtonDragFrame:SetFrameStrata("MEDIUM")

        -- 小按钮本体
        miniButton = CreateFrame("Button", "RAMainMiniButton", miniButtonDragFrame, "UIPanelButtonTemplate")
        miniButton:SetWidth(70)
        miniButton:SetHeight(30)
        miniButton:SetText(L["检测还原"])
        miniButton:SetPoint("CENTER", miniButtonDragFrame, "CENTER", 0, 0)
        miniButton:SetScript("OnClick", function()
            if self.mainFrame then self.mainFrame:Show() end
            miniButtonDragFrame:Hide()
        end)
        self.miniButtonDragFrame = miniButtonDragFrame
    end
end

-- 开始或停止debuff检测
-- debuffInput: 用户输入的debuff名称（可多个，用/分隔）
function RAMain:StartDebuffCheck(debuffInput)
    self:CancelScheduledEvent(DEBUFF_CHECK_EVENT) -- 取消之前的定时检测
    activeDebuffNames = nil

    -- 未输入或输入为空，停止检测
    if not debuffInput or debuffInput == "" or debuffInput == L["输入debuff名称"] then
        self:UpdateStats(false, nil)
        return
    end

    -- 解析输入，支持多个debuff（用/分隔）
    local debuffList = {}
    for name in string.gmatch(debuffInput, "([^/]+)") do
        name = strtrim(name)
        if name ~= "" then
            table.insert(debuffList, name)
        end
    end
    if getn(debuffList) == 0 then
        self:UpdateStats(false, nil)
        return
    end
    activeDebuffNames = debuffList

    -- 定时检测，每秒扫描一次
    self:ScheduleRepeatingEvent(DEBUFF_CHECK_EVENT, function()
        RARaid:Scan(activeDebuffNames)
        RAMain:NotifyDebuffedPlayers(activeDebuffNames)
    end, 1)

    self:UpdateStats(true, table.concat(debuffList, " / "))
end

-- 检查团队成员是否中了指定debuff，并私聊提醒
function RAMain:NotifyDebuffedPlayers(debuffNames)
    if type(debuffNames) == "string" then
        debuffNames = { debuffNames }
    end
    for playerName, debuffs in pairs(RARaid.raidDebuffs) do
        local matchedDebuff = nil
        -- 检查该玩家是否中了目标debuff
        for _, debuff in ipairs(debuffs) do
            for _, targetDebuff in ipairs(debuffNames) do
                if debuff == targetDebuff then
                    matchedDebuff = targetDebuff
                    break
                end
            end
            if matchedDebuff then break end
        end
        if matchedDebuff then
            local now = GetTime()
            -- 冷却时间内不重复提醒
            if not whisperCooldowns[playerName] or now - whisperCooldowns[playerName] > RaidAlert.notificationCooldownSeconds then
                SendChatMessage("你中了debuff: "..matchedDebuff .. "  (时间: " .. DV_Date() .. ")", "WHISPER", nil, playerName)
                whisperCooldowns[playerName] = now
                -- 如果有WIM聊天插件，自动关闭会话窗口
                if WIM_CloseConvo then
                    local closeName = playerName
                    self:ScheduleEvent(function()
                        WIM_CloseConvo(closeName)
                    end, 1)
                end
            end
        end
    end
end

-- 更新界面状态显示
-- isActive: 是否正在检测
-- debuffName: 当前检测的debuff名称
function RAMain:UpdateStats(isActive, debuffName)
    local status = isActive and L["正在检测"] or L["未检测"]
    statsText:SetText(string.format(L["当前状态: %s, 当前检测名称: %s"], status, debuffName or L["无"]))
    statsFrame.text = statsText
end

-- 注册聊天事件（团队、团队领袖、系统频道）
function RAMain:RegisterChatEvents()
    self:RegisterEvent("CHAT_MSG_RAID", "HandleChatMessage")
    self:RegisterEvent("CHAT_MSG_RAID_LEADER", "HandleChatMessage")
    self:RegisterEvent("CHAT_MSG_SYSTEM", "HandleChatMessage")
end

-- 聊天消息处理函数
function RAMain:HandleChatMessage(msg, sender)
    DEFAULT_CHAT_FRAME:AddMessage("收到聊天消息: " .. tostring(msg) .. " 来自: " .. tostring(sender))
end
