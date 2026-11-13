local _, ns = ...

local Adapter = {}
ns.Adapter = Adapter

-- Enemy tokens that can report a unit with no nameplate. With no plate to tell
-- units apart, their reports in one frame are taken to name one unit, so they
-- merge like the repeats on a plate. The Hit is named by the first token here.
local ENEMY_TOKEN_RANK = { target = 1, softenemy = 2, softinteract = 3 }
local NO_PLATE = "<no plate>"

-- How long after a Nameplate hides a report on its unit can still come. A
-- melee Hit comes one Swing Delay after its Log Line, and the kill can hide the
-- Nameplate first (Warrior Trace: hide at 0.267 s, Hit at 0.300 s, on
-- softinteract only). A Weapon Proc's Hit can come later than a swing's, so this
-- is the longer of the two delays.
local LATE_REPORT_WINDOW = ns.LineKind.LONGEST_PROC_DELAY

-- Hits on the player and the pet stay, so Pairing can give the Log Lines for
-- heals and self-damage to them, not to an enemy's Hit. Events.lua records
-- `own` on any report that names one of them; Traces from before that field
-- name them only by these tokens.
local OWN_UNITS = { player = true, pet = true }
Adapter.OWN_UNITS = OWN_UNITS

-- The cast events, and the stage of each. UNIT_SPELLCAST_SENT has its own
-- branch in Push, since its arguments differ.
local CAST_STAGES = {
	UNIT_SPELLCAST_SENT = "SENT",
	UNIT_SPELLCAST_START = "START",
	UNIT_SPELLCAST_SUCCEEDED = "SUCCEEDED",
	UNIT_SPELLCAST_INTERRUPTED = "INTERRUPTED",
	UNIT_SPELLCAST_CHANNEL_START = "CHANNEL_START",
	UNIT_SPELLCAST_CHANNEL_STOP = "CHANNEL_STOP",
}
Adapter.CAST_STAGES = CAST_STAGES

-- The unit a report names: player or pet, or else the nameplate token that
-- Events.lua recorded with it. Returns nil for a token whose reports only
-- repeat others, such as targettarget, and for a nameplate that Events.lua
-- never saw added: in a dungeon a friendly plate reports combat without
-- NAME_PLATE_UNIT_ADDED, and Plate Text is for enemies only. Also nil for a
-- unit the player cannot attack, such as a friendly player that a mob hits
-- in the open world, so its Hit cannot take the player's Log Line; Traces
-- from before canAttack keep every such Hit.
local function unitOf(entry)
	local token = entry[3]
	if entry.own then
		return entry.own
	end
	if entry.canAttack == false then
		return nil
	end
	if OWN_UNITS[token] then
		return token
	end
	if entry.plate then
		return entry.plate
	end
	if ENEMY_TOKEN_RANK[token] then
		return NO_PLATE
	end
end

-- When a chat frame opens, the game sends old lines again to fill it; they are
-- not new combat. A secret order cannot be compared, so such a line is kept.
local function isRefill(order)
	local orders = Enum and Enum.CombatLogMessageOrder
	return orders ~= nil and not issecretvalue(order) and order == orders.Oldest
end

local function byEntry(a, b)
	return a.entry < b.entry
end

local RANGED_SWING = 2 -- Enum.PlayerSwingType.Ranged
Adapter.RANGED_SWING = RANGED_SWING

-- PLAYER_SWING comes for the player's own swings only, in the frame of the
-- swing's Log Line (each of the player's 20 swing lines in the Warlock Traces
-- had one in its frame; none of the pet's 114 did). So a melee Log Line in a
-- frame with no main-hand or off-hand swing is the pet's, and gets pet. A
-- wand's swing does not count, as a pet swing could come in its frame (not
-- seen in the Traces). When the player and the pet swing in one frame, which
-- line is whose is not known, so all of them stay the player's. So does a
-- line that came while the player had no pet: PLAYER_SWING is tested only on
-- a Warlock's main hand, and a melee class's extra attack or off-hand swing
-- could come without one. A Trace from before Events.lua recorded hasPet
-- counts as having a pet.
local function markPetSwings(records)
	for _, record in ipairs(records) do
		if record.kind == "swing" and record.swingType ~= RANGED_SWING then
			return
		end
	end
	for _, record in ipairs(records) do
		if record.kind == "line" and ns.LineKind.IsMelee(record.lineKind) and record.hasPet ~= false then
			record.pet = true
		end
	end
end

