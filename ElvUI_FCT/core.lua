local E, L, V, P, G = unpack(ElvUI)
local _, ns = ...

local oUF = E.oUF or oUF
if not oUF then return end

local FCT = ns[2]
local S = E:GetModule('Skins')

local wipe, tinsert, tremove = wipe, tinsert, tremove
local bit, type, unpack, next = bit, type, unpack, next
local sin, cos, pi, rand = math.sin, math.cos, math.pi, math.random
local band, guid, uisu, gsi, cf = bit.band, UnitGUID, UnitIsUnit, GetSpellInfo, CreateFrame
local info = CombatLogGetCurrentEventInfo

ns.objects, ns.spells = {}, {}
ns.CT, ns.SC = E:CopyTable({}, CombatFeedbackText), ns.colors
ns.CT.MISFIRE = _G.COMBAT_TEXT_MISFIRE

local harlemShake = {
	StopIt = function(object)
		if object then
			E:StopShake(object)
			object.isShaking = nil
		end
	end,
	ShakeIt = function(object, delay)
		if object and not object:IsForbidden() and object:IsShown() then
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
	xOffsets = {diagonal = 24, fountain = 24, horizontal = 8, random = 0, static = 0, vertical = 8},
	yOffsets = {diagonal = 8, fountain = 8, horizontal = 8, random = 0, static = 0, vertical = 8},
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
		for i = 1, #fb.texts do
			if not fb.texts[i]:IsShown() then
				return fb.texts[i]
			end
		end

		return ns.LS.removeText(fb, 1, fb.objs[1])
	end,
	onUpdate = function(frame, elapsed)
		for index, text in next, frame.Feedback.objs do
			if text.elapsed >= text.scrollTime then
				ns.LS.removeText(frame.Feedback, index, text)
			else

			text.progress = text.elapsed / text.scrollTime
			text:SetPoint("CENTER", frame, "CENTER", text:GetXY())

			text.elapsed = text.elapsed + elapsed
			text.frame:SetAlpha(ns.LS.clamp(1 - (text.elapsed - text.fadeTime) / (text.scrollTime - text.fadeTime)))
			end
		end
	end,
	onShowHide = function(frame)
		wipe(frame.Feedback.objs)

		for i = 1, #frame.Feedback.texts do
			frame.Feedback.texts[i]:Hide()
			frame.Feedback.texts[i].Icon:Hide()
			frame.Feedback.texts[i].Icon.backdrop:Hide()
			frame.Feedback.texts[i].Spell:SetText('')
		end
	end}
ns.LS = lightspark

