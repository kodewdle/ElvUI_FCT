local E = unpack(ElvUI)
local UF = E:GetModule('UnitFrames')
local _, ns = ...
local FCT = ns[2]
local GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit
local GetNamePlates = C_NamePlate.GetNamePlates

ns.frameInfo = {}
ns.defaults.nameplates.hideBlizzardDamage = true

local platesByUnit = {}
local damageCVar = 'floatingCombatTextCombatDamage_v2'
local savedBlizzardDamage

local function restoreBlizzardDamage()
	if savedBlizzardDamage ~= nil and C_CVar.GetCVar(damageCVar) == '0' then
		C_CVar.SetCVar(damageCVar, savedBlizzardDamage)
	end
	savedBlizzardDamage = nil
end

local function updateBlizzardDamage()
	if not FCT.db then return end
	if not (FCT.db.nameplates.enable and FCT.db.nameplates.hideBlizzardDamage) then
		restoreBlizzardDamage()
		return
	end
	local current = C_CVar.GetCVar(damageCVar)
	if current and current ~= '0' then
		savedBlizzardDamage = savedBlizzardDamage or current
		C_CVar.SetCVar(damageCVar, 0)
	end
end

FCT.OnEnable = updateBlizzardDamage
FCT.OnDisable = restoreBlizzardDamage

function FCT:ConfigureForeverOptions()
	FCT.options.advanced.args.OffsetY.max = 200
	local nameplates = E.Options.args.ElvFCT.args.nameplates
	nameplates.args.hideBlizzardDamage = { order = 1.1, type = 'toggle', name = FCT.L["Hide Blizzard damage numbers"] }
	nameplates.set = function(info, value)
		FCT.db.nameplates[info[#info]] = value
		updateBlizzardDamage()
		if info[#info] == 'enable' then FCT:UpdateNamePlates() end
	end
	ns.AddLogFilterOptions(nameplates.args)
end

function FCT:UpdateNamePlates()
	for _, nameplate in pairs(GetNamePlates()) do
		if not nameplate:IsForbidden() then
			local unit = nameplate.namePlateUnitToken
			if not issecretvalue(unit) and unit then FCT:AttachPlate(unit) end
		end
	end
end

local function public(value)
	if not issecretvalue(value) then return value end
end

function FCT:GetFrameType(unit)
	if not unit then return end

	local isMe = public(UnitIsUnit(unit, 'player'))
	local isPVPSanctuary = public(UnitIsPVPSanctuary(unit))
	local isEnemy = public(UnitIsEnemy('player', unit))
	local reaction = public(UnitReaction('player', unit))
	local isPlayer = public(UnitIsPlayer(unit))

	if isMe then
		return 'PLAYER'
	elseif isPVPSanctuary then
		return 'FRIENDLY_PLAYER'
	elseif isEnemy == nil and reaction == nil then
		return
	elseif not isEnemy and (not reaction or reaction > 4) then
		return (isPlayer and 'FRIENDLY_PLAYER') or 'FRIENDLY_NPC'
	else
		return (isPlayer and 'ENEMY_PLAYER') or 'ENEMY_NPC'
	end
end

function FCT:ToggleFrame(frame, unit)
	if not FCT.db or not frame or frame:IsForbidden() then return end

	local module = unit and FCT.db.nameplates or FCT.db.unitframes
	local frameType = unit and FCT:GetFrameType(unit) or frame.unitframeType
	local db = FCT:FetchDB(unit and 'nameplates' or 'unitframes', frameType)
	if not (db and module.enable and db.enable) then
		FCT:Disable(frame)
		return
	end

	local info = ns.frameInfo[frame]
	if not info then
		info = FCT:Build(frame, unit)
		ns.frameInfo[frame] = info
	end

	info.unit = unit or frame.unit
	info.isNameplate = not not unit
	info.frametype = frameType
	FCT:Enable(frame, db)
end

function ns.GetForeverPlate(unit)
	if issecretvalue(unit) or not unit then return end
	local ok, plate = pcall(GetNamePlateForUnit, unit)
	if ok and not issecretvalue(plate) and plate and not plate:IsForbidden() then return plate end
end

function FCT:AttachPlate(unit)
	local plate = ns.GetForeverPlate(unit)
	if not plate then return end
	platesByUnit[unit] = plate
	FCT:ToggleFrame(plate, unit)
end

function FCT:NAME_PLATE_UNIT_ADDED(_, unit)
	FCT:AttachPlate(unit)
end

function FCT:NAME_PLATE_UNIT_REMOVED(_, unit)
	local plate = platesByUnit[unit]
	platesByUnit[unit] = nil
	if plate then FCT:Disable(plate) end
end

function FCT:UNIT_FACTION(_, unit)
	if not issecretvalue(unit) and unit and platesByUnit[unit] then FCT:AttachPlate(unit) end
end

function FCT:Build(frame, unit)
	local raised = CreateFrame('Frame', nil, (unit and UIParent) or frame)
	raised:SetIgnoreParentScale(true)
	raised:SetScale(E.uiscale)
	raised:SetSize(1, 1)
	raised:SetPoint('CENTER', frame, 'CENTER')

	local info = { owner = frame, raised = raised }
	raised.ElvFCT = info
	return info
end

local sharedLogout = FCT.PLAYER_LOGOUT
function FCT:PLAYER_LOGOUT(...)
	ns.ApplyQueuedLogFilter()
	restoreBlizzardDamage()
	sharedLogout(self, ...)
end

function FCT:InitializeForever()
	FCT:RegisterEvent('NAME_PLATE_UNIT_ADDED')
	FCT:RegisterEvent('NAME_PLATE_UNIT_REMOVED')
	FCT:RegisterEvent('UNIT_FACTION')
	FCT:UpdateUnitFrames()
	FCT:UpdateNamePlates()
	FCT:StartForeverEvents()
	updateBlizzardDamage()
end

hooksecurefunc(UF, 'Configure_HealthBar', function(_, frame) FCT:ToggleFrame(frame) end)
