local _, ns = ...

local T, LOCALE = ns.Locale.Text, ns.Locale.clientLocale
ns.T = T

-- One build serves retail and WoW: Forever. Forever reports WOW_PROJECT_MAINLINE like retail,
-- so the interface number is the only tell (Forever is 16001). Each Data file loads for one game.
local interface = select(4, GetBuildInfo())
ns.IS_FOREVER = type(interface) == "number" and interface < 20000

ns.PLUGIN = "ProfessionStations" -- HandyNotes plugin id: an identifier, never translated
ns.TITLE = T["Profession Stations"]

-- Options sections: one per profession, Cooking first. tools/build_data.py emits these keys in
-- each station type's `recipes`; a station type is listed under every profession it names.
ns.PROFESSION_ORDER = {
	"cooking", "alchemy", "archaeology", "blacksmithing", "enchanting", "engineering", "firstaid",
	"fishing", "herbalism", "inscription", "jewelcrafting", "leatherworking", "mining", "skinning",
	"tailoring",
}
-- English names; other locales use the game's own (ns.professionNames from the Data files).
ns.PROFESSIONS = {
	cooking = "Cooking", alchemy = "Alchemy", archaeology = "Archaeology", blacksmithing = "Blacksmithing",
	enchanting = "Enchanting", engineering = "Engineering", firstaid = "First Aid", fishing = "Fishing",
	herbalism = "Herbalism", inscription = "Inscription", jewelcrafting = "Jewelcrafting",
	leatherworking = "Leatherworking", mining = "Mining", skinning = "Skinning", tailoring = "Tailoring",
}

function ns.ProfessionName(key)
	local names = ns.professionNames and ns.professionNames[LOCALE]
	return names and names[key] or ns.PROFESSIONS[key]
end

-- A station type's name in the client's language; its English name stays the settings key.
function ns.StationName(focus)
	return focus.names and focus.names[LOCALE] or focus.name
end

-- Pin icon per station category (each station type's `category` in the data files).
-- Icons are Vanilla-era files so they exist in both games.
ns.CATEGORIES = {
	anvil = { icon = "Interface\\Icons\\Trade_BlackSmithing" },
	forge = { icon = "Interface\\Icons\\Spell_Fire_Fire" },
	cooking = { icon = "Interface\\Icons\\INV_Misc_Food_15" },
	moonwell = { icon = "Interface\\Icons\\Spell_Nature_Starfall" },
	alchemy = { icon = "Interface\\Icons\\Trade_Alchemy" },
	tailoring = { icon = "Interface\\Icons\\Trade_Tailoring" },
	leatherworking = { icon = "Interface\\Icons\\Trade_LeatherWorking" },
	engineering = { icon = "Interface\\Icons\\Trade_Engineering" },
	jewelcrafting = { icon = "Interface\\Icons\\INV_Misc_Gem_01" },
	enchanting = { icon = "Interface\\Icons\\Trade_Engraving" },
	inscription = { icon = "Interface\\Icons\\INV_Inscription_Tradeskill01" },
	blacksmithing = { icon = "Interface\\Icons\\Trade_BlackSmithing" },
	special = { icon = "Interface\\Icons\\INV_Misc_QuestionMark" },
}

ns.DEFAULTS = {
	scale = 1.0,
	alpha = 1.0,
	minimap = true,
	showSeed = true,
	showRecorded = true,
	stations = {}, -- [English station type name] = false hides that type; anything else shows it
}

-- Chat output: message is already translated; arguments are formatted with Locale.Format.
function ns.Print(message, ...)
	print("|cff33ff99" .. ns.TITLE .. "|r: " .. ns.Locale.Format(message, ...))
end
