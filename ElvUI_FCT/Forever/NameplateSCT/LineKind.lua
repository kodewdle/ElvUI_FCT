local _, ns = ...

local LineKind = {}
ns.LineKind = LineKind

-- A Log Line reaches addons with no words, so its colour is the only thing
-- in it that tells its Line Kind. A Log Filter that colours each line by its
-- event type (settings.lineColorPriority 3) has a colour for each event in
-- colors.eventColoring, and a line is read by the colours of the filter that
-- is active when it comes (see ADR 0005; PaletteOf). The colours here are the
-- ones the Log Filter fix writes (ADR 0003). Each is about 0.1 or more apart
-- in some channel (0.098 as 8-bit values) from every other one here and from
-- the 0.5 grey that Blizzard gives an event with no colour.
-- reports is the sort of Hit the kind comes with: "damage" (a WOUND), "miss"
-- (an avoid action), or "heal". A killing blow line comes with no Hit of its
-- own. group is the sort of spell behind the line, a hit or its miss alike:
-- "direct", "tick", or "shot", or none for a kind with no spell to tell.
local KINDS = {
	direct = { r = 1.00, g = 0.85, b = 0.25, reports = "damage", group = "direct" },
	tick = { r = 0.75, g = 0.55, b = 1.00, reports = "damage", group = "tick" },
	swing = { r = 0.85, g = 0.85, b = 0.85, reports = "damage", melee = true },
	shot = { r = 0.90, g = 0.70, b = 0.45, reports = "damage", group = "shot" },
	shield = { r = 1.00, g = 0.55, b = 0.20, reports = "damage" },
	directMiss = { r = 0.55, g = 0.65, b = 0.85, reports = "miss", group = "direct" },
	tickMiss = { r = 0.65, g = 0.50, b = 0.85, reports = "miss", group = "tick" },
	swingMiss = { r = 0.60, g = 0.60, b = 0.60, reports = "miss", melee = true },
	shotMiss = { r = 0.75, g = 0.60, b = 0.50, reports = "miss", group = "shot" },
	shieldMiss = { r = 0.70, g = 0.55, b = 0.35, reports = "miss" },
	heal = { r = 0.30, g = 1.00, b = 0.40, reports = "heal" },
	hot = { r = 0.55, g = 0.85, b = 0.55, reports = "heal" },
	kill = { r = 1.00, g = 1.00, b = 1.00 },
}

