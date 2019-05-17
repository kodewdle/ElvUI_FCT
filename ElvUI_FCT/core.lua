local E, L, V, P, G = unpack(ElvUI)

local oUF = E.oUF or oUF
if not oUF then return end

local _, ns = ...
local FCT = ns[2]
local S = E:GetModule('Skins')

local wipe, tinsert, tremove = wipe, tinsert, tremove
local bit, type, unpack, next = bit, type, unpack, next
local sin, cos, pi, rand = math.sin, math.cos, math.pi, math.random
local band, guid, uisu, gsi, cf = bit.band, UnitGUID, UnitIsUnit, GetSpellInfo, CreateFrame
local info = CombatLogGetCurrentEventInfo
local buln = BreakUpLargeNumbers

ns.objects, ns.spells, ns.color, ns.fallback = {}, {}, {}, {1,1,1}
ns.CT = E:CopyTable({}, _G.CombatFeedbackText)
ns.CT.MISFIRE = _G.COMBAT_TEXT_MISFIRE

local harlemShake = {
	StopIt = function(object)
		if object then
			E:StopShake(object)
			object.isShaking = nil
		end
	end,
	ShakeIt = function(object, delay)
		if object and object:IsShown() and not object:IsForbidden() then
			E:Shake(object)
			return E:Delay(delay, ns.HS.StopIt, object)
		end
	end}
ns.HS = harlemShake

local lightspark = {
	animations = {
		fountain = function(s) return s.x + s.xDirection * s.radius * (1 - cos(pi / 2 * s.progress)), s.y + s.yDirection * s.radius * sin(pi / 2 * s.progress) end,
		vertical = function(s) return s.x, s.y + s.yDirection * s.radius * s.progress end,
		horizontal = function(s) return s.x + s.xDirection * s.radius * s.progress, s.y end,
		diagonal = function(s) return s.x + s.xDirection * s.radius * s.progress, s.y + s.yDirection * s.radius * s.progress end,
		static = function(s) return s.x, s.y end,
		random = function(s) if s.elapsed == 0 then s.x, s.y = rand(-s.radius * 0.66, s.radius * 0.66), rand(-s.radius * 0.66, s.radius * 0.66) end return s.x, s.y end},
	clamp = function(v) if v > 1 then return 1 elseif v < 0 then return 0 end return v end,
	removeText = function(fb, i, text)
		tremove(fb.objs, i)

		if text then
			text:Hide()
			text.Icon:Hide()
			text.Icon.backdrop:Hide()
			text.Spell:SetText('')

			return text
		end
	end,
	getText = function(fb)
		if not fb.texts then return end
		for i = 1, #fb.texts do
			if not fb.texts[i]:IsShown() then
				return fb.texts[i]
			end
		end

		return ns.LS.removeText(fb, 1, fb.objs[1])
	end,
	onUpdate = function(frame, elapsed)
		for index, text in next, frame.ElvFCT.objs do
			if text.elapsed >= text.scrollTime then
				ns.LS.removeText(frame.ElvFCT, index, text)
			else
				text.progress = text.elapsed / text.scrollTime
				text:SetPoint("CENTER", frame, "CENTER", text:GetXY())

				text.elapsed = text.elapsed + elapsed
				text.frame:SetAlpha(ns.LS.clamp(1 - (text.elapsed - text.fadeTime) / (text.scrollTime - text.fadeTime)))
			end
		end
	end,
	onShowHide = function(frame)
		if frame.ElvFCT.objs then
			wipe(frame.ElvFCT.objs)
		end

		if frame.ElvFCT.texts then
			for i = 1, #frame.ElvFCT.texts do
				frame.ElvFCT.texts[i]:Hide()
				frame.ElvFCT.texts[i].Icon:Hide()
				frame.ElvFCT.texts[i].Icon.backdrop:Hide()
				frame.ElvFCT.texts[i].Spell:SetText('')
			end
		end
	end}
ns.LS = lightspark

local Simpy = {
	FadeOut = function(a,d,f,e)
		local z = a.owner.ElvFCT.FadeOut
		z.timeToFade = d
		z.startAlpha = f
		z.endAlpha = e
		E:UIFrameFade(a, z)
	end,
	FadeIn = function(z,a,b,c,d,e,f)
		z.timeToFade	= b --timeToFade (In)
		z.fadeHoldTime	= c --fadeHoldTime
		z.startAlpha	= e --startAlpha
		z.endAlpha		= f --endAlpha
		z.finishedFunc	= ns.SI.FadeOut --finishedFunc
		z.finishedArg1	= a --frame
		z.finishedArg2	= d --timeToFade (Out)
		z.finishedArg3	= f --endAlpha (startAlpha)
		z.finishedArg4	= e --startAlpha (endAlpha)
		E:UIFrameFade(a, z)
	end}
