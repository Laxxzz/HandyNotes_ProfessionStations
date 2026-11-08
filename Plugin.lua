local ADDON, ns = ...

local HandyNotes = LibStub("AceAddon-3.0"):GetAddon("HandyNotes", true)
if not HandyNotes then return end

local T, Format, Plural = ns.T, ns.Locale.Format, ns.Locale.Plural
local CATEGORIES, PLUGIN = ns.CATEGORIES, ns.PLUGIN
-- Object names in the data are English only; other clients show the translated station type.
local ENGLISH = ns.Locale.clientLocale == "enUS"
local REMOVE_RADIUS_YARDS = 15
local FOCI = ns.foci or {}   -- this game's station types (Data/*.lua)
local FOCUS_BY_NAME = {}
for _, focus in ipairs(FOCI) do FOCUS_BY_NAME[focus.name] = focus end
local db -- HandyNotes_ProfessionStationsDB, bound on ADDON_LOADED

local function settings() return db.settings end

local function stationShown(name)
	return settings().stations[name] ~= false
end

local function refresh()
	HandyNotes:UpdatePluginMap(nil, PLUGIN)
end

-- What sits at (uiMapID, coord); a recorded pin wins over a seeded one.
-- Returns station type (nil for a legacy recorded pin), icon, object or user label, source.
local function lookup(uiMapID, coord)
	local rec = db.recorded[uiMapID] and db.recorded[uiMapID][coord]
	if rec then
		local focus = rec.station and FOCUS_BY_NAME[rec.station]
		local category = focus and focus.category or rec.category
		local icon = (CATEGORIES[category] or CATEGORIES.special).icon
		return focus, icon, rec.name, "recorded"
	end
	local index = ns.seed and ns.seed[uiMapID] and ns.seed[uiMapID][coord]
	local kind = index and ns.seedKinds[index]
	local focus = kind and FOCI[kind[2]]
	if focus then
		local name = ENGLISH and kind[1] ~= "" and kind[1] or nil
		return focus, CATEGORIES[focus.category].icon, name, "seed"
	end
end

local function label(focus, name)
	return name or (focus and ns.StationName(focus)) or T["Crafting station"]
end

---------------------------------------------------------------- HandyNotes handler

local handler = {}

function handler:GetNodes2(uiMapID, minimap)
	local s = settings()
	if minimap and not s.minimap then return next, {} end
	local seed = s.showSeed and ns.seed and ns.seed[uiMapID] or nil
	local recorded = s.showRecorded and db.recorded[uiMapID] or nil
	local hidden = db.hidden[uiMapID]
	local phase, tbl, coord = 1, seed, nil
	return function()
		while true do
			if not tbl then
				if phase ~= 1 then return nil end
				phase, tbl, coord = 2, recorded, nil
			else
				local value
				coord, value = next(tbl, coord)
				if coord == nil then
					tbl = nil
				elseif phase == 2 then
					local focus, icon = lookup(uiMapID, coord)
					if icon and (not focus or stationShown(focus.name)) then
						return coord, nil, icon, s.scale, s.alpha
					end
				elseif not ((hidden and hidden[coord]) or (recorded and recorded[coord])) then
					local focus = FOCI[ns.seedKinds[value][2]]
					if focus and stationShown(focus.name) then
						return coord, nil, CATEGORIES[focus.category].icon, s.scale, s.alpha
					end
				end
			end
		end
	end
end

function handler:OnEnter(uiMapID, coord)
	local focus, icon, name, source = lookup(uiMapID, coord)
	if not icon then return end
	local tooltip = GameTooltip
	if self:GetCenter() > UIParent:GetCenter() then
		tooltip:SetOwner(self, "ANCHOR_LEFT")
	else
		tooltip:SetOwner(self, "ANCHOR_RIGHT")
	end
	tooltip:AddLine(label(focus, name))
	local station = focus and ns.StationName(focus)
	if name and station and station ~= name then tooltip:AddLine(station, 1, 1, 1) end
	if source == "recorded" then tooltip:AddLine(T["Recorded by you"], 0.4, 1, 0.4) end
	if TomTom then tooltip:AddLine(T["Click: set a TomTom waypoint"], 0.6, 0.6, 0.6) end
	if source == "recorded" then
		tooltip:AddLine(T["Shift-right-click: delete this pin"], 0.6, 0.6, 0.6)
	else
		tooltip:AddLine(T["Shift-right-click: hide this pin"], 0.6, 0.6, 0.6)
	end
	tooltip:Show()
