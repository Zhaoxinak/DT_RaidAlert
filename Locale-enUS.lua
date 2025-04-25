--[[---------------------------------------------------------------------------
  DT_RaidAlert Localization - English (enUS)
  Uses AceLocale-2.2
  This file defines all UI and message translations for English.
---------------------------------------------------------------------------]]

local L = AceLibrary("AceLocale-2.2"):new("RaidAlert")

L:RegisterTranslations("enUS", function()
    return {
        ["已加载"] = " loaded", -- Plugin loaded
        ["标题"] = "Detection Panel", -- Main panel title
        ["当前状态:"] = "Current Status:", -- Status label
        ["当前状态: %s, 当前检测名称: %s"] = "Current Status: %s, Current Debuff: %s", -- Status detail
        ["开启检测"] = "Start Detection", -- Start button
        ["停止"] = "Stop", -- Stop button
        ["关闭"] = "Close", -- Close panel
        ["输入debuff名称"] = "Enter debuff name", -- Input box hint
        ["未检测"] = "Not Detecting", -- Not detecting status
        ["正在检测"] = "Detecting", -- Detecting status
        ["无"] = "None", -- No debuff
        ["通知间隔:"] = "Notify Interval:", -- Cooldown slider label
        ["秒"] = "s", -- Unit
        ["打开界面"] = "Open Panel", -- Menu item
        ["打开界面描述"] = "Open the main detection panel", -- Menu description
        ["同步间隔时间"] = "Notify Interval", -- Menu item
        ["设置消息同步间隔"] = "Set minimum interval for notifications", -- Menu description
        ["通知间隔时间已设置为 %d 秒"] = "Notify interval set to %d seconds", -- Set tip
        ["私聊模式"] = "Whisper Mode", -- Menu item
        ["开启后，自动私聊团队成员"] = "Automatically whisper raid members when enabled", -- Menu description
        ["私聊模式已开启"] = "Whisper mode enabled", -- Status tip
        ["私聊模式已关闭"] = "Whisper mode disabled", -- Status tip
        ["缩小"] = "Minimize", -- Minimize button
        ["检测还原"] = "Detect and restore", -- Mini button
    }
end)
