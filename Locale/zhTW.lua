-- Traditional Chinese draft (machine-made), addressed as 你 like Blizzard's zhTW strings.
-- Command words (/pstations add, restore, types) stay English. Yards are "碼" in zhTW;
-- Chinese has no plural, so plural keys carry only `other`.
local _, ns = ...

ns.Locale.Register("zhTW", {
	["Profession Stations"] = "專業製作台",
	["Crafting station"] = "製作台",
	["Recorded by you"] = "由你記錄",
	["Click: set a TomTom waypoint"] = "點擊：設定TomTom導航點",
	["Shift-right-click: delete this pin"] = "Shift+右鍵點擊：刪除此標記",
	["Shift-right-click: hide this pin"] = "Shift+右鍵點擊：隱藏此標記",
	["Deleted your %s pin."] = "已刪除你的%s標記。",
	["Hid %s. /pstations restore shows hidden pins again."] = "已隱藏%s。/pstations restore 可重新顯示隱藏的標記。",
	["Check all"] = "全選",
	["Show or hide every %s station type below."] = "顯示或隱藏下方所有%s製作台類型。",
	["Built-in pins: %s.\nRecord a missing station where you stand with /pstations add <station type>; shift-right-click a wrong pin to hide it."] = "內建標記：%s。\n在原地用 /pstations add <製作台類型> 記錄缺少的製作台；Shift+右鍵點擊錯誤的標記可將其隱藏。",
	["none for this game"] = "此遊戲無",
	["Icon scale"] = "圖示縮放",
	["Icon alpha"] = "圖示透明度",
	["Show on the minimap"] = "在小地圖上顯示",
	["Show built-in pins"] = "顯示內建標記",
	["Show pins you recorded"] = "顯示你記錄的標記",
	["Station types"] = "製作台類型",
	["Show hidden pins again"] = "重新顯示隱藏的標記",
	["No map position here (instances have none)."] = "此處沒有地圖位置（副本內沒有）。",
	["No map position here."] = "此處沒有地圖位置。",
	["%d hidden pins shown again."] = {
		other = "已重新顯示%d個隱藏的標記。",
	},
	["Commands:"] = "指令：",
	["open these settings in HandyNotes"] = "在HandyNotes中開啟這些設定",
	["<station type> [label]"] = "<製作台類型> [名稱]",
	["record a station where you stand"] = "在你所在的位置記錄製作台",
	["delete or hide the nearest pin (within %d yards)"] = {
		other = "刪除或隱藏最近的標記（%d碼以內）",
	},
	["show hidden pins again"] = "重新顯示隱藏的標記",
	["list the station types"] = "列出製作台類型",
	["your map and position"] = "你的地圖和位置",
	["Which one? %s"] = "哪一個？%s",
	["Unknown station type. /pstations types lists them."] = "未知的製作台類型。/pstations types 可列出全部類型。",
	["Recorded %s at %s %.1f, %.1f."] = "已記錄%s：%s %.1f, %.1f。",
	["No shown pin within %d yards."] = {
		other = "%d碼以內沒有顯示的標記。",
	},
	["Station types: %s"] = "製作台類型：%s",
})