local Simpy = {
	FadeOut = function(a,d,f,e)
		local z = a.owner.Feedback.FadeOut
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

function FCT:GP(a)
	for x, z in next, ns.SC do
		if x > 1 and band(x,a) > 0 then
			return z
		end
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
		if not fb.exclude[h] then a, b, d = j, k, ns.SC[-3] end
	elseif e == 'RANGE_DAMAGE' then
		a, b, d = j, l, ns.SC[-2]
	elseif e == 'SWING_DAMAGE' then
		a, b, d = h, k, ns.SC[-1]
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
		elseif fb.mode == 'LS' then
			text = ns.LS.getText(fb)
			if not text then return end

			if text.alternateX then text.xDirection = text.xDirection * -1 end
			if text.alternateY then text.yDirection = text.yDirection * -1 end
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
								text.Icon:Point('RIGHT', text, 'LEFT', -5, 0)
							else
								text.Icon:Point('LEFT', text, 'RIGHT', 5, 0)
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

		if fb.critShake and b and not frame.isShaking then
			frame.isShaking = ns.HS.ShakeIt(frame, fb.shakeDuration)
		elseif fb.textShake and b and not text.isShaking then
			text.isShaking = ns.HS.ShakeIt(text, fb.shakeDuration)
		end

		text:FontTemplate(fb.font, fb.fontSize + (b and 4 or 0), fb.fontOutline)
		text:SetTextColor(unpack(d or (ns.CT[a] and ns.SC[00]) or GP(c) or ns.SC[01]))
		text:SetText(ns.CT[a] or a)

		if fb.mode == 'Simpy' then
			if not fb.FadeOut then fb.FadeOut = { mode = 'OUT' } else fb.FadeOut.fadeTimer = nil end
			if not fb.FaderIn then fb.FaderIn = { mode = 'IN' } else fb.FaderIn.fadeTimer = nil end
			ns.SI.FadeIn(fb.FaderIn, fb.Frame, 0.2, 0.7 + (b and 0.3 or 0), 0.4, 0.0, 0.8)
		elseif fb.mode == 'LS' then
			tinsert(fb.objs, text)
			text.frame:SetAlpha(1)
			text:Show()
		end
end end

function FCT:EnableMode(fb, parent, mode)
	if mode == 'Simpy' then
		fb.Frame = cf('Frame', parent:GetDebugName()..'Feedback', parent)
		local frameName = fb.Frame:GetDebugName()
		fb.Frame.owner = fb.owner

		fb.Text = fb.Frame:CreateFontString(frameName..'Text', 'OVERLAY')
		fb.Text:FontTemplate(fb.font, fb.fontSize, fb.fontOutline)
		fb.Text:Point('CENTER', x.Health)
		fb.Text.Icon = fb.Frame:CreateTexture(frameName..'Icon')
		fb.Text.Icon:Point('RIGHT', fb.Text, 'LEFT', -10, 0)
		fb.Text.Icon:Size(16, 16)
		S:HandleIcon(fb.Text.Icon, true)
		fb.Text.Icon.backdrop:Hide()
		fb.Text.Icon:Hide()
		fb.Text.Spell = fb.Frame:CreateFontString(frameName..'Spell', 'OVERLAY')
		fb.Text.Spell:FontTemplate(fb.font, fb.fontSize, fb.fontOutline)
		fb.Text.Spell:Point('BOTTOM', fb.Text, 'TOP', 5, 0)
	elseif mode == 'LS' then
		fb.objs, fb.texts = {}, {}

		for i=1, fb.numTexts do
			local frame = cf('Frame', parent:GetDebugName()..'Feedback'..i, parent)
			local frameName = frame:GetDebugName()
			local text = frame:CreateFontString(frameName..'Text', 'OVERLAY')
			text:FontTemplate(fb.font, fb.fontSize, fb.fontOutline)
			text.Icon = frame:CreateTexture(frameName..'Icon')
			text.Icon:Point('RIGHT', text, 'LEFT', -5, 0)
			text.Icon:Size(16, 16)
			S:HandleIcon(text.Icon, true)
			text.Icon.backdrop:Hide()
			text.Icon:Hide()
			text.Spell = frame:CreateFontString(frameName..'Spell', 'OVERLAY')
			text.Spell:FontTemplate(fb.font, fb.fontSize, fb.fontOutline)
			text.Spell:Point('BOTTOM', text, 'TOP', 0, 5)

			text.radius     = fb.radius
			text.scrollTime = fb.ScrollTime
			text.fadeTime   = fb.FadeTime
			text.xDirection = fb.DirectionX
			text.yDirection = fb.DirectionY
			text.alternateX = fb.AlternateX
			text.alternateY = fb.AlternateY

			text.x = text.xDirection * ns.LS.xOffsets[fb.anim]
			text.y = text.yDirection * ns.LS.yOffsets[fb.anim]
			text.GetXY = ns.LS.animations[fb.anim]
			text.elapsed = 0
			text.frame = frame
			fb.texts[i] = text
		end

		fb.owner:HookScript("OnHide", ns.LS.onShowHide)
		fb.owner:HookScript("OnShow", ns.LS.onShowHide)
		fb.owner:HookScript("OnUpdate", ns.LS.onUpdate)
	end
end

function FCT:SetOptions(fb, db)
	fb.enable = db.enable
	fb.font = db.font
	fb.fontSize = db.fontSize
	fb.fontOutline = db.fontOutline
	fb.alternateIcon = db.alternateIcon
	fb.shakeDuration = db.shakeDuration
	fb.critShake = db.critShake
	fb.textShake = db.textShake
	fb.showIcon = fb.showIcon
	fb.showName = fb.showName
	fb.showHots = fb.showHots
	fb.showDots = fb.showDots
	fb.isTarget = fb.isTarget
	fb.isPlayer = fb.isPlayer
	fb.showPet = fb.showPet
	fb.exclude = fb.exclude
	fb.mode = db.mode

	-- advanced animation settings
	fb.anim = db.advanced.anim
	fb.numTexts = db.advanced.numTexts
	fb.radius = db.advanced.radius
	fb.FadeTime = db.advanced.FadeTime
	fb.ScrollTime = db.advanced.ScrollTime
	fb.DirectionX = db.advanced.DirectionX
	fb.DirectionY = db.advanced.DirectionY
	fb.AlternateY = db.advanced.AlternateY
	fb.AlternateX = db.advanced.AlternateX
end

--[[
	function FCT:Hook(x)
		local fb = x and x.Feedback
		if not (fb and fb.owner) or ns.objects[fb.owner] then return end

		ns.objects[fb.owner] = fb

		local parent = fb.parent or x
		if fb.mode == 'Simpy' then
		elseif fb.mode == 'LS' then
		end
	end
]]

function FCT:COMBAT_LOG_EVENT_UNFILTERED()
	for object, texts in next, ns.objects do
		ns:Update(object, texts)
	end
end
