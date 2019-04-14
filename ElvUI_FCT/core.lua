local E, L, V, P, G = unpack(ElvUI); --Inport: Engine, Locales, PrivateDB, ProfileDB, GlobalDB, Localize Underscore
local S = E:GetModule('Skins')

local oUF = E.oUF or oUF
if not oUF then return end

local wipe, tinsert, tremove = wipe, tinsert, tremove
local bit, type, unpack, next = bit, type, unpack, next
local sin, cos, pi, rand = math.sin, math.cos, math.pi, math.random
local band, guid, uisu, gsi, cf = bit.band, UnitGUID, UnitIsUnit, GetSpellInfo, CreateFrame
local info = CombatLogGetCurrentEventInfo

local spells, exclude = {}, {}
local CT, SC = CombatFeedbackText, {
	[-3] = {050/255, 255/255, 050/255}, -- [32FF32] Heal
	[-2] = {102/255, 102/255, 102/255}, -- [666666] Ranged
	[-1] = {153/255, 102/255, 051/255}, -- [996633] Physical
	[00] = {255/255, 255/255, 255/255}, -- [FFFFFF] Standard
	[01] = {255/255, 050/255, 050/255}, -- [FF3232] Damage
	[02] = {255/255, 255/255, 075/255}, -- [FFFF4B] Holy
	[04] = {255/255, 100/255, 000/255}, -- [FF6400] Fire
	[08] = {150/255, 255/255, 050/255}, -- [96FF32] Nature
	[16] = {075/255, 255/255, 255/255}, -- [4BFFFF] Frost
	[32] = {175/255, 075/255, 255/255}, -- [AF4BFF] Shadow
	[64] = {255/255, 075/255, 175/255}} -- [FF4BAF] Arcane
CT.MISFIRE = COMBAT_TEXT_MISFIRE

local HS
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
			return E:Delay(delay, HS.StopIt, object)
		end
	end}
HS = harlemShake

local LS
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

		return LS.removeText(fb, 1, fb.objs[1])
	end,
	onUpdate = function(frame, elapsed)
		for index, text in next, frame.Feedback.objs do
			if text.elapsed >= text.scrollTime then
				LS.removeText(frame.Feedback, index, text)
			else

			text.progress = text.elapsed / text.scrollTime
			text:SetPoint("CENTER", frame, "CENTER", text:GetXY())

			text.elapsed = text.elapsed + elapsed
			text.frame:SetAlpha(LS.clamp(1 - (text.elapsed - text.fadeTime) / (text.scrollTime - text.fadeTime)))
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
LS = lightspark

local SI
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
		z.finishedFunc	= SI.FadeOut --finishedFunc
		z.finishedArg1	= a --frame
		z.finishedArg2	= d --timeToFade (Out)
		z.finishedArg3	= f --endAlpha (startAlpha)
		z.finishedArg4	= e --startAlpha (endAlpha)
		E:UIFrameFade(a, z)
	end}
SI = Simpy

local function GP(a)
	for x, z in next, SC do
		if x > 1 and band(x,a) > 0 then
			return z
		end
	end
end

local function Update(frame, fb)
	local a, b, c, d -- amount, critical, spellSchool, dmgColor
	local _, e, _, f, _, _, _, g, _, _, _, h, _, i, j, _, _, k, _, _, l = info()
	-- event (2nd), sourceGUID (4th), destGUID (8th), 1st Parameter [spellId] (12th), spellSchool (14th), 1st Param (15th), 4th Param (18th), 7th Param [critical] (21st)

	if g ~= guid(frame.unit) then return end -- needs to be the frames unit!

	local tBreak, pBreak
	if fb.isTarget and not (g == guid('target') and uisu(frame.unit, 'target')) then
		tBreak = true
	end
	if fb.isPlayer then
		local y = g == E.myguid and uisu(frame.unit, 'player')
		local z = f == E.myguid or (fb.showPet and f == guid('pet'))
		if y or z then -- its player
			if fb.isPlayer == 1 and tBreak then tBreak = false end -- allow player on all
		elseif fb.isPlayer ~= 1 then -- dont pBreak when we are doing this
			pBreak = true
		end
	end
	if tBreak or pBreak then return end

	if e == 'SPELL_HEAL' or (fb.showHots and e == 'SPELL_PERIODIC_HEAL') then
		if not exclude[h] then a, b, d = j, k, SC[-3] end
	elseif e == 'RANGE_DAMAGE' then
		a, b, d = j, l, SC[-2]
	elseif e == 'SWING_DAMAGE' then
		a, b, d = h, k, SC[-1]
	elseif e == 'SPELL_DAMAGE' or (fb.showDots and e == 'SPELL_PERIODIC_DAMAGE') then
		a, b, c = j, l, i
	elseif e == 'SPELL_MISSED' or e == 'RANGE_MISSED' then
		a = j
	elseif e == 'SWING_MISSED' then
		a = h
	end

	if (type(a) == 'number' and a > 0) or type(a) == 'string' then
		if (fb.showIcon or fb.showName) and not (e == 'SWING_DAMAGE' or spells[h]) then spells[h] = {gsi(h)} end

		local text
		if fb.mode == 'Simpy' then
			text = fb.Text
		elseif fb.mode == 'LS' then
			text = LS.getText(fb)
			if not text then return end

			if text.alternateX then text.xDirection = text.xDirection * -1 end
			if text.alternateY then text.yDirection = text.yDirection * -1 end
			text.elapsed = 0
		end

		if fb.showIcon or fb.showName then
			local spell = spells[h]
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
			frame.isShaking = HS.ShakeIt(frame, fb.shakeDuration)
		elseif fb.textShake and b and not text.isShaking then
			text.isShaking = HS.ShakeIt(text, fb.shakeDuration)
		end

		text:FontTemplate(fb.font, fb.fontSize + (b and 4 or 0), fb.fontOutline)
		text:SetTextColor(unpack(d or (CT[a] and SC[00]) or GP(c) or SC[01]))
		text:SetText(CT[a] or a)

		if fb.mode == 'Simpy' then
			if not fb.FadeOut then fb.FadeOut = { mode = 'OUT' } else fb.FadeOut.fadeTimer = nil end
			if not fb.FaderIn then fb.FaderIn = { mode = 'IN' } else fb.FaderIn.fadeTimer = nil end
			SI.FadeIn(fb.FaderIn, fb.Frame, 0.2, 0.7 + (b and 0.3 or 0), 0.4, 0.0, 0.8)
		elseif fb.mode == 'LS' then
			tinsert(fb.objs, text)
			text.frame:SetAlpha(1)
			text:Show()
		end
