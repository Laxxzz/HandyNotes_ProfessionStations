-- Russian draft (machine-made), addressed as вы like Blizzard's ruRU strings.
-- Command words (/pstations add, restore, types) stay English. Yards are "м" in ruRU, which
-- needs no plural, so those keys carry only `other`.
local _, ns = ...

ns.Locale.Register("ruRU", {
	["Profession Stations"] = "Станции профессий",
	["Crafting station"] = "Ремесленная станция",
	["Recorded by you"] = "Записано вами",
	["Click: set a TomTom waypoint"] = "Щелчок: поставить путевую точку TomTom",
	["Shift-right-click: delete this pin"] = "Shift + правый щелчок: удалить эту метку",
	["Shift-right-click: hide this pin"] = "Shift + правый щелчок: скрыть эту метку",
	["Deleted your %s pin."] = "Ваша метка «%s» удалена.",
	["Hid %s. /pstations restore shows hidden pins again."] = "Скрыто: «%s». /pstations restore снова показывает скрытые метки.",
	["Check all"] = "Отметить все",
	["Show or hide every %s station type below."] = "Показать или скрыть все типы станций ниже (%s).",
	["Built-in pins: %s.\nRecord a missing station where you stand with /pstations add <station type>; shift-right-click a wrong pin to hide it."] = "Встроенные метки: %s.\nЗапишите недостающую станцию там, где стоите, командой /pstations add <тип станции>; Shift + правый щелчок скрывает неверную метку.",
	["none for this game"] = "нет для этой игры",
	["Icon scale"] = "Размер значков",
	["Icon alpha"] = "Непрозрачность значков",
	["Show on the minimap"] = "Показывать на миникарте",
	["Show built-in pins"] = "Показывать встроенные метки",
	["Show pins you recorded"] = "Показывать ваши метки",
	["Station types"] = "Типы станций",
	["Show hidden pins again"] = "Снова показать скрытые метки",
	["No map position here (instances have none)."] = "Здесь нет позиции на карте (в подземельях ее нет).",
	["No map position here."] = "Здесь нет позиции на карте.",
	["%d hidden pins shown again."] = {
		one = "Снова показана %d скрытая метка.",
		few = "Снова показаны %d скрытые метки.",
		many = "Снова показано %d скрытых меток.",
		other = "Снова показано %d скрытой метки.",
	},
	["Commands:"] = "Команды:",
	["open these settings in HandyNotes"] = "открыть эти настройки в HandyNotes",
	["<station type> [label]"] = "<тип станции> [название]",
	["record a station where you stand"] = "записать станцию там, где вы стоите",
	["delete or hide the nearest pin (within %d yards)"] = {
		other = "удалить или скрыть ближайшую метку (в пределах %d м)",
	},
	["show hidden pins again"] = "снова показать скрытые метки",
	["list the station types"] = "список типов станций",
	["your map and position"] = "ваша карта и позиция",
	["Which one? %s"] = "Какую именно? %s",
	["Unknown station type. /pstations types lists them."] = "Неизвестный тип станции. Список: /pstations types.",
	["Recorded %s at %s %.1f, %.1f."] = "Записано: %s, %s %.1f, %.1f.",
	["No shown pin within %d yards."] = {
		other = "В пределах %d м нет видимых меток.",
	},
	["Station types: %s"] = "Типы станций: %s",
})
