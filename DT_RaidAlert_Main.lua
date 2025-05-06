-- 确保最近debuff列表变量已初始化
if not RaidAlertRecentDebuffs then
    RaidAlertRecentDebuffs = {}
end

-- 主界面相关常量
local FRAME_HEIGHT = 260 -- 主界面高度（适当增加）
local FRAME_WIDTH = 480  -- 主界面宽度（适当增加）

-- 主界面及其控件引用
local statsFrame, searchBox, statsText, cooldownSlider
local miniButton, miniButtonDragFrame

-- 定时检测事件名
local DEBUFF_CHECK_EVENT = "RA_DebuffCheckEvent"
local activeDebuffNames = nil -- 当前激活的debuff名称列表

-- 新增：检测来源选择框引用
local sourceChecks = {}

-- RAMain 模块定义，继承 Ace2 多个库
RAMain = AceLibrary("AceAddon-2.0"):new(
    "AceEvent-2.0",   -- 事件处理
    "AceComm-2.0",    -- 通信
    "AceDB-2.0",      -- 数据库
    "AceDebug-2.0",   -- 调试
    "AceConsole-2.0", -- 命令行
    "AceHook-2.1"     -- 钩子
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

    -- 新增：检测来源提示文字
    local sourceTip = frame:CreateFontString(nil, "OVERLAY")
    sourceTip:SetFontObject("GameFontNormal")
    sourceTip:SetPoint("TOPLEFT", titleLine, "BOTTOMLEFT", 0, -4)
    sourceTip:SetText(L["请选择检测来源"])
    frame.fontStrs["sourceTip"] = sourceTip

    -- 新增：检测来源选择框（团员，团队，大喊，Boss喊话）
    -- 不使用循环，单独写每个CheckButton

    -- 团员
    local partyCheck = CreateFrame("CheckButton", "RASourceCheck_party", frame, "UICheckButtonTemplate")
    partyCheck:SetPoint("TOPLEFT", sourceTip, "BOTTOMLEFT", 0, -6)
    partyCheck:SetWidth(24)
    partyCheck:SetHeight(24)
    if not partyCheck.Text then
        partyCheck.text = partyCheck:CreateFontString(nil, "OVERLAY")
        partyCheck.text:SetFontObject("GameFontNormal")
        partyCheck.text:SetPoint("LEFT", partyCheck, "RIGHT", 2, 0)
        partyCheck.text:SetText(L["团员"])
    else
        partyCheck.Text:SetText(L["团员"])
    end
    if RaidAlert["source_party"] == nil then
        RaidAlert["source_party"] = true
    end
    partyCheck:SetChecked(RaidAlert["source_party"])
    partyCheck:SetScript("OnClick", function()
        RaidAlert["source_party"] = partyCheck:GetChecked()
        partyCheck:SetChecked(RaidAlert["source_party"])
    end)
    sourceChecks["party"] = partyCheck

    -- 团队
    local raidCheck = CreateFrame("CheckButton", "RASourceCheck_raid", frame, "UICheckButtonTemplate")
    raidCheck:SetPoint("LEFT", partyCheck, "RIGHT", 70, 0)
    raidCheck:SetWidth(24)
    raidCheck:SetHeight(24)
    if not raidCheck.Text then
        raidCheck.text = raidCheck:CreateFontString(nil, "OVERLAY")
        raidCheck.text:SetFontObject("GameFontNormal")
        raidCheck.text:SetPoint("LEFT", raidCheck, "RIGHT", 2, 0)
        raidCheck.text:SetText(L["团队"])
    else
        raidCheck.Text:SetText(L["团队"])
    end
    if RaidAlert["source_raid"] == nil then
        RaidAlert["source_raid"] = false
    end
    raidCheck:SetChecked(RaidAlert["source_raid"])
    raidCheck:SetScript("OnClick", function()
        RaidAlert["source_raid"] = raidCheck:GetChecked()
        raidCheck:SetChecked(RaidAlert["source_raid"])
    end)
    sourceChecks["raid"] = raidCheck

    -- 大喊
    local yellCheck = CreateFrame("CheckButton", "RASourceCheck_yell", frame, "UICheckButtonTemplate")
    yellCheck:SetPoint("LEFT", raidCheck, "RIGHT", 70, 0)
    yellCheck:SetWidth(24)
    yellCheck:SetHeight(24)
    if not yellCheck.Text then
        yellCheck.text = yellCheck:CreateFontString(nil, "OVERLAY")
        yellCheck.text:SetFontObject("GameFontNormal")
        yellCheck.text:SetPoint("LEFT", yellCheck, "RIGHT", 2, 0)
        yellCheck.text:SetText(L["大喊"])
    else
        yellCheck.Text:SetText(L["大喊"])
    end
    if RaidAlert["source_yell"] == nil then
        RaidAlert["source_yell"] = false
    end
    yellCheck:SetChecked(RaidAlert["source_yell"])
    yellCheck:SetScript("OnClick", function()
        RaidAlert["source_yell"] = yellCheck:GetChecked()
        yellCheck:SetChecked(RaidAlert["source_yell"])
    end)
    sourceChecks["yell"] = yellCheck

    -- Boss喊话
    local bossCheck = CreateFrame("CheckButton", "RASourceCheck_boss", frame, "UICheckButtonTemplate")
    bossCheck:SetPoint("LEFT", yellCheck, "RIGHT", 70, 0)
    bossCheck:SetWidth(24)
    bossCheck:SetHeight(24)
    if not bossCheck.Text then
        bossCheck.text = bossCheck:CreateFontString(nil, "OVERLAY")
        bossCheck.text:SetFontObject("GameFontNormal")
        bossCheck.text:SetPoint("LEFT", bossCheck, "RIGHT", 2, 0)
        bossCheck.text:SetText(L["Boss喊话"])
    else
        bossCheck.Text:SetText(L["Boss喊话"])
    end
    if RaidAlert["source_boss"] == nil then
        RaidAlert["source_boss"] = false
    end
    bossCheck:SetChecked(RaidAlert["source_boss"])
    bossCheck:SetScript("OnClick", function()
        RaidAlert["source_boss"] = bossCheck:GetChecked()
        bossCheck:SetChecked(RaidAlert["source_boss"])
    end)
    sourceChecks["boss"] = bossCheck

    local firstSourceCheck = partyCheck

    -- 冷却时间滑块（设置通知间隔）
    cooldownSlider = CreateFrame("Slider", "RAStatsCooldownSlider", frame, "OptionsSliderTemplate")
    cooldownSlider:SetOrientation("HORIZONTAL")
    cooldownSlider:SetWidth(180)
    cooldownSlider:SetHeight(20)
    -- 修改锚点：放在团员选择框下方
    cooldownSlider:SetPoint("TOPLEFT", firstSourceCheck, "BOTTOMLEFT", 0, -20)
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

    -- 搜索框（输入debuff名称）
    searchBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    searchBox:SetPoint("TOPLEFT", cooldownSlider, "BOTTOMLEFT", 0, -30)
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
        -- 只在勾选“团员”时才调用 StartDebuffCheck
        if RaidAlert and RaidAlert.source_party then
            RAMain:StartDebuffCheck(query)
        else
            -- 只注册聊天事件，不做debuff检测
            RAMain:StartDebuffCheck() -- 停止任何已有检测
            RAMain:RegisterChatEvents()
            RAMain:UpdateStats(false, nil)
        end
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
        RAMain:UpdateStats(false, nil)
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
        RAMain:UpdateStats(false, nil)
    end)

    -- 新增：通知团队/私人选择框
    local notifyTeamCheck = CreateFrame("CheckButton", "RANotifyTeamCheck", frame, "UICheckButtonTemplate")
    notifyTeamCheck:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", 0, -10)
    notifyTeamCheck:SetWidth(24)
    notifyTeamCheck:SetHeight(24)
    notifyTeamCheck.text = notifyTeamCheck:CreateFontString(nil, "OVERLAY")
    notifyTeamCheck.text:SetFontObject("GameFontNormal")
    notifyTeamCheck.text:SetPoint("LEFT", notifyTeamCheck, "RIGHT", 2, 0)
    notifyTeamCheck.text:SetText(L["通知团队"])
    notifyTeamCheck:SetChecked(RaidAlert and RaidAlert.notifyTeam or false)
    notifyTeamCheck:SetScript("OnClick", function()
        if RaidAlert then
            RaidAlert.notifyTeam = notifyTeamCheck:GetChecked()
        end
    end)

    local notifyWhisperCheck = CreateFrame("CheckButton", "RANotifyWhisperCheck", frame, "UICheckButtonTemplate")
    notifyWhisperCheck:SetPoint("LEFT", notifyTeamCheck, "RIGHT", 100, 0)
    notifyWhisperCheck:SetWidth(24)
    notifyWhisperCheck:SetHeight(24)
    notifyWhisperCheck.text = notifyWhisperCheck:CreateFontString(nil, "OVERLAY")
    notifyWhisperCheck.text:SetFontObject("GameFontNormal")
    notifyWhisperCheck.text:SetPoint("LEFT", notifyWhisperCheck, "RIGHT", 2, 0)
    notifyWhisperCheck.text:SetText(L["通知私人"])
    notifyWhisperCheck:SetChecked(RaidAlert and RaidAlert.notifyWhisper or true)
    notifyWhisperCheck:SetScript("OnClick", function()
        if RaidAlert then
            RaidAlert.notifyWhisper = notifyWhisperCheck:GetChecked()
        end
    end)

    -- 最近监听debuff的ScrollFrame
    local scrollFrame = CreateFrame("ScrollFrame", "RARecentDebuffScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetWidth(160)
    scrollFrame:SetHeight(60)
    scrollFrame:SetPoint("LEFT", cooldownSlider, "RIGHT", 10, 0)
    scrollFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    scrollFrame:SetAlpha(0.8)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(150)
    content:SetHeight(60)
    scrollFrame:SetScrollChild(content)
    frame.recentDebuffScrollFrame = scrollFrame
    frame.recentDebuffContent = content

    function RAMain:UpdateRecentDebuffList()
        local parent = self.mainFrame and self.mainFrame.recentDebuffContent
        local scrollFrame = self.mainFrame and self.mainFrame.recentDebuffScrollFrame
        if not parent then return end
        -- 清理旧的按钮
        if parent.buttons then
            for _, btn in ipairs(parent.buttons) do
                btn:Hide()
                btn:SetParent(nil)
            end
        end
        parent.buttons = {}
        local y = -2
        local btnHeight = 20
        for i, debuff in ipairs(RaidAlertRecentDebuffs) do
            local thisDebuff = debuff
            local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
            btn:SetWidth(130)
            btn:SetHeight(18)
            btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, y)
            btn:SetText(tostring(thisDebuff) or "")
            btn:SetScript("OnClick", function()
                searchBox:SetText(tostring(thisDebuff) or "")
                searchBox:ClearFocus()
            end)
            -- 删除按钮
            local delBtn = CreateFrame("Button", nil, btn, "UIPanelCloseButton")
            delBtn:SetWidth(18)
            delBtn:SetHeight(18)
            delBtn:SetPoint("RIGHT", btn, "RIGHT", 18, 0)
            delBtn:SetScript("OnClick", function()
                -- 查找并删除对应debuff
                for idx, v in ipairs(RaidAlertRecentDebuffs) do
                    if v == thisDebuff then
                        table.remove(RaidAlertRecentDebuffs, idx)
                        if RaidAlert and RaidAlert.SaveRecentDebuffs then
                            RaidAlert:SaveRecentDebuffs()
                        end
                        break
                    end
                end
                RAMain:UpdateRecentDebuffList()
            end)
            btn.delBtn = delBtn
            btn:Show()
            table.insert(parent.buttons, btn)
            y = y - btnHeight
        end
        -- 动态调整content高度
        local totalHeight = math.max(getn(RaidAlertRecentDebuffs) * btnHeight, 60)
        parent:SetHeight(totalHeight)
        if scrollFrame then
            scrollFrame:UpdateScrollChildRect()
            local scrollbar = _G[scrollFrame:GetName() .. "ScrollBar"]
            if scrollbar then
                local min, max = scrollbar:GetMinMaxValues()
                if max > 0 then
                    scrollbar:Show()
                else
                    scrollbar:Hide()
                end
            end
        end

        if RaidAlert and RaidAlert.SaveRecentDebuffs then
            RaidAlert:SaveRecentDebuffs()
        end
    end

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
            miniButtonDragFrame:SetPoint(point or "CENTER", relativeTo or UIParent, relativePoint or "CENTER", xOfs or 0,
                yOfs or 0)
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

     -- 新增：刷新最近debuff列表
     if self.mainFrame and self.mainFrame.UpdateRecentDebuffList then
        self.mainFrame:UpdateRecentDebuffList()
    elseif RAMain.UpdateRecentDebuffList then
        RAMain:UpdateRecentDebuffList()
    end
    
