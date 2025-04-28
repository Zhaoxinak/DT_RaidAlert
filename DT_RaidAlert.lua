--[[---------------------------------------------------------------------------
  DT_RaidAlert 主文件
  - 注册聊天命令和选项菜单
  - 插件主入口，负责初始化、配置、通信等
---------------------------------------------------------------------------]]

-- 插件对象定义，继承 Ace2 多个库
RaidAlert = AceLibrary("AceAddon-2.0"):new(
    "AceEvent-2.0",    -- 事件处理
    "AceComm-2.0",     -- 插件间通信
    "AceDB-2.0",       -- 数据库 (保存配置)
    "AceDebug-2.0",    -- 调试工具
    "AceConsole-2.0",  -- 命令行接口
    "FuBarPlugin-2.0", -- FuBar 插件支持
    "AceHook-2.1"      -- 函数钩子
)

-- 获取本地化库实例
local L = AceLibrary("AceLocale-2.2"):new("RaidAlert")

-- FuBar 或类似插件显示的图标
RaidAlert.hasIcon = "Interface\\Icons\\Spell_holy_borrowedtime"

-- 插件间通信方法名常量
local COMM_METHOD_UPDATE_MANUAL = "UpdateManuel"

-- === 插件生命周期函数 ===

-- 插件初始化 (仅执行一次)
function RaidAlert:OnInitialize()
    self:SetDebugLevel(3) -- 设置调试等级

    -- 聊天框输出前缀
    self.Prefix = "|cffF5F54A[Boss战Debuff提醒]|r|cff9482C9团队提醒|r"

    -- 注册数据库 "RaidAlertDB"
    self:RegisterDB("RaidAlertDB")
    -- 注册默认配置结构
    self:RegisterDefaults("profile", {
        xOfs = {},           -- 主窗口 X 轴偏移量
        yOfs = {},           -- 主窗口 Y 轴偏移量
        point = {},          -- 主窗口 锚点
        relativePoint = {},  -- 主窗口 相对锚点
        recentDebuffs = {},  -- 新增：保存最近debuff
    })

    -- 启用当前角色的配置文件
    self:OnProfileEnable()

    -- 初始化主界面模块 (RBMain)
    if not RAMain or not RAMain.OnInitialize then
        RAMain:OnInitialize()
        RAMain:RegisterChatEvents()
    else
        self:Print("错误：RAMain 模块未找到或未正确加载！")
        -- return -- 建议不要提前 return，保证按钮注册
    end

    -- 设置插件间通信前缀
    self:SetCommPrefix(self.Prefix)

    -- 初始化选项菜单
    self:InitializeOptions()
    self.OnMenuRequest = self.options -- 用于 FuBar 等插件显示菜单

    -- 注册聊天命令
    self:RegisterChatCommand({ "/rat" }, self.options)

    self.isPrivateWhisperMode = false    -- 私聊模式默认关闭
    self.notificationCooldownSeconds = 15 -- 消息通知冷却时间 (秒)
    self.notifyTeam = false              -- 新增：团队通知默认关闭
    self.notifyWhisper = true            -- 新增：私人通知默认开启

    DEFAULT_CHAT_FRAME:AddMessage(self.Prefix .. L["已加载"])
end

-- 插件启用 (登录、重载界面时)
function RaidAlert:OnEnable()
    -- 注册插件间通信，监听团队消息
    self:RegisterComm(self.Prefix, "RAID")
    -- 注册团队成员变化事件
    self:RegisterEvent("RAID_ROSTER_UPDATE", "HandleRaidRosterUpdate")
end

-- 插件禁用 (退出、禁用插件时)
function RaidAlert:OnDisable()
    -- 注销所有事件
    self:UnregisterAllEvents()
end

-- === 配置文件处理 ===

