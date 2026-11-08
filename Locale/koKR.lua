-- Korean draft (machine-made), polite -습니다 style like Blizzard's koKR strings.
-- Command words (/pstations add, restore, types) stay English. Yards are "미터" in koKR;
-- Korean has no plural, so plural keys carry only `other`.
local _, ns = ...

ns.Locale.Register("koKR", {
	["Profession Stations"] = "전문기술 작업대",
	["Crafting station"] = "제작 작업대",
	["Recorded by you"] = "직접 기록함",
	["Click: set a TomTom waypoint"] = "클릭: TomTom 웨이포인트 설정",
	["Shift-right-click: delete this pin"] = "Shift+오른쪽 클릭: 이 표시 삭제",
	["Shift-right-click: hide this pin"] = "Shift+오른쪽 클릭: 이 표시 숨기기",
	["Deleted your %s pin."] = "%s 표시를 삭제했습니다.",
	["Hid %s. /pstations restore shows hidden pins again."] = "%s 표시를 숨겼습니다. /pstations restore로 숨긴 표시를 다시 볼 수 있습니다.",
	["Check all"] = "모두 선택",
	["Show or hide every %s station type below."] = "아래의 %s 작업대 종류를 모두 표시하거나 숨깁니다.",
	["Built-in pins: %s.\nRecord a missing station where you stand with /pstations add <station type>; shift-right-click a wrong pin to hide it."] = "기본 표시: %s.\n없는 작업대는 그 자리에서 /pstations add <작업대 종류>로 기록하고, 잘못된 표시는 Shift+오른쪽 클릭으로 숨기세요.",
	["none for this game"] = "이 게임에는 없음",
	["Icon scale"] = "아이콘 크기",
	["Icon alpha"] = "아이콘 불투명도",
	["Show on the minimap"] = "미니맵에 표시",
	["Show built-in pins"] = "기본 표시 보기",
	["Show pins you recorded"] = "직접 기록한 표시 보기",
	["Station types"] = "작업대 종류",
	["Show hidden pins again"] = "숨긴 표시 다시 보기",
	["No map position here (instances have none)."] = "이곳에는 지도 위치가 없습니다 (인스턴스에는 없음).",
	["No map position here."] = "이곳에는 지도 위치가 없습니다.",
	["%d hidden pins shown again."] = {
		other = "숨긴 표시 %d개를 다시 표시합니다.",
	},
	["Commands:"] = "명령어:",
	["open these settings in HandyNotes"] = "HandyNotes에서 이 설정 열기",
	["<station type> [label]"] = "<작업대 종류> [이름]",
	["record a station where you stand"] = "현재 위치에 작업대 기록",
	["delete or hide the nearest pin (within %d yards)"] = {
		other = "가장 가까운 표시 삭제 또는 숨기기 (%d미터 이내)",
	},
	["show hidden pins again"] = "숨긴 표시 다시 보기",
	["list the station types"] = "작업대 종류 목록",
	["your map and position"] = "현재 지도와 위치",
	["Which one? %s"] = "어느 것인가요? %s",
	["Unknown station type. /pstations types lists them."] = "알 수 없는 작업대 종류입니다. /pstations types로 목록을 확인하세요.",
	["Recorded %s at %s %.1f, %.1f."] = "%s 기록: %s %.1f, %.1f.",
	["No shown pin within %d yards."] = {
		other = "%d미터 이내에 표시가 없습니다.",
	},
	["Station types: %s"] = "작업대 종류: %s",
})