end

-- 开始或停止debuff检测
-- debuffInput: 用户输入的debuff名称（可多个，用/分隔）
function RAMain:StartDebuffCheck(debuffInput)
    self:CancelScheduledEvent(DEBUFF_CHECK_EVENT)
    activeDebuffNames = nil

    if not debuffInput or debuffInput == "" or debuffInput == L["输入debuff名称"] then
        self:UpdateStats(false, nil)
        return
    end

    local debuffList = {}

    for name in string.gmatch(debuffInput, "([^/]+)") do
        name = strtrim(name)
        if name ~= "" then
            table.insert(debuffList, name)
            -- 新增：记录到 RaidAlertRecentDebuffs
            local exists = false
            for _, v in ipairs(RaidAlertRecentDebuffs) do
                if v == name then
                    exists = true
                    break
                end
            end
            if not exists then
                table.insert(RaidAlertRecentDebuffs, name)
                if RaidAlert and RaidAlert.SaveRecentDebuffs then
                    RaidAlert:SaveRecentDebuffs()
                end
            end
        end
    end
    if getn(debuffList) == 0 then
        self:UpdateStats(false, nil)
        return
    end
    activeDebuffNames = debuffList

    -- 新增：刷新最近debuff列表
    if self.mainFrame and self.mainFrame.UpdateRecentDebuffList then
        self.mainFrame:UpdateRecentDebuffList()
    elseif RAMain.UpdateRecentDebuffList then
        RAMain:UpdateRecentDebuffList()
    end

    -- 定时检测，每秒扫描一次
    self:ScheduleRepeatingEvent(DEBUFF_CHECK_EVENT, function()
        RARaid:Scan(activeDebuffNames)
        RAMain:NotifyDebuffedPlayers(activeDebuffNames)
    end, 1)

    -- 新增：注册聊天事件
    self:RegisterChatEvents()

    self:UpdateStats(true, table.concat(debuffList, " / "))
