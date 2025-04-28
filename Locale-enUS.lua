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
        ["当前状态: %s, 当前检测名称: %s, 检测来源: %s"] = "Current Status: %s, Current Debuff: %s, Source: %s", -- Status detail with source
        ["开启检测"] = "Start Detection", -- Start button
        ["停止"] = "Stop", -- Stop button
        ["关闭"] = "Close", -- Close panel
        ["输入debuff名称"] = "Enter debuff name", -- Input box hint
        ["未检测"] = "Not Detecting", -- Not detecting status
        ["正在检测"] = "Detecting", -- Detecting status
        ["无"] = "None", -- No debuff
        ["通知间隔:"] = "Notify Interval:", -- Cooldown slider label
        ["秒"] = "s", -- Unit
        ["缩小"] = "Minimize", -- Minimize button
        ["检测还原"] = "Detect and restore", -- Mini button
        ["通知团队"] = "Notify Raid", -- Notify team checkbox
        ["通知私人"] = "Notify Whisper", -- Notify whisper checkbox
        ["最近监听debuff"] = "Recent Debuffs", -- Recent debuff list
        ["删除"] = "Delete", -- Delete button
        ["团员"] = "Party", -- Party source
        ["团队"] = "Raid", -- Raid source
        ["大喊"] = "Yell", -- Yell source
        ["Boss喊话"] = "Boss Yell", -- Boss yell source
        ["系统"] = "System", -- System source
        ["请选择检测来源"] = "Please select detection source", -- Detection source tip
        ["打开界面"] = "Open Panel", -- Open panel button
        ["打开界面描述"] = "Show the main detection panel", -- Open panel description
        ["私聊模式"] = "Whisper Mode", -- Whisper mode label
        ["开启后，自动私聊团队成员"] = "When enabled, automatically whisper raid members", -- Whisper mode description
        ["私聊模式已开启"] = "Whisper mode enabled", -- Whisper mode enabled status
        ["私聊模式已关闭"] = "Whisper mode disabled", -- Whisper mode disabled status
        ["同步间隔时间"] = "Sync Interval", -- Sync interval label
        ["设置消息同步间隔"] = "Set message sync interval", -- Sync interval description
        ["通知间隔时间已设置为 %d 秒"] = "Notification interval set to %d seconds", -- Notification interval message
    }
end)