ns.SI = Simpy

function FCT:RecolorText(t)
	if not (t.types and t.types[1] and t.typeTime) then return end

	t:SetTextColor(unpack(t.types[1]))
	tremove(t.types, 1)

	if #t.types >= 1 then
		E:Delay(t.typeTime, FCT.RecolorText, FCT, t)
	end
end

function FCT:GP(t, fb, b, a)
	if not a then
		return ns.color[01] or ns.fallback
	end

	if fb.cycleColors then
		if not t.types then
			t.types = {}
		else
			wipe(t.types)
		end

		for x, z in next, ns.color do
			if x > 1 and band(x, a) > 0 then
				tinsert(t.types, z)
			end
		end

		if next(t.types) then
			local c = t.types[1]
			tremove(t.types, 1)

			if #t.types >= 1 then
				t.typeTime = (t.fadeTime + ((fb.mode == 'Simpy' and b and 0.3) or 0)) / #t.types
				E:Delay(t.typeTime, FCT.RecolorText, FCT, t)
			end

			return c
		else
			return ns.color[01] or ns.fallback
		end
	else
		for x, z in next, ns.color do
			if x > 1 and band(x, a) > 0 then
				return z
			end
		end

		return ns.color[01] or ns.fallback
	end
end

function FCT:StyleNumber(style, number)
	if style == 'BLIZZARD' then
		return buln(number)
	elseif style == 'SHORT' then
		return E:ShortValue(number)
	else
		return number
	end
end

function FCT:Update(frame, fb)
	local a, b, c, d -- amount, critical, spellSchool, dmgColor
	local _, e, _, f, _, _, _, g, _, _, _, h, _, i, j, _, _, k, _, _, l = info()
	-- event (2nd), sourceGUID (4th), destGUID (8th), 1st Parameter [spellId] (12th), spellSchool (14th), 1st Param (15th), 4th Param (18th), 7th Param [critical] (21st)

	if g ~= guid(frame.unit) then return end -- needs to be the frames unit!

	local tb, pb
	if fb.isTarget and not (g == guid('target') and uisu(frame.unit, 'target')) then
		tb = true
	end
	if fb.isPlayer then
		local y = g == E.myguid and uisu(frame.unit, 'player')
		local z = f == E.myguid or (fb.showPet and f == guid('pet'))
		if y or z then -- its player
			if fb.isPlayer == 1 and tb then tb = false end -- allow player on all
		elseif fb.isPlayer ~= 1 then -- dont pb when we are doing this
			pb = true
		end
	end
	if tb or pb then return end

	if e == 'SPELL_HEAL' or (fb.showHots and e == 'SPELL_PERIODIC_HEAL') then
		if not fb.exclude[h] then a, b, d = j, k, ns.color[-3] end
	elseif e == 'RANGE_DAMAGE' then
		a, b, d = j, l, ns.color[-2]
	elseif e == 'SWING_DAMAGE' then
		a, b, d = h, k, ns.color[-1]
	elseif e == 'SPELL_DAMAGE' or (fb.showDots and e == 'SPELL_PERIODIC_DAMAGE') then
		a, b, c = j, l, i
	elseif e == 'SPELL_MISSED' or e == 'RANGE_MISSED' then
		a = j
	elseif e == 'SWING_MISSED' then
		a = h
	end

	if (type(a) == 'number' and a > 0) or type(a) == 'string' then
		if (fb.showIcon or fb.showName) and not (e == 'SWING_DAMAGE' or ns.spells[h]) then ns.spells[h] = {gsi(h)} end

		local text
		if fb.mode == 'Simpy' then
			text = fb.Text
			if not text then return end
		elseif fb.mode == 'LS' then
			text = ns.LS.getText(fb)
			if not text then return end

			if text.alternateX then text.xDirection = -text.xDirection end
			if text.alternateY then text.yDirection = -text.yDirection end
			text.elapsed = 0
		end

		if fb.showIcon or fb.showName then
			local spell = ns.spells[h]
			if spell then
				if fb.showIcon then
					if (e ~= 'SWING_DAMAGE') and spell[3] then
						text.Icon:SetTexture(spell[3])
						text.Icon.backdrop:Show()
						text.Icon:Show()

						if fb.alternateIcon then
							text.Icon:ClearAllPoints()
							if text.xDirection < 0 then
								text.Icon:Point('RIGHT', text, 'LEFT', fb.iconX, fb.iconY)
							else
								text.Icon:Point('LEFT', text, 'RIGHT', -fb.iconX, fb.iconY)
							end
						end
					else
						text.Icon.backdrop:Hide()
						text.Icon:Hide()
					end
				end
				if fb.showName then
					text.Spell:SetText(spell[1] or '')
				end
			else
				text.Icon:Hide()
				text.Icon.backdrop:Hide()
				text.Spell:SetText('')
			end
		end

		text:FontTemplate(fb.font, fb.fontSize + (b and 4 or 0), fb.fontOutline)
		text:SetTextColor(unpack(d or (ns.CT[a] and ns.color[00]) or FCT:GP(text, fb, b, c)))
		text:SetText(ns.CT[a] or FCT:StyleNumber(fb.numberStyle, a))
		text:Show()

		if b then
			if fb.critShake then
				if not fb.owner.isShaking then
					fb.owner.isShaking = ns.HS.ShakeIt(fb.owner, fb.shakeDuration)
				end
			elseif fb.textShake then
				if not text.isShaking then
					text.isShaking = ns.HS.ShakeIt(text, fb.shakeDuration)
				end
			end
		end

		if fb.mode == 'Simpy' then
			if not fb.FadeOut then fb.FadeOut = { mode = 'OUT' } else fb.FadeOut.fadeTimer = nil end
			if not fb.FaderIn then fb.FaderIn = { mode = 'IN' } else fb.FaderIn.fadeTimer = nil end
			ns.SI.FadeIn(fb.FaderIn, fb.Frame, 0.2, text.fadeTime + (b and 0.3 or 0), 0.4, 0.0, 0.8)
		elseif fb.mode == 'LS' then
			tinsert(fb.objs, text)
			text.frame:SetAlpha(1)
		end