end

-- 检查团队成员是否中了指定debuff，返回中了debuff的玩家及debuff
function RAMain:CheckDebuffedPlayers(debuffNames)
    if type(debuffNames) == "string" then
        debuffNames = { debuffNames }
    end
    local debuffedPlayers = {}
    for playerName, debuffs in pairs(RARaid.raidDebuffs) do
        for _, debuff in ipairs(debuffs) do
            for _, targetDebuff in ipairs(debuffNames) do
                if debuff == targetDebuff then
                    if not debuffedPlayers[playerName] then
                        debuffedPlayers[playerName] = {}
                    end
                    table.insert(debuffedPlayers[playerName], debuff)
                end
            end
        end
    end
    return debuffedPlayers
end

-- 新增：发送私信的辅助方法
function RAMain:SendWhisperMessage(targetPlayer, message)
    if not targetPlayer or targetPlayer == "" then return end

    -- 仅在勾选了“通知私人”时发送私信
    if RaidAlert and RaidAlert.notifyWhisper then
        SendChatMessage(message, "WHISPER", nil, targetPlayer)
        -- 如果有 WIM 聊天插件，自动关闭会话窗口
        if type(WIM_CloseConvo) == "function" and targetPlayer and targetPlayer ~= "" then
            self:ScheduleEvent(function()
                if targetPlayer and targetPlayer ~= "" then
                    WIM_CloseConvo(targetPlayer)
                end
            end, 1)
        end
    end
