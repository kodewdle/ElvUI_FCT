local _, ns = ...
local FCT = ns[2]
local stack = ns.SH
local guid, uisu, uhm = UnitGUID, UnitIsUnit, UnitHealthMax

-- On Forever, animate on the addon's overlay. A Blizzard nameplate can
-- disappear, change unit or become restricted while combat text is visible.
function ns.LS.onUpdate(frame, elapsed)
	for index = #frame.ElvFCT.objs, 1, -1 do
		local text = frame.ElvFCT.objs[index]
		if text.elapsed >= text.scrollTime then
			ns.LS.removeText(frame.ElvFCT, index, text)
		else
			text.progress = text.elapsed / text.scrollTime
			text:SetPoint('CENTER', frame, text:GetXY())

			text.elapsed = text.elapsed + elapsed
			if text.scrollTime > text.fadeTime then
				text.frame:SetAlpha(ns.LS.clamp(1 - (text.elapsed - text.fadeTime) / (text.scrollTime - text.fadeTime)))
			end
		end
	end
	if #frame.ElvFCT.objs == 0 then frame:SetScript('OnUpdate', nil) end
end

local clearAnimation = ns.LS.onShowHide
function ns.LS.onShowHide(frame)
	frame:SetScript('OnUpdate', nil)
	clearAnimation(frame)
end

local formatNumber = FCT.StyleNumber
function FCT:StyleNumber(unit, style, number)
	if style == 'PERCENT' then
		local maximum = uhm(unit)
		if issecretvalue(maximum) or not maximum or maximum <= 0 then return number end
		return string.format('%.2f%%', (number / maximum) * 100)
	end
	return formatNumber(self, unit, style, number)
end

local function sameUnit(first, second)
	if first == second then return true end
	local same = uisu(first, second)
	return not issecretvalue(same) and same
end

function FCT:Update(fb, data)
	local unit = fb.isNameplate and fb.unit or fb.owner.unit
	if issecretvalue(unit) or not unit or not fb.owner:IsVisible() or not sameUnit(unit, data.unit) then return end
	if (data.audience == 'all' and fb.isPlayer) or (data.audience == 'own' and not fb.isPlayer) then return end

	local sourceMe = data.source == 'player' or data.source == 'pet' or data.source == 'own'
	local allowedSource = data.source == 'player' or (fb.showPet and sourceMe) or sameUnit(unit, 'player')
	if fb.isPlayer and fb.isPlayer ~= 1 and not allowedSource then return end
	if fb.isTarget and not (fb.isPlayer == 1 and allowedSource) and not sameUnit(unit, 'target') then return end

	local kind, spellID = data.kind, data.spellID
	local healing = kind == 'heal'
	if data.periodic and ((healing and not fb.showHots) or (not healing and not fb.showDots)) then return end
	local ex = spellID and FCT.db.exclude[spellID]
	if ex and (ex.global or ex[fb.frametype]) then return end

	local value = data.amount
	local isMiss = kind ~= 'damage' and not healing
	if isMiss then value = kind end
	local hidden = issecretvalue(value)
	local positiveAmount = not hidden and type(value) == 'number' and value > 0
	if not (hidden or positiveAmount or isMiss) then return end

	-- A delayed stack is safe only while this token still represents its original unit.
	local totals = data[fb]
	if data.stackGUID then
		local currentGUID = guid(unit)
		if issecretvalue(currentGUID) or currentGUID ~= data.stackGUID or not totals then return end
	end

	-- handle stacking spells
	local wantsStack = (fb.stackingSelf and sourceMe) or (fb.stackingOthers and not sourceMe)
	local destination
	if wantsStack and not totals and positiveAmount and spellID and not FCT.db.stacks.exclude[spellID] then
		local destGUID = guid(unit)
		if not issecretvalue(destGUID) then destination = destGUID end
	end
	if totals then
		if not wantsStack or totals.amount <= 0 then return end
	elseif destination then
		local key = spellID..'^'..kind..'^'..(data.source or 'unknown')..'^'..(data.audience or 'normal')..(data.periodic and '^tick' or '')
		if stack:Collect(key, destination, fb, data, value, data.critical, data.periodic) then return end
	end

	stack:CheckShown()
	if hidden then
		if fb.numberStyle == 'SHORT' then
			value = AbbreviateNumbers(value)
		else
			value = BreakUpLargeNumbers(value)
		end
	end
	FCT:Display(fb, unit, {
		amount = value, critical = data.critical, school = data.school, color = healing and ns.color.Heal,
		spellID = spellID, icon = data.icon,
		label = isMiss and (ns.CT[kind] or _G['ACTION_SPELL_MISSED_'..kind] or kind),
		restricted = hidden, stack = totals,
	})
end

function FCT:ForeverCombat(unit, amount, kind, critical, spellID, school, source, periodic, icon, audience)
	local data = {
		unit = unit, amount = amount, kind = kind, critical = critical,
		spellID = spellID, school = school, source = source, periodic = periodic,
		icon = icon, audience = audience,
	}
	for fb in next, ns.objects do
		FCT:Update(fb, data)
	end
end

function FCT:Enable(frame, db)
	local fb = ns.frameInfo[frame]
	if fb and db then
		FCT:Disable(frame)
		fb.raised:Show()
		FCT:SetOptions(fb, db)
		FCT:EnableMode(fb, db.mode)

		if not ns.objects[fb] then
			ns.objects[fb] = true
		end
	end
end

function FCT:Disable(frame)
	local fb = ns.frameInfo[frame]
	if fb then
		fb.raised:Hide()
		fb.raised:SetScript('OnUpdate', nil)
		if fb.Text then
			fb.Text:Hide()
			fb.Text.Icon:Hide()
			fb.Text.Icon.backdrop:Hide()
			fb.Text.Spell:SetText('')
		end

		if ns.objects[fb] then
			ns.objects[fb] = nil
		end
	end
end