end end

function FCT:EnableMode(fb, mode)
	if mode == 'Simpy' then
		if not fb.Frame then
			fb.Frame = cf('Frame', fb.owner:GetDebugName()..'ElvFCT', fb.parent)
			fb.Frame.owner = fb.owner

			local frameName = fb.Frame:GetDebugName()
			fb.Text = fb.Frame:CreateFontString(frameName..'Text', 'OVERLAY')
			fb.Text:FontTemplate(fb.font, fb.fontSize, fb.fontOutline)

			fb.Text.Icon = fb.Frame:CreateTexture(frameName..'Icon')
			S:HandleIcon(fb.Text.Icon, true)

			fb.Text.Spell = fb.Frame:CreateFontString(frameName..'Spell', 'OVERLAY')
			fb.Text.Spell:FontTemplate(fb.font, fb.fontSize, fb.fontOutline)
		end

		fb.Text:Point('CENTER', fb.parent, 'CENTER', fb.textX, fb.textY)
		fb.Text.Spell:Point('BOTTOM', fb.Text, 'TOP', fb.spellX, fb.spellY)
		fb.Text.Icon:Point('RIGHT', fb.Text, 'LEFT', fb.iconX, fb.iconY)
		fb.Text.Icon:Size(fb.iconSize)

		fb.Text.fadeTime   = fb.FadeTime
		fb.Text.xDirection = fb.DirectionX
		fb.Text.yDirection = fb.DirectionY

		fb.Text.Spell:SetText('')
		fb.Text.Icon.backdrop:Hide()
		fb.Text.Icon:Hide()
		fb.Text:Hide()
	elseif mode == 'LS' then
		if not fb.objs then fb.objs = {} end
		if not fb.texts then fb.texts = {} end

		for i=1, fb.numTexts do
			if not fb.texts[i] then
				local frame = cf('Frame', fb.owner:GetDebugName()..'ElvFCT'..i, fb.parent)

				local frameName = frame:GetDebugName()
				local text = frame:CreateFontString(frameName..'Text', 'OVERLAY')
				text:FontTemplate(fb.font, fb.fontSize, fb.fontOutline)
				text.frame = frame

				text.Icon = frame:CreateTexture(frameName..'Icon')
				S:HandleIcon(text.Icon, true)

				text.Spell = frame:CreateFontString(frameName..'Spell', 'OVERLAY')
				text.Spell:FontTemplate(fb.font, fb.fontSize, fb.fontOutline)

				fb.texts[i] = text
			end

			fb.texts[i].Icon:Size(fb.iconSize)
			fb.texts[i].Icon:Point('RIGHT', fb.texts[i], 'LEFT', fb.iconX, fb.iconY)
			fb.texts[i].Spell:Point('BOTTOM', fb.texts[i], 'TOP', fb.spellX, fb.spellY)

			fb.texts[i].fadeTime   = fb.FadeTime
			fb.texts[i].xDirection = fb.DirectionX
			fb.texts[i].yDirection = fb.DirectionY

			fb.texts[i].radius     = fb.radius
			fb.texts[i].scrollTime = fb.ScrollTime
			fb.texts[i].alternateX = fb.AlternateX
			fb.texts[i].alternateY = fb.AlternateY

			fb.texts[i].x = fb.texts[i].xDirection * fb.OffsetX
			fb.texts[i].y = fb.texts[i].yDirection * fb.OffsetY
			fb.texts[i].GetXY = ns.LS.animations[fb.anim]
			fb.texts[i].elapsed = 0

			fb.texts[i].Spell:SetText('')
			fb.texts[i].Icon.backdrop:Hide()
			fb.texts[i].Icon:Hide()
			fb.texts[i]:Hide()
		end

		if not fb.owner.ElvFCTHooked then
			fb.owner:HookScript("OnHide", ns.LS.onShowHide)
			fb.owner:HookScript("OnShow", ns.LS.onShowHide)
			fb.owner:HookScript("OnUpdate", ns.LS.onUpdate)
			fb.owner.ElvFCTHooked = true
		end
	end
