--[[---------------------------------------------------------------------------
  DT_RaidAlert Localization - English (enUS)
  Uses AceLocale-2.2
---------------------------------------------------------------------------]]

local L = AceLibrary("AceLocale-2.2"):new("RaidAlert")

L:RegisterTranslations("enUS", function()
    return {
        ["已加载"] = " loaded",
        ["标题"] = "Detection Panel",
        ["当前状态:"] = "Current Status:",
        ["当前状态: %s, 当前检测名称: %s"] = "Current Status: %s, Current Debuff: %s",
        ["开启检测"] = "Start Detection",
        ["停止"] = "Stop",
        ["关闭"] = "Close",
        ["输入debuff名称"] = "Enter debuff name",
        ["未检测"] = "Not Detecting",
        ["正在检测"] = "Detecting",
        ["无"] = "None",
        ["通知间隔:"] = "Notify Interval:",
        ["秒"] = "s",
        ["打开界面"] = "Open Panel",
        ["打开界面描述"] = "Open the main detection panel",
        ["同步间隔时间"] = "Notify Interval",
        ["设置消息同步间隔"] = "Set minimum interval for notifications",
        ["通知间隔时间已设置为 %d 秒"] = "Notify interval set to %d seconds",
        ["私聊模式"] = "Whisper Mode",
        ["开启后，自动私聊团队成员"] = "Automatically whisper raid members when enabled",
        ["私聊模式已开启"] = "Whisper mode enabled",
        ["私聊模式已关闭"] = "Whisper mode disabled",
    }
end)