end

function handler:OnLeave()
	GameTooltip:Hide()
end

local function removeAt(uiMapID, coord)
	local focus, icon, name, source = lookup(uiMapID, coord)
	if not icon then return end
	if source == "recorded" then
		db.recorded[uiMapID][coord] = nil
		if not next(db.recorded[uiMapID]) then db.recorded[uiMapID] = nil end
		ns.Print(T["Deleted your %s pin."], label(focus, name))
	else
		db.hidden[uiMapID] = db.hidden[uiMapID] or {}
		db.hidden[uiMapID][coord] = true
		ns.Print(T["Hid %s. /pstations restore shows hidden pins again."], label(focus, name))
	end
	refresh()
	return true
end

function handler:OnClick(button, down, uiMapID, coord)
	if down then return end
	if button == "RightButton" and IsShiftKeyDown() then
		removeAt(uiMapID, coord)
	elseif button == "LeftButton" and TomTom and TomTom.AddWaypoint then
		local focus, icon, name = lookup(uiMapID, coord)
		if not icon then return end
		local x, y = HandyNotes:getXY(coord)
		TomTom:AddWaypoint(uiMapID, x, y, { title = label(focus, name), persistent = false })
	end
end

---------------------------------------------------------------- options

local function setStation(name, show)
	if show then settings().stations[name] = nil else settings().stations[name] = false end
end