end

function FCT:SetOptions(fb, db)
	fb.font = E.Libs.LSM:Fetch('font', db.font)
	fb.fontSize = db.fontSize
	fb.fontOutline = db.fontOutline
	fb.alternateIcon = db.alternateIcon
	fb.shakeDuration = db.shakeDuration
	fb.cycleColors = db.cycleColors
	fb.numberStyle = db.numberStyle
	fb.critShake = db.critShake
	fb.textShake = db.textShake
	fb.showIcon = db.showIcon
	fb.showName = db.showName
	fb.showHots = db.showHots
	fb.showDots = db.showDots
	fb.isTarget = db.isTarget
	fb.isPlayer = db.isPlayer
	fb.iconSize = db.iconSize
	fb.showPet = db.showPet
	fb.exclude = db.exclude
	fb.mode = db.mode

	-- offsets
	fb.textX = db.textX
	fb.textY = db.textY
	fb.iconX = db.iconX
	fb.iconY = db.iconY
	fb.spellX = db.spellX
	fb.spellY = db.spellY

	-- advanced animation settings
	fb.anim = db.advanced.anim
	fb.numTexts = db.advanced.numTexts
	fb.radius = db.advanced.radius
	fb.FadeTime = db.advanced.FadeTime
	fb.ScrollTime = db.advanced.ScrollTime
	fb.DirectionX = db.advanced.DirectionX
	fb.DirectionY = db.advanced.DirectionY
	fb.AlternateX = db.advanced.AlternateX
	fb.AlternateY = db.advanced.AlternateY
	fb.OffsetX = db.advanced.OffsetX
	fb.OffsetY = db.advanced.OffsetY
end

function FCT:COMBAT_LOG_EVENT_UNFILTERED()
	for object, texts in next, ns.objects do
		FCT:Update(object, texts)
	end
end

function FCT:Toggle(frame, module, db)
	local fb = frame.ElvFCT
	if fb and db then
		if db.enable and FCT.db[module].enable then
			FCT:Enable(frame, db)
		else
			FCT:Disable(frame, db)
		end
	end
end

function FCT:Enable(frame, db)
	local fb = frame.ElvFCT
	if fb and db then
		FCT:SetOptions(fb, db)
		FCT:EnableMode(fb, db.mode)

		if not ns.objects[fb.owner] then
			ns.objects[fb.owner] = fb
		end
	end
end

function FCT:Disable(frame)
	local fb = frame.ElvFCT
	if fb then
		ns.LS.onShowHide(frame)

		if ns.objects[fb.owner] then
			ns.objects[fb.owner] = nil
		end
	end
end
