-- Localisation primitives, ported from SimpleLootCouncil's Core/Locale.lua: T["English"] returns
-- the client locale's translation or the English key; a translation whose format slots or
-- escapes differ from its key is rejected (and listed by /pstations locale) instead of erroring.
local _, ns = ...

local Locale = {}
ns.Locale = Locale

local clientLocale = "enUS"
if type(GetLocale) == "function" then
	local value = GetLocale()
	if type(value) == "string" then clientLocale = value end
end
if clientLocale == "enGB" then clientLocale = "enUS" end
Locale.clientLocale = clientLocale

local registered = {}
Locale.rejected = {}
Locale.Text = setmetatable({}, {
	__index = function(_, key) return registered[key] or key end,
})

-- The printf slots Lua accepts; %% is an escape. Positional indexes (%2$s) are allowed.
local function Slots(message)
	local slots, position = {}, 1
	while true do
		local start = message:find("%", position, true)
		if not start then return slots end
		if message:sub(start + 1, start + 1) == "%" then
			position = start + 2
		else
			local tail = message:sub(start + 1)
			local index = tail:match("^(%d+)%$")
			local cursor = start + 1
			if index then cursor = cursor + #index + 1 end
			local flags = message:sub(cursor):match("^[%-%+ #0]*") or ""
			cursor = cursor + #flags
			local width = message:sub(cursor):match("^%d*") or ""
			cursor = cursor + #width
			if message:sub(cursor, cursor) == "." then
				local precision = message:sub(cursor + 1):match("^%d+")
				if not precision then return nil end
				cursor = cursor + #precision + 1
			end
			local conversion = message:sub(cursor, cursor)
			if not conversion:match("^[cdiouxXeEfgGqs]$") then return nil end
			slots[#slots + 1] = {
				first = start, last = cursor, index = index and tonumber(index), conversion = conversion,
				plain = "%" .. message:sub(start + 1 + (index and #index + 1 or 0), cursor),
			}
			position = cursor + 1
		end
	end
end

local function Escapes(message)
	local tokens, position = {}, 1
	while true do
		local start = message:find("|", position, true)
		if not start then break end
		local tail = message:sub(start)
		local token = tail:match("^|c%x%x%x%x%x%x%x%x") or tail:match("^|[rn]")
			or tail:match("^|T.-|t") or tail:match("^|H.-|h") or tail:match("^||")
		if not token then return nil end
		tokens[#tokens + 1] = token
		position = start + #token
	end
	table.sort(tokens)
	return table.concat(tokens, "\n")
end

local function ValidForm(keySlots, keyEscapes, form, plural)
	if type(form) ~= "string" then return false, "translation is not a string" end
	local slots = Slots(form)
	if not slots then return false, "invalid format slot" end
	if Escapes(form) ~= keyEscapes then return false, "escape mismatch" end
	local positional = false
	for _, slot in ipairs(slots) do
		if slot.index then positional = true end
	end
	if positional then
		for _, slot in ipairs(slots) do
			local original = slot.index and keySlots[slot.index]
			if not original or original.conversion ~= slot.conversion then return false, "slot mismatch" end
		end
	else
		if #slots > #keySlots or (not plural and #slots ~= #keySlots) then return false, "slot mismatch" end
		for index, slot in ipairs(slots) do
			if keySlots[index].conversion ~= slot.conversion then return false, "slot mismatch" end
		end
	end
	return true
end

local function Install(entries)
	for key, value in pairs(entries) do
		local reason
		local keySlots, keyEscapes = Slots(key), Escapes(key)
		if not keySlots or not keyEscapes then
			reason = "invalid key"
		elseif type(value) == "table" then
			if type(value.other) ~= "string" then
				reason = "plural has no other form"
			else
				for name, form in pairs(value) do
					if name ~= "one" and name ~= "few" and name ~= "many" and name ~= "other" then
						reason = "unknown plural form"
						break
					end
					local ok, why = ValidForm(keySlots, keyEscapes, form, true)
					if not ok then reason = why break end
				end
			end
		else
			local ok, why = ValidForm(keySlots, keyEscapes, value, false)
			if not ok then reason = why end
		end
		if reason then
			Locale.rejected[#Locale.rejected + 1] = reason .. " for " .. tostring(key)
		else
			registered[key] = value
		end
	end
end

-- Each Locale\<locale>.lua loads only on its own client ([AllowLoadTextLocale] in the .toc);
-- the locale check also keeps a misfiled table out.
function Locale.Register(locale, entries)
	if locale == clientLocale and type(entries) == "table" then Install(entries) end
end

-- A plural is a table of CLDR forms keyed by its `other` English text:
-- Locale.Format(T.Plural{ one = "%d pin", other = "%d pins" }, n, n)
function Locale.Plural(forms)
	local translated = registered[forms.other]
	return type(translated) == "table" and translated or forms
end

local function PluralForm(count)
	count = tonumber(count)
	if not count or count ~= count or math.abs(count) == math.huge then return "other" end
	count = math.abs(count)
	if clientLocale == "ruRU" and count == math.floor(count) then
		local mod10, mod100 = count % 10, count % 100
		if mod10 == 1 and mod100 ~= 11 then return "one" end
		if mod10 >= 2 and mod10 <= 4 and (mod100 < 12 or mod100 > 14) then return "few" end
		return "many"
	end
	if (clientLocale == "frFR" or clientLocale == "ptBR") and count < 2 then return "one" end
	if clientLocale == "frFR" or clientLocale == "ptBR" or clientLocale == "itIT"
		or clientLocale == "esES" or clientLocale == "esMX" then
		if count ~= 0 and count % 1000000 == 0 then return "many" end
	end
	if clientLocale == "koKR" or clientLocale == "zhCN" or clientLocale == "zhTW" then return "other" end
	return count == 1 and "one" or "other"
end

local function FormatString(format, ...)
	if not format:find("%%%d+%$") then return format:format(...) end
	local slots = Slots(format)
	if not slots then return format:format(...) end
	local pieces, values, last = {}, {}, 1
	for index, slot in ipairs(slots) do
		pieces[#pieces + 1] = format:sub(last, slot.first - 1)
		pieces[#pieces + 1] = slot.plain
		values[index] = (select(slot.index or index, ...))
		last = slot.last + 1
	end
	pieces[#pieces + 1] = format:sub(last)
	return string.format(table.concat(pieces), unpack(values, 1, #slots))
end

-- Locale.Format("Requires %s.", x); with a plural table the first argument picks the form.
function Locale.Format(message, ...)
	if type(message) == "table" then
		local form = message[PluralForm((...))] or message.other
		return FormatString(form, select(2, ...))
	end
	return FormatString(message, ...)
end