-- Under colours by source, Blizzard gives the player's and the pet's lines
-- 0.70 grey (COMBATLOG_DEFAULT_COLORS unitColoring), so a line in any other
-- colour is another unit's, or the player's highlighted killing blow.
local OWN_BY_SOURCE = { r = 0.70, g = 0.70, b = 0.70 }
LineKind.OWN_BY_SOURCE = OWN_BY_SOURCE
-- The longest a melee Hit comes after its Log Line: one Swing Delay. Pairing's
-- melee window ends here.
LineKind.LONGEST_SWING_DELAY = 1.1
-- The longest a Weapon Proc's Hit comes after its Log Line. Pairing keeps a proc
-- line this long, and the adapter a Nameplate that hid, as the kill can hide it
-- before the Hit comes. The longest seen is 1.41 s (a Shaman's Trace, issue #48).
LineKind.LONGEST_PROC_DELAY = 1.45
-- Blizzard's lineColorPriority values, and the colouring each one gives.
local BY_SOURCE, BY_EVENT_TYPE = 1, 3
local COLOURINGS = { [BY_SOURCE] = "source", [BY_EVENT_TYPE] = "kind" }

-- Colours arrive as 8-bit floats, such as 0.70196 for a 0.7 setting.
local TOLERANCE = 0.02
-- A Line Kind's colour must be more than this from every other colour a line
-- can come in, so a line within TOLERANCE of it is that kind.
local APART = 2 * TOLERANCE
-- Saved colours are the floats a filter's writer stored, or 8-bit ones after
-- an edit in Blizzard's settings, so two events' colours this close are one.
local SAVED_TOLERANCE = 0.005
-- Blizzard's colour for an event with no colour of its own, and how much
-- brighter highlighting makes a highlighted event's line, at most white
-- (Blizzard_CombatLogProcessor.lua GenerateMessage).
local UNCOLOURED = { r = 0.5, g = 0.5, b = 0.5 }
local HIGHLIGHT = 1.5

-- The event names Blizzard colours a line by. SPELL_MISSED always has its
-- miss type added (SPELL_MISSED_RESIST), and with Blizzard's "full text" on
-- the other misses have it too (Blizzard_CombatLogProcessor.lua).
local MISS_TYPES = { "ABSORB", "BLOCK", "DEFLECT", "DODGE", "EVADE", "IMMUNE", "MISS", "PARRY", "REFLECT", "RESIST" }
local EVENT_KINDS = {
	SPELL_DAMAGE = "direct",
	SPELL_LEECH = "direct",
	SPELL_PERIODIC_DAMAGE = "tick",
	SPELL_PERIODIC_LEECH = "tick",
	SWING_DAMAGE = "swing",
	RANGE_DAMAGE = "shot",
	DAMAGE_SHIELD = "shield",
	SPELL_MISSED = "directMiss",
	SPELL_PERIODIC_MISSED = "tickMiss",
	SWING_MISSED = "swingMiss",
	RANGE_MISSED = "shotMiss",
	DAMAGE_SHIELD_MISSED = "shieldMiss",
	SPELL_HEAL = "heal",
	SPELL_PERIODIC_HEAL = "hot",
	PARTY_KILL = "kill",
}
for _, event in ipairs({ "SPELL_MISSED", "SPELL_PERIODIC_MISSED", "SWING_MISSED", "RANGE_MISSED",
	"DAMAGE_SHIELD_MISSED" }) do
	for _, missType in ipairs(MISS_TYPES) do
		EVENT_KINDS[event .. "_" .. missType] = EVENT_KINDS[event]
	end
end

-- Events of no Line Kind that a filter may colour as one, whose lines then
-- read as that kind: MikScrollingBattleText colours a hit on a building as a
-- direct hit, and a heal on one as a heal. Any other event in a kind's colour
-- would pass for that kind, as an interrupt would pass for a direct hit.
local ALIASES = { SPELL_BUILDING_DAMAGE = "direct", SPELL_BUILDING_HEAL = "heal" }

-- Whether a public colour is within tolerance of colour in every channel, by
-- default the tolerance of a Log Line's colour.
local function near(r, g, b, colour, tolerance)
	tolerance = tolerance or TOLERANCE
	return math.abs(r - colour.r) <= tolerance and math.abs(g - colour.g) <= tolerance
		and math.abs(b - colour.b) <= tolerance
end
LineKind.Near = near

-- How a Log Filter, as Blizzard_CombatLog_Filters stores one, colours whole
-- lines: "kind" (by event type, as the fix sets), "source", or nil when the
-- colour of a line tells nothing about it, as when lines take their target's
-- colour or are not coloured (all white).
function LineKind.ColouringOf(filter)
	local settings = type(filter) == "table" and filter.settings
	if type(settings) ~= "table" or settings.lineColoring ~= true then
		return nil
	end
	return COLOURINGS[settings.lineColorPriority]
end

-- Makes a Log Filter's settings colour whole lines by kind.
function LineKind.ColourByKind(settings)
	settings.lineColoring = true
	settings.lineColorPriority = BY_EVENT_TYPE
end

-- A saved filter's colour for an event, or nil when it has none.
local function savedColour(eventColoring, event)
	local colour = eventColoring[event]
	if type(colour) == "table" and type(colour.r) == "number" and type(colour.g) == "number"
		and type(colour.b) == "number" then
		return colour
	end
end

-- The events a saved filter highlights, by name.
local function highlightedOf(filter)
	local colors = filter.colors
	return filter.settings.lineHighlighting and type(colors.highlightedEvents) == "table"
		and colors.highlightedEvents or {}
end

-- The events a saved filter sends: those on in the event list of any of its
-- parts. A part that asks for no unit sends none, but its events count here
-- too, which errs on the safe side. Blizzard colours some lines by the event
-- name with a suffix, such as SPELL_DISPEL_DEBUFF for a sent SPELL_DISPEL, so
-- any colour or highlight key that starts with a sent event's name and "_"
-- counts as sent too.
local function sentEvents(filter)
	local sent = {}
	for _, part in pairs(type(filter.filters) == "table" and filter.filters or {}) do
		if type(part) == "table" and type(part.eventList) == "table" then
			for event, on in pairs(part.eventList) do
				if on == true then
					sent[event] = true
				end
			end
		end
	end
	local suffixed = {}
	for _, keys in ipairs({ filter.colors.eventColoring, filter.colors.highlightedEvents }) do
		for key in pairs(type(keys) == "table" and keys or {}) do
			for event in pairs(sent) do
				if type(key) == "string" and key:sub(1, #event + 1) == event .. "_" then
					suffixed[key] = true
				end
			end
		end
	end
	for key in pairs(suffixed) do
		sent[key] = true
	end
	return sent
end

-- The colour of a saved filter's event lines: its own, or Blizzard's grey;
-- and brighter when the filter highlights it.
local function shownColour(colors, highlighted, event)
	local colour = savedColour(colors.eventColoring, event) or UNCOLOURED
	if not highlighted[event] then
		return colour
	end
	return { r = math.min(colour.r * HIGHLIGHT, 1), g = math.min(colour.g * HIGHLIGHT, 1),
		b = math.min(colour.b * HIGHLIGHT, 1) }
end

-- Whether the lines of an event of no Line Kind come within APART of a kind's
-- colour, other than in exactly the colour of the kind it is an alias of.
local function clashes(palette, event, colour)
	for kind, kindColour in pairs(palette) do
		if near(colour.r, colour.g, colour.b, kindColour, APART)
			and not (ALIASES[event] == kind and near(colour.r, colour.g, colour.b, kindColour, SAVED_TOLERANCE)) then
			return true
		end
	end
	return false
end

-- The colour of each Line Kind under a Log Filter, as Blizzard_CombatLog_Filters
-- stores one: { [kind] = { r, g, b } }, when the filter colours whole lines by
-- event type and its colours tell every kind apart; otherwise nil. Every kind
-- needs a colour, given to each of its events and to none of them brightened
-- by highlighting, and more than APART from every other kind's colour and
-- from Blizzard's grey for an event with no colour. The lines of every other
-- event the filter sends, in its colour or grey and brightened when it is
-- highlighted, must be that far from them too, except an alias in exactly
-- its kind's colour (see ALIASES).
function LineKind.PaletteOf(filter)
	local colors = type(filter) == "table" and filter.colors
	if LineKind.ColouringOf(filter) ~= "kind" or type(colors) ~= "table" or type(colors.eventColoring) ~= "table" then
		return nil
	end
	local highlighted = highlightedOf(filter)
	local palette = {}
	for event, kind in pairs(EVENT_KINDS) do
		local colour = savedColour(colors.eventColoring, event)
		if not colour or highlighted[event] then
			return nil
		end
		local known = palette[kind]
		if known and not near(colour.r, colour.g, colour.b, known, SAVED_TOLERANCE) then
			return nil
		end
		palette[kind] = known or colour
	end
	for kind, colour in pairs(palette) do
		if near(colour.r, colour.g, colour.b, UNCOLOURED, APART) then
			return nil
		end
		for otherKind, otherColour in pairs(palette) do
			if otherKind ~= kind and near(colour.r, colour.g, colour.b, otherColour, APART) then
				return nil
			end
		end
	end
	for event in pairs(sentEvents(filter)) do
		if not EVENT_KINDS[event] and clashes(palette, event, shownColour(colors, highlighted, event)) then
			return nil
		end
	end
	return palette
end

-- Gives each event the filter sends that is of no Line Kind, and whose lines
-- would come near a kind's colour, Blizzard's grey with no highlight, which
-- is far from every kind's colour here. For the fix, once it has written
-- these colours, so the filter it leaves tells every kind apart.
function LineKind.ClearClashes(filter)
	local colors = filter.colors
	local highlighted = highlightedOf(filter)
	for event in pairs(sentEvents(filter)) do
		if not EVENT_KINDS[event] and clashes(KINDS, event, shownColour(colors, highlighted, event)) then
			colors.eventColoring[event] = nil
			highlighted[event] = nil
		end
	end
end

-- The Line Kind of a Log Line in this colour, read as reading says: by a
-- palette (see PaletteOf), one of its kinds, or "other" for any other colour,
-- such as Blizzard's grey for an event with no colour; "source", for lines
-- coloured by source, nil (the colour tells nothing) for the player's and the
-- pet's grey and "other" for any other colour; or nil, under any other
-- colouring or for a secret colour.
function LineKind.Of(r, g, b, reading)
	if not reading or issecretvalue(r) or issecretvalue(g) or issecretvalue(b) then
		return nil
	end
	if reading == "source" then
		return not near(r, g, b, OWN_BY_SOURCE) and "other" or nil
	end
	for kind, colour in pairs(reading) do
		if near(r, g, b, colour) then
			return kind
		end
	end
	return "other"
end

-- The Line Kind of a combat log event, by its name, or nil for an event of
-- no kind.
function LineKind.OfEvent(event)
	return EVENT_KINDS[event]
end

-- The Line Kind that an event of no kind can read as, when its filter gives it
-- that kind's colour (see ALIASES), or nil.
function LineKind.AliasOf(event)
	return ALIASES[event]
end

-- The sort of Hit that a line of this kind comes with: "damage", "miss",
-- "heal", or nil for a kind that comes with no Hit.
function LineKind.Reports(kind)
	return KINDS[kind] and KINDS[kind].reports
end

-- The sort of spell behind a line of this kind: "direct", "tick", "shot", or
-- nil for a kind with no spell to tell or one that tells nothing.
function LineKind.Group(kind)
	return KINDS[kind] and KINDS[kind].group
end

-- Whether a line of this kind is melee, so it comes one Swing Delay early.
-- A kind that tells nothing (nil) or no Hit ("other") is not.
function LineKind.IsMelee(kind)
	local known = KINDS[kind]
	return known ~= nil and known.melee == true
end

-- Every event the Log Filter colours, with its kind's colour as
-- Blizzard_CombatLog_Filters stores one: { [event] = { r, g, b, a } }.
function LineKind.EventColours()
	local colours = {}
	for event, kind in pairs(EVENT_KINDS) do
		local colour = KINDS[kind]
		colours[event] = { r = colour.r, g = colour.g, b = colour.b, a = 1 }
	end
	return colours
end
