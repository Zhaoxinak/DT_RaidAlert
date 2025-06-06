--[[---------------------------------------------------------------------------
  DT_RaidAlert 本地化文件 - 繁體中文 (zhTW)
  使用 AceLocale-2.2 库
  本文件定義插件所有界面與消息的繁體中文翻譯
---------------------------------------------------------------------------]]

local L = AceLibrary("AceLocale-2.2"):new("RaidAlert")

L:RegisterTranslations("zhTW", function()
    return {
        ["已加载"] = " 已加載", -- 插件加載提示
        ["标题"] = "檢測介面", -- 主介面標題
        ["当前状态:"] = "當前狀態:", -- 狀態標籤
        ["当前状态: %s, 当前检测名称: %s"] = "當前狀態: %s, 當前檢測名稱: %s", -- 狀態詳情
        ["当前状态: %s, 当前检测名称: %s, 检测来源: %s"] = "當前狀態: %s, 當前檢測名稱: %s, 檢測來源: %s", -- 狀態詳情擴展
        ["开启检测"] = "開始檢測", -- 開始檢測按鈕
        ["停止"] = "停止", -- 停止檢測按鈕
        ["关闭"] = "關閉", -- 關閉介面按鈕
        ["输入debuff名称"] = "輸入debuff名稱", -- 輸入框提示
        ["未检测"] = "未檢測", -- 未檢測狀態
        ["正在检测"] = "檢測中", -- 檢測中狀態
        ["无"] = "無", -- 無debuff
        ["通知间隔:"] = "通知間隔:", -- 冷卻滑塊標籤
        ["秒"] = "秒", -- 單位
        ["缩小"] = "縮小", -- 縮小按鈕
        ["检测还原"] = "檢測還原", -- 小按鈕
        ["通知团队"] = "通知團隊", -- 通知團隊選擇框
        ["通知私人"] = "通知私人", -- 通知私人選擇框
        ["最近监听debuff"] = "最近監聽debuff", -- 最近debuff列表
        ["删除"] = "刪除", -- 刪除按鈕
        ["团员"] = "團員",
        ["团队"] = "團隊",
        ["大喊"] = "大喊",
        ["Boss喊话"] = "Boss喊話",
        ["系统"] = "系統",
        ["请选择检测来源"] = "請選擇檢測來源", -- 檢測來源提示
        ["打开界面"] = "打開介面",
        ["打开界面描述"] = "顯示主檢測介面",
        ["私聊模式"] = "私聊模式",
        ["开启后，自动私聊团队成员"] = "開啟後，自動私聊團隊成員",
        ["私聊模式已开启"] = "私聊模式已開啟",
        ["私聊模式已关闭"] = "私聊模式已關閉",
        ["同步间隔时间"] = "同步間隔時間",
        ["设置消息同步间隔"] = "設置消息同步間隔",
        ["通知间隔时间已设置为 %d 秒"] = "通知間隔時間已設置為 %d 秒",
    }
end)