end end

local objects = {}
local function hook(x)
	local fb = x and x.Feedback
	if not (fb and fb.owner) or objects[fb.owner] then return end

	if fb.font			== nil then fb.font			= 'Expressway'	end
	if fb.fontSize		== nil then fb.fontSize		= 14			end
	if fb.fontOutline	== nil then fb.fontOutline	= 'OUTLINE'		end
	if fb.mode			== nil then fb.mode			= 'Simpy'		end
	if fb.font == 'Expressway' then fb.font = E.Libs.LSM:Fetch('font', fb.font) end
	if fb.alternateIcon == nil then fb.alternateIcon = false end
	if fb.shakeDuration == nil then fb.shakeDuration = 0.25 end
	if fb.critShake == nil then fb.critShake = false end
	if fb.textShake == nil then fb.textShake = false end
	if fb.showIcon == nil then fb.showIcon = false end
	if fb.showName == nil then fb.showName = false end
	if fb.showHots == nil then fb.showHots = false end
	if fb.showDots == nil then fb.showDots = false end
	if fb.isTarget == nil then fb.isTarget = false end
	if fb.isPlayer == nil then fb.isPlayer = true  end
	if fb.showPet  == nil then fb.showPet  = true  end

	if fb.exclude == nil then
		exclude[145109] = true -- Ysera's Gift (self healing)
	else
		exclude = fb.exclude
	end

	objects[fb.owner] = fb

	local parent = fb.parent or x
	if fb.mode == 'Simpy' then
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
	elseif fb.mode == 'LS' then
		fb.objs, fb.texts = {}, {}
		if fb.numTexts == nil then fb.numTexts = 25 end
		if fb.anim == nil then fb.anim = 'fountain' end

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

			if fb.radius     ~= nil then text.radius     = fb.radius     else text.radius     = 64                end
			if fb.ScrollTime ~= nil then text.scrollTime = fb.ScrollTime else text.scrollTime = 1.5               end
			if fb.FadeTime   ~= nil then text.fadeTime   = fb.FadeTime   else text.fadeTime = text.scrollTime / 3 end
			if fb.DirectionX ~= nil then text.xDirection = fb.DirectionX else text.xDirection = 1                 end
			if fb.DirectionY ~= nil then text.yDirection = fb.DirectionY else text.yDirection = 1                 end
			if fb.AlternateX ~= nil then text.alternateX = fb.AlternateX else text.alternateX = true              end
			if fb.AlternateY ~= nil then text.alternateY = fb.AlternateY else text.alternateY = false             end

			text.x = text.xDirection * LS.xOffsets[fb.anim]
			text.y = text.yDirection * LS.yOffsets[fb.anim]
			text.GetXY = LS.animations[fb.anim]
			text.elapsed = 0
			text.frame = frame
			fb.texts[i] = text
		end

		fb.owner:HookScript("OnHide", LS.onShowHide)
		fb.owner:HookScript("OnShow", LS.onShowHide)
		fb.owner:HookScript("OnUpdate", LS.onUpdate)
	end
end

local cft = cf('Frame')
cft:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
cft:SetScript('OnEvent', function()
	for object, texts in next, objects do
		Update(object, texts)
	end
end)

for _, x in ipairs(oUF.objects) do
	hook(x)
end

oUF:RegisterInitCallback(hook)
