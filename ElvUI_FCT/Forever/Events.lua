local _, ns = ...
local FCT = ns[2]

local function public(value)
	if not issecretvalue(value) then return value end
	return nil
end

local function sameUnit(a, b)
	return a == b or public(UnitIsUnit(a, b)) == true
end

local kinds = {
	WOUND = 'damage', HEAL = 'heal', ABSORB = 'ABSORB', BLOCK = 'BLOCK',
	DEFLECT = 'DEFLECT', DODGE = 'DODGE', EVADE = 'EVADE', IMMUNE = 'IMMUNE',
	MISS = 'MISS', PARRY = 'PARRY', REFLECT = 'REFLECT', RESIST = 'RESIST',
}
local spellTexture = C_Spell.GetSpellTexture

function FCT:StartForeverEvents()
	if self.foreverEventFrame then return end
	local frame = CreateFrame('Frame')
	self.foreverEventFrame = frame
	local plates, facts = {}, {}
	local targetChangedAt = -1
	local function findPlate(unit)
		if plates[unit] then return unit end
		for plate in pairs(plates) do
			if sameUnit(unit, plate) then return plate end
		end
	end
	local function possibleOwner()
		local pet = UnitExists('pet')
		-- UnitExists returns nil as well as false for a unit that doesn't exist.
		if not issecretvalue(pet) and not pet then return 'player' end
		return 'own'
	end

	local function showOwn(hit, spellID, late, swinger, how, lineKind)
		-- An old nameplate token can point at a new mob after a killing blow.
		if late or not kinds[hit.action] then return end
		local source = swinger or (spellID and 'player') or possibleOwner()
		local icon
		if spellID then icon = spellTexture(spellID)
		elseif swinger == 'player' then icon = spellTexture(6603)
		elseif swinger == 'pet' then icon = PET_ATTACK_TEXTURE end
		FCT:ForeverCombat(hit.unit, hit.amount, kinds[hit.action], public(hit.descriptor) == 'CRITICAL',
			spellID, public(hit.school), source, ns.LineKind.Group(lineKind) == 'tick', icon, 'own')
	end
	local flow = ns.Flow.New({
		show = showOwn,
		noPlate = function(hit)
			if hit.unit == 'target' and hit.time > targetChangedAt then showOwn(hit) end
		end,
		spellFacts = facts,
	})

	-- UNIT_COMBAT issues a separate report for each visible token naming a
	-- unit. For each action take the longest per-token list in the frame.
	-- Keeping the entire list preserves simultaneous hits on the same mob.
	local raw, heals, frameTime = {}, {}, nil
	local function addRaw(unit, action, descriptor, amount, school, hostile, plate)
		local group
		for _, candidate in ipairs(raw) do
			if candidate.action == action and sameUnit(candidate.unit, unit) then
				group = candidate
				break
			end
		end
		if not group then
			group = { unit = plate or unit, action = action, hostile = hostile, tokens = {}, hits = {} }
			raw[#raw+1] = group
		end
		local list = group.tokens[unit]
		if not list then list = {}; group.tokens[unit] = list end
		list[#list+1] = { amount, public(descriptor) == 'CRITICAL', public(school) }
		if #list > #group.hits then group.hits = list end
	end
	local function flush()
		if #raw > 0 then
			local healCount = 0
			for _, group in ipairs(raw) do
				if group.action == 'HEAL' then healCount = healCount + #group.hits end
			end
			-- A line has no destination. Attribute heals only when the counts
			-- agree and all lines represent the same kind of heal.
			local ownHeals = healCount > 0 and healCount == #heals
			for i = 2, #heals do
				if heals[i] ~= heals[1] then ownHeals = false end
			end
			for _, group in ipairs(raw) do
				local isHeal = group.action == 'HEAL'
				local source = isHeal and ownHeals and possibleOwner() or nil
				local periodic = isHeal and ownHeals and heals[1] == 'hot'
				local audience = group.hostile and not isHeal and 'all' or nil
				for _, hit in ipairs(group.hits) do
					FCT:ForeverCombat(group.unit, hit[1], kinds[group.action], hit[2], nil,
						hit[3], source, periodic, nil, audience)
				end
			end
		end
		wipe(raw)
		wipe(heals)
		frameTime = nil
	end
	local function keepFiltered()
		local enabled = C_CombatLog.AreFilteredEventsEnabled()
		if not issecretvalue(enabled) and not enabled then C_CombatLog.SetFilteredEventsEnabled(true) end
	end
	local filter, reading, nextRead = nil, nil, 0
	local function logKind(now, r, g, b)
		local saved = Blizzard_CombatLog_Filters
		local selected = saved and saved.filters and saved.filters[saved.currentFilter]
		if selected ~= filter or now >= nextRead then
			filter, reading, nextRead = selected, ns.LogFilter.Reading(saved), now + 1
		end
		if not reading or type(public(r)) ~= 'number' or type(public(g)) ~= 'number'
			or type(public(b)) ~= 'number' then return 'other' end
		return ns.LineKind.Of(r, g, b, reading)
	end
	frame:SetScript('OnEvent', function(_, event, ...)
		local now = GetTime()
		local entry = { now, event, ... }
		local unit = entry[3]
		if frameTime and now ~= frameTime then flush() end
		frameTime = now
		if event == 'UNIT_COMBAT' then
			local action = public(entry[4])
			if not action or not kinds[action] or issecretvalue(unit) then return end
			local own = sameUnit(unit, 'player') and 'player' or sameUnit(unit, 'pet') and 'pet'
			entry.own = own or nil
			local canAttack = UnitCanAttack('player', unit)
			if not issecretvalue(canAttack) then entry.canAttack = not not canAttack end
			entry.plate = findPlate(unit)
			if not entry.plate then entry.guid = public(UnitGUID(unit)) end
			local hostile = not own and entry.canAttack ~= false
			addRaw(unit, action, entry[5], entry[6], entry[7], hostile, entry.plate)
		elseif event == 'COMBAT_LOG_MESSAGE' then
			if public(entry[7]) == Enum.CombatLogMessageOrder.Oldest then return end
			entry.lineKind = logKind(now, entry[4], entry[5], entry[6])
			entry.hasPet = public(UnitExists('pet')) == true
			if entry.lineKind == 'heal' or entry.lineKind == 'hot' then
				heals[#heals+1] = entry.lineKind
			end
		elseif event == 'NAME_PLATE_UNIT_ADDED' then
			entry.frame = ns.GetForeverPlate(unit)
			plates[unit] = entry.frame
		elseif event == 'NAME_PLATE_UNIT_REMOVED' then
			entry.frame = plates[unit]
			plates[unit] = nil
			entry.guid = public(UnitGUID(unit))
			for i = #raw, 1, -1 do
				if raw[i].unit == unit then table.remove(raw, i) end
			end
		elseif ns.Adapter.CAST_STAGES[event] and unit == 'player' then
			entry.target = findPlate('target')
		elseif event == 'PLAYER_TARGET_CHANGED' then
			targetChangedAt = now
			for i = #raw, 1, -1 do
				if raw[i].unit == 'target' then table.remove(raw, i) end
			end
		elseif event == 'PLAYER_EQUIPMENT_CHANGED' then
			if unit == GetInventorySlotInfo('RangedSlot') then wipe(facts) end
			return
		elseif event == 'PLAYER_SWING' then
			entry[4] = public(entry[4])
		end
		flow.Push(entry)
	end)
	frame:SetScript('OnUpdate', function()
		local now = GetTime()
		if frameTime and now > frameTime then flush() end
		flow.Tick(now)
	end)
	for i = 1, 40 do
		local unit = 'nameplate'..i
		if public(UnitExists(unit)) then plates[unit] = ns.GetForeverPlate(unit) end
	end
	for _, event in ipairs({ 'UNIT_COMBAT', 'COMBAT_LOG_MESSAGE', 'PLAYER_SWING', 'PLAYER_TARGET_CHANGED',
		'PLAYER_EQUIPMENT_CHANGED', 'NAME_PLATE_UNIT_ADDED', 'NAME_PLATE_UNIT_REMOVED' }) do
		frame:RegisterEvent(event)
	end
	for event in pairs(ns.Adapter.CAST_STAGES) do frame:RegisterUnitEvent(event, 'player', 'pet') end
	keepFiltered()
	self.foreverLogTicker = C_Timer.NewTicker(2, keepFiltered)
end