-- One inline section per profession (Cooking first), holding a "Check all" toggle and one
-- toggle per station type its recipes need; a type used by several professions is listed in
-- each, and every listing shares the one setting (keyed by the English name).
local function stationSections()
	local sections = {}
	for order, prof in ipairs(ns.PROFESSION_ORDER) do
		local list = {}
		for _, focus in ipairs(FOCI) do
			if focus.recipes[prof] then list[#list + 1] = focus end
		end
		if #list > 0 then
			table.sort(list, function(a, b)
				if a.recipes[prof] ~= b.recipes[prof] then return a.recipes[prof] > b.recipes[prof] end
				return a.name < b.name
			end)
			local args = {
				all = {
					type = "toggle", order = 0, width = "full", name = T["Check all"],
					desc = Format(T["Show or hide every %s station type below."], ns.ProfessionName(prof)),
					get = function()
						for _, focus in ipairs(list) do
							if not stationShown(focus.name) then return false end
						end
						return true
					end,
					set = function(_, v)
						for _, focus in ipairs(list) do setStation(focus.name, v) end
						refresh()
					end,
				},
			}
			for i, focus in ipairs(list) do
				args["station" .. i] = {
					type = "toggle", order = i,
					name = "|T" .. CATEGORIES[focus.category].icon .. ":0|t " .. ns.StationName(focus),
					get = function() return stationShown(focus.name) end,
					set = function(_, v) setStation(focus.name, v); refresh() end,
				}
			end
			sections[prof] = {
				type = "group", inline = true, order = order, name = ns.ProfessionName(prof), args = args,
			}
		end
	end
	return sections
end

local function options()
	local function getter(info) return settings()[info[#info]] end
	local function setter(info, v) settings()[info[#info]] = v; refresh() end
	return {
		type = "group", name = ns.TITLE, get = getter, set = setter,
		args = {
			about = {
				type = "description", order = 0, width = "full",
				name = function()
					return Format(T["Built-in pins: %s.\nRecord a missing station where you stand with /pstations add <station type>; shift-right-click a wrong pin to hide it."],
						ns.seedSource or T["none for this game"])
				end,
			},
			scale = { type = "range", order = 1, name = T["Icon scale"], min = 0.3, max = 3, step = 0.05 },
			alpha = { type = "range", order = 2, name = T["Icon alpha"], min = 0, max = 1, step = 0.05 },
			minimap = { type = "toggle", order = 3, name = T["Show on the minimap"] },
			showSeed = { type = "toggle", order = 4, name = T["Show built-in pins"] },
			showRecorded = { type = "toggle", order = 5, name = T["Show pins you recorded"] },
			stations = { type = "group", inline = true, order = 10, name = T["Station types"], args = stationSections() },
			restore = {
				type = "execute", order = 20, name = T["Show hidden pins again"],
				func = function() ns.Restore() end,
			},
		},
	}
end

---------------------------------------------------------------- recording

local function playerPosition()
	local uiMapID = C_Map.GetBestMapForUnit("player")
	local pos = uiMapID and C_Map.GetPlayerMapPosition(uiMapID, "player")
	if not pos then return end
	local x, y = pos:GetXY()
	if not x or (x == 0 and y == 0) then return end
	return uiMapID, x, y
end

local function mapName(uiMapID)
	local info = C_Map.GetMapInfo(uiMapID)
	return info and info.name or tostring(uiMapID)
end

-- "<station type> [label]", matched against the English and the client's names: the longest
-- name the text starts with, else the one type whose name starts with the whole text.
-- string.lower folds ASCII only, so other scripts must match their exact case.
local function stationFromInput(text)
	local lower = text:lower()
	local best, bestLength, rest
	for _, focus in ipairs(FOCI) do
		for _, candidate in ipairs({ focus.name, ns.StationName(focus) }) do
			local name = candidate:lower()
			if (lower == name or lower:sub(1, #name + 1) == name .. " ") and (not best or #name > bestLength) then
				best, bestLength, rest = focus, #name, text:sub(#name + 2)
			end
		end
	end
	if best then return best, rest ~= "" and rest or nil end
	local matches = {}
	for _, focus in ipairs(FOCI) do
		local english, here = focus.name:lower(), ns.StationName(focus):lower()
		if lower ~= "" and (english:sub(1, #lower) == lower or here:sub(1, #lower) == lower) then
			matches[#matches + 1] = focus
		end
	end
	if #matches == 1 then return matches[1] end
	return nil, nil, matches
end

local function nearestPin(uiMapID, x, y)
	local width, height = C_Map.GetMapWorldSize(uiMapID)
	if not width or width == 0 then width, height = 1000, 1000 end
	local best, bestDist
	for coord in handler:GetNodes2(uiMapID, false) do
		local px, py = HandyNotes:getXY(coord)
		local d = math.sqrt(((px - x) * width) ^ 2 + ((py - y) * height) ^ 2)
		if not bestDist or d < bestDist then best, bestDist = coord, d end
	end
	return best, bestDist
end

function ns.Restore()
	local n = 0
	for _, coords in pairs(db.hidden) do
		for _ in pairs(coords) do n = n + 1 end
	end
	wipe(db.hidden)
	ns.Print(Plural({ one = "%d hidden pin shown again.", other = "%d hidden pins shown again." }), n, n)
	refresh()
end

local function names(list)
	local out = {}
	for i, focus in ipairs(list) do out[i] = ns.StationName(focus) end
	return table.concat(out, ", ")
end

-- HandyNotes registers its options table as "HandyNotes", with plugins under args.plugins.
local function openOptions(...)
	local dialog = LibStub("AceConfigDialog-3.0", true)
	if dialog then dialog:Open("HandyNotes", ...) end
end

-- Command words are identifiers and stay English; only their descriptions are translated.
local function usage()
	ns.Print(T["Commands:"])
	print("  /pstations options (o) - " .. T["open these settings in HandyNotes"])
	print("  /pstations add " .. T["<station type> [label]"] .. " - " .. T["record a station where you stand"])
	print("  /pstations remove - " .. Format(Plural({
		one = "delete or hide the nearest pin (within %d yard)",
		other = "delete or hide the nearest pin (within %d yards)",
	}), REMOVE_RADIUS_YARDS, REMOVE_RADIUS_YARDS))
	print("  /pstations restore - " .. T["show hidden pins again"])
	print("  /pstations types - " .. T["list the station types"])
	print("  /pstations where - " .. T["your map and position"])
end

SLASH_PROFESSIONSTATIONS1 = "/pstations"
SLASH_PROFESSIONSTATIONS2 = "/pst"
SlashCmdList.PROFESSIONSTATIONS = function(msg)
	local verb, rest = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
	verb = verb:lower()
	if verb == "add" then
		local focus, name, matches = stationFromInput(rest)
		if not focus then
			if matches and #matches > 1 then
				ns.Print(T["Which one? %s"], names(matches))
			else
				ns.Print(T["Unknown station type. /pstations types lists them."])
			end
			return
		end
		local uiMapID, x, y = playerPosition()
		if not uiMapID then ns.Print(T["No map position here (instances have none)."]) return end
		local coord = HandyNotes:getCoord(x, y)
		db.recorded[uiMapID] = db.recorded[uiMapID] or {}
		db.recorded[uiMapID][coord] = { station = focus.name, name = name }
		if db.hidden[uiMapID] then db.hidden[uiMapID][coord] = nil end
		ns.Print(T["Recorded %s at %s %.1f, %.1f."], ns.StationName(focus), mapName(uiMapID), x * 100, y * 100)
		refresh()
	elseif verb == "remove" or verb == "rm" then
		local uiMapID, x, y = playerPosition()
		if not uiMapID then ns.Print(T["No map position here."]) return end
		local coord, dist = nearestPin(uiMapID, x, y)
		if not coord or dist > REMOVE_RADIUS_YARDS then
			ns.Print(Plural({ one = "No shown pin within %d yard.", other = "No shown pin within %d yards." }),
				REMOVE_RADIUS_YARDS, REMOVE_RADIUS_YARDS)
			return
		end
		removeAt(uiMapID, coord)
	elseif verb == "options" or verb == "o" then
		openOptions("plugins", PLUGIN)
	elseif verb == "restore" then
		ns.Restore()
	elseif verb == "types" then
		ns.Print(T["Station types: %s"], names(FOCI))
	elseif verb == "where" then
		local uiMapID, x, y = playerPosition()
		if not uiMapID then ns.Print(T["No map position here."]) return end
		ns.Print("%s (uiMapID %d) %.2f, %.2f", mapName(uiMapID), uiMapID, x * 100, y * 100) -- diagnostic
	else
		usage()
	end
end

-- Addon compartment (minimap addon list) click: the TOC's AddonCompartmentFunc.
function HandyNotes_ProfessionStations_OnCompartmentClick()
	openOptions("plugins", PLUGIN)
end

-- /hn: short alias for /handynotes, unless an addon loaded earlier already owns /hn.
local hnTaken = false
for key, value in pairs(_G) do
	if type(key) == "string" and key:sub(1, 6) == "SLASH_" and value == "/hn" then hnTaken = true break end
end
if not hnTaken then
	SLASH_PROFESSIONSTATIONSHN1 = "/hn"
	SlashCmdList.PROFESSIONSTATIONSHN = function(msg)
		local handynotes = SlashCmdList.ACECONSOLE_HANDYNOTES -- AceConsole's slot for /handynotes
		if handynotes then handynotes(msg) else openOptions() end
	end
end

---------------------------------------------------------------- startup

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, _, name)
	if name ~= ADDON then return end
	self:UnregisterEvent("ADDON_LOADED")
	HandyNotes_ProfessionStationsDB = HandyNotes_ProfessionStationsDB or {}
	db = HandyNotes_ProfessionStationsDB
	db.settings = db.settings or {}
	for k, v in pairs(ns.DEFAULTS) do
		if db.settings[k] == nil then db.settings[k] = type(v) == "table" and {} or v end
	end
	db.settings.categories = nil    -- 0.1.0's per-category toggles, replaced by per-station ones
	db.recorded = db.recorded or {} -- [uiMapID][coord] = { station = English name, name = label }
	db.hidden = db.hidden or {}     -- [uiMapID][coord] = true: seeded pins the player hid
	HandyNotes:RegisterPluginDB(PLUGIN, handler, options())
	for _, reason in ipairs(ns.Locale.rejected) do
		print("|cff33ff99" .. ns.TITLE .. "|r: translation rejected: " .. reason) -- diagnostic
	end
end)
