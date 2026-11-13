local _, ns = ...

local LogFilter = {}
ns.LogFilter = LogFilter

-- Pairing needs a Log Line for each of Your Hits, so the Log Filter must send
-- the player's and the pet's damage and misses, and colour each line by its
-- Line Kind (see LineKind.lua). Only the filter picked above the Combat Log
-- tab sends lines, and its first part holds the message types and the Done
-- By sources (Blizzard_CombatLogProcessor.lua ApplyFilterSettings; Forever
-- Combat Text's Setup.lua). The game refuses a filter that an addon applies
-- during a session, so the fix is written into Blizzard's saved table at
-- logout, and Blizzard applies it at the next load.

-- Done By "Me" and "My pet" (COMBATLOG_FILTER_MINE, COMBATLOG_FILTER_MY_PET).
local OWN_SOURCES = { [0x4511] = true, [0x3111] = true }
-- A damage shield's Hit, such as Thorns, comes in the frame of its line (a
-- live Druid recording, 2026-11-07: 9 of 9), and with no line it is lost.
local EVENTS = {
	"SWING_DAMAGE", "RANGE_DAMAGE", "SPELL_DAMAGE", "SPELL_PERIODIC_DAMAGE", "DAMAGE_SHIELD",
	"SWING_MISSED", "RANGE_MISSED", "SPELL_MISSED", "SPELL_PERIODIC_MISSED", "DAMAGE_SHIELD_MISSED",
}

-- The table at parent[key], made empty first when it is not a table.
local function tableAt(parent, key)
	if type(parent[key]) ~= "table" then
		parent[key] = {}
	end
	return parent[key]
end

local function indexOf(saved, name)
	for index, filter in ipairs(saved.filters) do
		if type(filter) == "table" and filter.name == name then
			return index
		end
	end
end

-- What a part's sourceFlags or destFlags table asks for, as Blizzard's
-- CombatLogProcessor:ApplyFilterSettings reads it: nil (any unit) with no
-- table, "guid" for a string key (one unit's GUID), "none" when no flag is
-- set, or "flags".
local function flagsOf(flags)
	if type(flags) ~= "table" then
		return nil
	end
	local any = false
	for key, on in pairs(flags) do
		if type(key) == "string" then
			return "guid"
		end
		any = any or on
	end
	return any and "flags" or "none"
end

-- Whether a filter part asks only for the player's and the pet's lines, or
-- for none. Each part is a request of its own; a "none" on either side asks
-- for nothing, except that the other side's GUID then stands alone (Blizzard's
-- ApplyFilterSettings). A part such as Done To "Me" asks for lines from every
-- source done to the player, which look like the player's under colours by
-- kind.
local function asksOnlyOwn(part)
	if type(part) ~= "table" then
		return true
	end
	local source, dest = flagsOf(part.sourceFlags), flagsOf(part.destFlags)
	if (source == "none" and dest ~= "guid") or (dest == "none" and source ~= "guid") then
		return true
	end
	if source ~= "flags" then
		return false
	end
	for flag, on in pairs(part.sourceFlags) do
		if on and not OWN_SOURCES[flag] then
			return false
		end
	end
	return true
end

-- The filter's palette (LineKind.PaletteOf), in the fix's colours or
-- another's, when the filter sends what Pairing needs through its first part,
-- asks for no other units' lines through any part, and colours each line so
-- its Line Kind reads back; otherwise nil.
local function pairingPalette(filter)
	local parts = type(filter) == "table" and filter.filters
	local part = type(parts) == "table" and parts[1]
	if type(part) ~= "table" or type(part.sourceFlags) ~= "table" or type(part.eventList) ~= "table"
		or flagsOf(part.destFlags) == "none" then
		return nil
	end
	for flag in pairs(OWN_SOURCES) do
		if part.sourceFlags[flag] ~= true then
			return nil
		end
	end
	for _, event in ipairs(EVENTS) do
		if part.eventList[event] ~= true then
			return nil
		end
	end
	-- With lines coloured by kind, other units' lines look like the player's.
	for _, each in pairs(parts) do
		if not asksOnlyOwn(each) then
			return nil
		end
	end
	return ns.LineKind.PaletteOf(filter)