end

-- 私聊提醒中了debuff的玩家
function RAMain:NotifyDebuffedPlayers(debuffNames)
    local debuffedPlayers = self:CheckDebuffedPlayers(debuffNames)
    local now = GetTime()
    for playerName, debuffs in pairs(debuffedPlayers) do
        local notifiedDebuffs = {}
        for _, debuff in ipairs(debuffs) do
            if not notifiedDebuffs[debuff] then
                local cooldownKey = playerName .. ":" .. debuff
                if not whisperCooldowns[cooldownKey] or now - whisperCooldowns[cooldownKey] > RaidAlert.notificationCooldownSeconds then
                    -- 新增：根据选择框决定通知方式
                    if RaidAlert and RaidAlert.notifyWhisper then
                        self:SendWhisperMessage(playerName, "你中了debuff: " .. debuff .. "  (时间: " .. DV_Date() .. ")")
                    end
                    if RaidAlert and RaidAlert.notifyTeam then
                        SendChatMessage(playerName .. " 中了debuff: " .. debuff .. "  (时间: " .. DV_Date() .. ")", "RAID")
                    end
                    whisperCooldowns[cooldownKey] = now
                end
                notifiedDebuffs[debuff] = true
            end
        end
    end
end

-- 更新界面状态显示
-- isActive: 是否正在检测
-- debuffName: 当前检测的debuff名称
function RAMain:UpdateStats(isActive, debuffName)
    local status = isActive and L["正在检测"] or L["未检测"]
    -- 新增：显示当前检测来源
    local sources = {}
    if RaidAlert and RaidAlert.source_party then table.insert(sources, L["团员"]) end
    if RaidAlert and RaidAlert.source_raid then table.insert(sources, L["团队"]) end
    if RaidAlert and RaidAlert.source_yell then table.insert(sources, L["大喊"]) end
    if RaidAlert and RaidAlert.source_boss then table.insert(sources, L["Boss喊话"]) end
    local sourceStr = getn(sources) > 0 and table.concat(sources, " / ") or L["无"]
    statsText:SetText(string.format(L["当前状态: %s, 当前检测名称: %s, 检测来源: %s"], status, debuffName or L["无"], sourceStr))
    statsFrame.text = statsText