-- 配置文件启用时调用
function RaidAlert:OnProfileEnable()
    self.opt = self.db.profile
    -- 新增：同步 SavedVariables 到全局变量
    if type(self.opt.recentDebuffs) ~= "table" then
        self.opt.recentDebuffs = {}
    end
    -- 始终让全局变量 RaidAlertRecentDebuffs 指向数据库内容
    RaidAlertRecentDebuffs = RaidAlertRecentDebuffs or self.opt.recentDebuffs or {}
    -- 可能需要通知 RBMain 更新其使用的配置
    if RAMain and RAMain.OnProfileUpdate then
        RAMain:OnProfileUpdate(self.opt)
    end
    -- 新增：同步通知选项
    self.notifyTeam = self.notifyTeam or false
    self.notifyWhisper = self.notifyWhisper or true
end

-- 新增：保存 recentDebuffs 到数据库
function RaidAlert:SaveRecentDebuffs()
    if self.opt then
        -- 强制同步全局变量到数据库
        self.opt.recentDebuffs = RaidAlertRecentDebuffs
    end
end

-- === 选项菜单 ===
-- 初始化插件选项菜单
function RaidAlert:InitializeOptions()
    self.options = {
        type = "group",
        args = {
            open = {
                type = "execute",
                name = L["打开界面"],
                desc = L["打开界面描述"],
                order = 1,
                func = function()
                    if RAMain and RAMain.mainFrame then
                        RAMain.mainFrame:Show()
                    else
                        self:Print("错误：无法打开界面，RAMain 或其界面未初始化。")
                    end
                end
            },
            privateWhisper = {
                type = "toggle",
                name = L["私聊模式"], -- 修改了名称，更清晰
                desc = L["开启后，自动私聊团队成员"],
                order = 2,
                disabled = function() return not self.isAutoReplyEnabled end, -- 仅在自动答复开启时可用
                get = function() return self.isPrivateWhisperMode end,
                set = function()
                    self.isPrivateWhisperMode = not self.isPrivateWhisperMode
                    self:Print(self.isPrivateWhisperMode and L["私聊模式已开启"] or L["私聊模式已关闭"])
                end
            },
            cooldown = {
                type = "range",
                name = L["同步间隔时间"],
                desc = L["设置消息同步间隔"],
                order = 3,
                min = 1,
                max = 60,
                step = 1,
                get = function() return self.notificationCooldownSeconds end,
                set = function(v)
                    self.notificationCooldownSeconds = v
                    self:Print(format(L["通知间隔时间已设置为 %d 秒"], v))
                end
            }
        }
    }
end

-- === 插件间通信 ===

-- 接收 AceComm 消息
-- commPrefix: 注册的前缀 (self.Prefix)
-- sender: 发送者名字
-- distributionType: 分布类型 ("RAID")
-- method: 方法名 (e.g., "UpdateManuel")
-- buffInternalID: Buff 内部标识
-- subgroup: 小队编号
-- targetName: 目标玩家名字 (负责者)
function RaidAlert:OnCommReceive(commPrefix, sender, distributionType, method, buffInternalID, subgroup, targetName)
    if method == COMM_METHOD_UPDATE_MANUAL then
        self:Debug(format("收到来自 %s 的手动更新: Buff=%s, 小队=%s, 负责者=%s", sender, buffInternalID or "N/A", subgroup or "N/A",
            targetName or "清除"))

        -- if RBMain and RBMain.UpdateResult then
        --     -- 调用 RBMain 更新分配结果 (false 表示非离队触发)
        --     RBMain:UpdateResult(buffInternalID, subgroup, targetName, false)
        --     -- 刷新界面显示
        --     RBMain:Flush()
        -- else
        --     self:Print("错误：无法处理通信消息，RBMain 或 UpdateResult 未找到。")
        -- end
    end
end

-- 处理团队成员变化事件
function RaidAlert:HandleRaidRosterUpdate()
    self:Debug("团队成员发生变化，重新扫描并检查离队成员。")
    -- -- 重新扫描团队
    -- if RBMain and RBMain.Scan then
    --     RBMain:Scan()
    -- end
    -- -- 检查是否有已分配的玩家离队
    -- self:CheckForLeftPlayers()
    -- -- 刷新界面
    -- if RBMain and RBMain.Flush then
    --     RBMain:Flush()
    -- end
end