end

-- How the saved Log Filters (Blizzard_CombatLog_Filters) suit Pairing: "ok",
-- when the picked filter sends what Pairing needs, and only lines it can tell
-- apart, whatever its name or colours; "foreign", when the picked filter is
-- not myActions and colours lines by event type in a way that does not suit,
-- as another addon's can, so a fix would only take turns with that addon
-- (see ADR 0005); otherwise "fixable", when a filter named myActions exists
-- to fix and pick, or "gone", when none does; or nil, when the game has not
-- loaded its Log Filters.
function LogFilter.Check(saved, myActions)
	if type(saved) ~= "table" or type(saved.filters) ~= "table" then
		return nil
	end
	local picked = saved.filters[saved.currentFilter]
	if pairingPalette(picked) then
		return "ok"
	end
	if ns.LineKind.ColouringOf(picked) == "kind" and picked.name ~= myActions then
		return "foreign"
	end
	return indexOf(saved, myActions) and "fixable" or "gone"
end

-- How to read the colour of a Log Line under the picked Log Filter, for
-- LineKind.Of: its palette when the filter colours by event type and suits
-- Pairing, or an empty one, under which every line is "other", when such a
-- filter does not suit, as it may send other units' lines; "source" under
-- colours by source; or nil, when the colour tells nothing.
function LogFilter.Reading(saved)
	if type(saved) ~= "table" or type(saved.filters) ~= "table" then
		return nil
	end
	local picked = saved.filters[saved.currentFilter]
	local colouring = ns.LineKind.ColouringOf(picked)
	if colouring == "kind" then
		return pairingPalette(picked) or {}
	end
	return colouring
end

-- Turns on in the filter named myActions what Check needs, and picks it. It
-- adds message types, makes whole lines take their event's colour, writes
-- each Line Kind's colour for its events, and turns off highlighting for
-- those events; another event it sends whose lines would come near a kind's
-- colour goes back to Blizzard's grey (LineKind.ClearClashes). Done By becomes only "Me" and "My pet", and any other part
-- that asks for other units' lines (such as Done To "Me") asks for none, as
-- those lines would pass for the player's (Forever Combat Text also limits
-- Done By). The player's other choices stay. Returns false, and changes
-- nothing, when no filter has that name.
function LogFilter.Fix(saved, myActions)
	if LogFilter.Check(saved, myActions) == nil then
		return false
	end
	local index = indexOf(saved, myActions)
	if not index then
		return false
	end
	saved.currentFilter = index
	local filter = saved.filters[index]
	local part = tableAt(tableAt(filter, "filters"), 1)
	local eventList = tableAt(part, "eventList")
	part.sourceFlags = {}
	for flag in pairs(OWN_SOURCES) do
		part.sourceFlags[flag] = true
	end
	if flagsOf(part.destFlags) == "none" then
		part.destFlags = nil
	end
	-- With no flag set under destFlags, a part asks for nothing, as Blizzard's
	-- own Done To part of "My actions" does.
	for i, other in pairs(filter.filters) do
		if i ~= 1 and not asksOnlyOwn(other) then
			other.sourceFlags, other.destFlags = nil, {}
		end
	end
	for _, event in ipairs(EVENTS) do
		eventList[event] = true
	end

	ns.LineKind.ColourByKind(tableAt(filter, "settings"))
	local colors = tableAt(filter, "colors")
	local eventColoring, highlightedEvents = tableAt(colors, "eventColoring"), tableAt(colors, "highlightedEvents")
	for event, colour in pairs(ns.LineKind.EventColours()) do
		eventColoring[event] = colour
		highlightedEvents[event] = nil
	end
	ns.LineKind.ClearClashes(filter)
	return true
end