end

-- 辅助函数：判断事件是否已注册
local function IsEventRegistered(self, event)
    if not self or not self.eventRegistry then return false end
    return self.eventRegistry[event] ~= nil
end

-- 注册聊天事件（根据检测来源选择框）
function RAMain:RegisterChatEvents()
    -- 先注销所有相关事件（加判断，避免AceEvent报错）
    local events = {
        "CHAT_MSG_RAID",
        "CHAT_MSG_YELL",
        "CHAT_MSG_MONSTER_YELL",
        "CHAT_MSG_RAID_LEADER",
        "CHAT_MSG_SYSTEM"
    }
    for _, event in ipairs(events) do
        -- AceEvent-2.0 会在 RAMain[event] 存在时注册事件
        -- 这里用 AceEvent 的私有表 eventRegistry 判断
        if IsEventRegistered(self, event) then
            self:UnregisterEvent(event)
        end
    end
    -- 根据选择框注册
    if RaidAlert and RaidAlert.source_raid then
        self:RegisterEvent("CHAT_MSG_RAID", "HandleChatMessage")
        self:RegisterEvent("CHAT_MSG_RAID_LEADER", "HandleChatMessage")
    end
    if RaidAlert and RaidAlert.source_yell then
        self:RegisterEvent("CHAT_MSG_YELL", "HandleChatMessage")
    end
    if RaidAlert and RaidAlert.source_boss then
        self:RegisterEvent("CHAT_MSG_MONSTER_YELL", "HandleChatMessage")
        self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE", "HandleChatMessage")
        
    end
    -- 系统频道保留
    self:RegisterEvent("CHAT_MSG_SYSTEM", "HandleChatMessage")
end

-- 聊天消息处理函数（参数顺序修正：msg, sender, event）
function RAMain:HandleChatMessage(msg, sender)
    -- 确保 msg 是字符串类型
    if type(msg) ~= "string" then
        DEFAULT_CHAT_FRAME:AddMessage("错误: msg 不是字符串类型")
        return
    end

    -- 检查消息是否以 "鲁普图兰命令大地粉碎" 开头
    local prefix = "鲁普图兰命令大地粉碎"
    if string.sub(msg, 1, string.len(prefix)) == prefix then
        -- 提取玩家名字（消息中前缀后的部分）
        local targetPlayer = string.match(msg, prefix .. " (.+)")
        if targetPlayer and targetPlayer ~= "" then
            -- 删除 targetPlayer 中的感叹号
            targetPlayer = string.gsub(targetPlayer, "！", "")
            self:SendWhisperMessage(targetPlayer, "你被点名了，请注意！")
        end
    end

    -- 调试信息
    DEFAULT_CHAT_FRAME:AddMessage("msg: " .. tostring(msg) .. ", sender: " .. tostring(sender))
end