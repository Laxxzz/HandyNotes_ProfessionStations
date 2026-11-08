-- Simplified Chinese draft (machine-made), addressed as 你 like Blizzard's zhCN strings.
-- Command words (/pstations add, restore, types) stay English. Yards are "码" in zhCN;
-- Chinese has no plural, so plural keys carry only `other`.
local _, ns = ...

ns.Locale.Register("zhCN", {
	["Profession Stations"] = "专业制作台",
	["Crafting station"] = "制作台",
	["Recorded by you"] = "由你记录",
	["Click: set a TomTom waypoint"] = "点击：设置TomTom路径点",
	["Shift-right-click: delete this pin"] = "Shift+右键点击：删除此标记",
	["Shift-right-click: hide this pin"] = "Shift+右键点击：隐藏此标记",
	["Deleted your %s pin."] = "已删除你的%s标记。",
	["Hid %s. /pstations restore shows hidden pins again."] = "已隐藏%s。/pstations restore 可重新显示隐藏的标记。",
	["Check all"] = "全选",
	["Show or hide every %s station type below."] = "显示或隐藏下方所有%s制作台类型。",
	["Built-in pins: %s.\nRecord a missing station where you stand with /pstations add <station type>; shift-right-click a wrong pin to hide it."] = "内置标记：%s。\n在原地用 /pstations add <制作台类型> 记录缺失的制作台；Shift+右键点击错误的标记可将其隐藏。",
	["none for this game"] = "此游戏无",
	["Icon scale"] = "图标缩放",
	["Icon alpha"] = "图标透明度",
	["Show on the minimap"] = "在小地图上显示",
	["Show built-in pins"] = "显示内置标记",
	["Show pins you recorded"] = "显示你记录的标记",
	["Station types"] = "制作台类型",
	["Show hidden pins again"] = "重新显示隐藏的标记",
	["No map position here (instances have none)."] = "此处没有地图位置（副本内没有）。",
	["No map position here."] = "此处没有地图位置。",
	["%d hidden pins shown again."] = {
		other = "已重新显示%d个隐藏的标记。",
	},
	["Commands:"] = "命令：",
	["open these settings in HandyNotes"] = "在HandyNotes中打开这些设置",
	["<station type> [label]"] = "<制作台类型> [名称]",
	["record a station where you stand"] = "在你所在的位置记录制作台",
	["delete or hide the nearest pin (within %d yards)"] = {
		other = "删除或隐藏最近的标记（%d码以内）",
	},
	["show hidden pins again"] = "重新显示隐藏的标记",
	["list the station types"] = "列出制作台类型",
	["your map and position"] = "你的地图和位置",
	["Which one? %s"] = "哪一个？%s",
	["Unknown station type. /pstations types lists them."] = "未知的制作台类型。/pstations types 可列出全部类型。",
	["Recorded %s at %s %.1f, %.1f."] = "已记录%s：%s %.1f, %.1f。",
	["No shown pin within %d yards."] = {
		other = "%d码以内没有显示的标记。",
	},
	["Station types: %s"] = "制作台类型：%s",
})