-- The game sends one report of a Hit for each token that names the unit. So,
-- for one unit and action in a frame, the token with the most reports gives
-- the number of Hits, and the Nth report of each token is a repeat of the Nth
-- Hit. A Hit's entry number is that of its earliest repeat. Reports on two
-- plate lives of one token, as when it hides and shows a new unit in one
-- frame, are two units.
local function addHits(reports, records)
	local groups, order = {}, {}
	for _, report in ipairs(reports) do
		local key = report.unit .. "\0" .. report.action .. "\0" .. tostring(report.life)
		local group = groups[key]
		if not group then
			group = { unit = report.unit, life = report.life, byToken = {}, tokens = {} }
			groups[key] = group
			order[#order + 1] = group
		end
		local token = report.token
		if not group.byToken[token] then
			group.byToken[token] = {}
			group.tokens[#group.tokens + 1] = token
		end
		table.insert(group.byToken[token], report)
	end

	for _, group in ipairs(order) do
		local most = group.byToken[group.tokens[1]]
		for _, token in ipairs(group.tokens) do
			if #group.byToken[token] > #most then
				most = group.byToken[token]
			end
		end
		local unit = group.unit
		if unit == NO_PLATE then
			for _, token in ipairs(group.tokens) do
				if unit == NO_PLATE or ENEMY_TOKEN_RANK[token] < ENEMY_TOKEN_RANK[unit] then
					unit = token
				end
			end
		end
		for n, report in ipairs(most) do
			local first = report.index
			for _, token in ipairs(group.tokens) do
				local repeated = group.byToken[token][n]
				if repeated and repeated.index < first then
					first = repeated.index
				end
			end
			records[#records + 1] = {
				kind = "hit",
				time = report.time,
				entry = first,
				unit = unit,
				life = group.life,
				action = report.action,
				descriptor = report.descriptor,
				amount = report.amount,
				school = report.school,
			}
		end
	end
end

-- Turns raw events, in the shape of Trace entries, into Hits, Log Lines (with
-- the Line Kind that Events.lua read from the line's colour, and pet on the
-- pet's swing lines), casts, and swings. All events of one frame share a
-- GetTime(), so a frame's records leave together through onRecord, in entry
-- order, once a later event or tick shows that the frame is over.
function Adapter.New(onRecord)
	local count = 0
	local frameTime
	local records, reports = {}, {}

	local function closeFrame()
		-- Other records arrive in entry order, so only Hits need a sort.
		if #reports > 0 then
			addHits(reports, records)
			table.sort(records, byEntry)
		end
		markPetSwings(records)
		local closed = records
		records, reports, frameTime = {}, {}, nil
		for _, record in ipairs(closed) do
			onRecord(record)
		end
	end

	-- Each Nameplate token's current plate life: one unit's time on the token.
	-- A Hit keeps the life that its reports came in, so Flow knows whether its
	-- Nameplate hid, and which one, however often the token moves on before
	-- Pairing decides the Hit. At the hide, hid is the Nameplate as it hid
	-- (see Flow.New); reused says that its frame has shown a unit since.
	local lives, lifeOnFrame = {}, {}
	-- Nameplates that hid within LATE_REPORT_WINDOW, by their unit's public GUID.
	-- A secret GUID cannot be compared, so such a Nameplate is not here, and a
	-- late report on its unit stays with no Nameplate (unverified how often this
	-- happens in dungeons).
	local hiddenByGuid = {}

	local function rememberHidden(entry, life)
		local time, guid = entry[1], entry.guid
		for known, hidden in pairs(hiddenByGuid) do
			if time - hidden.time > LATE_REPORT_WINDOW then
				hiddenByGuid[known] = nil
			end
		end
		if guid ~= nil and not issecretvalue(guid) then
			hiddenByGuid[guid] = { time = time, token = entry[3], life = life }
		end
	end

	local function hiddenFor(entry)
		local guid = entry.guid
		if guid == nil or issecretvalue(guid) then
			return nil
		end
		local hidden = hiddenByGuid[guid]
		if hidden and entry[1] - hidden.time <= LATE_REPORT_WINDOW then
			return hidden
		end
	end

	-- A token that showed before the first event, as after a /reload, starts
	-- its life when the adapter first sees it.
	local function lifeOf(token)
		lives[token] = lives[token] or {}
		return lives[token]
	end

	local function add(entry, record)
		record.time = entry[1]
		record.entry = count
		records[#records + 1] = record
	end

	local adapter = {}

	-- Entry numbers count every pushed event, so they match the Trace. Returns
	-- the entry's number.
	function adapter.Push(entry)
		count = count + 1
		local time, event = entry[1], entry[2]
		if frameTime and time ~= frameTime then
			closeFrame()
		end
		frameTime = time

		if event == "NAME_PLATE_UNIT_ADDED" then
			local life = {}
			lives[entry[3]] = life
			if entry.frame then
				if lifeOnFrame[entry.frame] then
					lifeOnFrame[entry.frame].reused = true
				end
				lifeOnFrame[entry.frame] = life
			end
		elseif event == "NAME_PLATE_UNIT_REMOVED" then
			local life = lifeOf(entry[3])
			life.hid = { frame = entry.frame, wasTarget = entry.wasTarget, classification = entry.classification,
				isBoss = entry.isBoss, isPlayer = entry.isPlayer }
			if entry.frame then
				lifeOnFrame[entry.frame] = life
			end
			lives[entry[3]] = nil
			rememberHidden(entry, life)
			add(entry, { kind = "hide" })
		elseif event == "UNIT_COMBAT" then
			local unit = unitOf(entry)
			if unit then
				local hidden = unit == NO_PLATE and hiddenFor(entry) or nil
				reports[#reports + 1] = {
					index = count,
					unit = hidden and hidden.token or unit,
					life = hidden and hidden.life or (unit == entry.plate and lifeOf(unit)) or nil,
					token = entry[3],
					time = time,
					action = entry[4],
					descriptor = entry[5],
					amount = entry[6],
					school = entry[7],
				}
			end
		elseif event == "COMBAT_LOG_MESSAGE" then
			if not isRefill(entry[7]) then
				add(entry, { kind = "line", lineKind = entry.lineKind, hasPet = entry.hasPet })
			end
		elseif event == "UNIT_SPELLCAST_SENT" then
			-- entry[4] is the target's name, which can be secret.
			add(entry, { kind = "cast", stage = "SENT", unit = entry[3], spellID = entry[6] })
		elseif CAST_STAGES[event] then
			add(entry, { kind = "cast", stage = CAST_STAGES[event], unit = entry[3], spellID = entry[5],
				target = entry.target, targetLife = entry.target and lifeOf(entry.target) or nil })
		elseif event == "PLAYER_SWING" then
			add(entry, { kind = "swing", swingType = entry[4] })
		end
		return count
	end

	function adapter.Tick(now)
		if frameTime and now > frameTime then
			closeFrame()
		end
	end

	return adapter
end
