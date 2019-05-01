local E, _, V, P, G = unpack(ElvUI)
local NP = E:GetModule('NamePlates')
local UF = E:GetModule('UnitFrames')
local addon, ns = ...

local FCT = E.Libs.AceAddon:NewAddon(addon, 'AceEvent-3.0')
ns[1] = addon
ns[2] = FCT

local _G = _G
local select = select
local next, type, pairs, format, tonumber = next, type, pairs, format, tonumber
local rawget, rawset, setmetatable = rawget, rawset, setmetatable
local hooksecurefunc = hooksecurefunc
local CreateFrame = CreateFrame

local Version = GetAddOnMetadata(addon, "Version")
local version = format("[|cFF508cf7v%s|r]", Version)
local title = '|cFFdd2244Floating Combat Text|r'
local by = 'by |cFF8866ccSimpy|r and |cFF34dd61Lightspark|r (ls-)'

function FCT:ColorOption(name, desc)
	if desc then
		return format("|cFF508cf7%s:|r |cFFffffff%s|r", name, desc)
	else
		return format("|cFF508cf7%s|r", name)
	end
end

function FCT:UpdateNamePlates()
	if NP.Plates then
		for nameplate in pairs(NP.Plates) do
			FCT:ToggleFrame(nameplate)
		end
	end
end

function FCT:UpdateUnitFrames()
	-- focus, focustarget, pet, pettarget, player, target, targettarget, targettargettarget
	if UF.units then
		for unit in pairs(UF.units) do
			FCT:ToggleFrame(UF[unit])
		end
	end

	-- arena{1-5}, boss{1-5}
	if UF.groupunits then
		for unit in pairs(UF.groupunits) do
			FCT:ToggleFrame(UF[unit])
		end
	end

	-- assist, tank, party, raid, raid40, raidpet
	if UF.headers then
		for groupName in pairs(UF.headers) do
			local group = UF[groupName]
			if group and group.GetNumChildren then
				for i=1, group:GetNumChildren() do
					local frame = select(i, group:GetChildren())
					if frame and frame.Health then
						FCT:ToggleFrame(frame)
					elseif frame then
						for n = 1, frame:GetNumChildren() do
							local child = select(n, frame:GetChildren())
							if child and child.Health then
								FCT:ToggleFrame(child)
							end
						end
					end
				end
			end
		end
	end
end

function FCT:AddOptions(arg1, arg2)
	if E.Options.args.ElvFCT.args[arg1].args[arg2] then return end

	if arg1 == 'colors' then
		E.Options.args.ElvFCT.args[arg1].args[arg2] = {
			order = FCT.orders[arg2],
			name = FCT.L[ns.colors[arg2].n],
			type = 'color',
		}
	else
		E.Options.args.ElvFCT.args[arg1].args[arg2] = {
			order = FCT.orders[arg2][1],
			name = FCT.L[FCT.orders[arg2][2]],
			type = "group",
			get = function(info)
				if info[4] == 'advanced' or info[4] == 'exclude' then
					return FCT.db[arg1].frames[arg2][info[4]][ info[#info] ]
				else
					return FCT.db[arg1].frames[arg2][ info[#info] ]
				end
			end,
			set = function(info, value)
				if info[4] == 'advanced' or info[4] == 'exclude' then
					FCT.db[arg1].frames[arg2][info[4]][ info[#info] ] = value
				else
					FCT.db[arg1].frames[arg2][ info[#info] ] = value
				end

				if arg1 == 'unitframes' then
					FCT:UpdateUnitFrames()
				else
					FCT:UpdateNamePlates()
				end
			end,
			args = FCT.options
		}
	end
end

function FCT:Options()
	FCT.L = E.Libs.ACL:GetLocale('ElvUI', E.global.general.locale or 'enUS')
	local L = FCT.L

	FCT.options = {
		enable = { order = 1, type = "toggle", name = L["Enable"] },
		toggles = { order = 2, type = "group", name = "", guiInline = true, args = {
			header = { order = 0, name = FCT:ColorOption(L["Toggles"]), type = "header" },
			alternateIcon = { order = 1, type = "toggle", name = L["Alternate Icon"] },
			showIcon = { order = 2, type = "toggle", name = L["Show Icon"] },
			showName = { order = 3, type = "toggle", name = L["Show Name"] },
			showPet = { order = 4, type = "toggle", name = L["Show Pet"] },
			showHots = { order = 5, type = "toggle", name = L["Show Hots"] },
			showDots = { order = 6, type = "toggle", name = L["Show Dots"] },
			isTarget = { order = 7, type = "toggle", name = L["Is Target"] },
			isPlayer = { order = 8, type = "toggle", name = L["From Player"] },
			critShake = { order = 9, type = "toggle", name = L["Critical Frame Shake"] },
			textShake = { order = 10, type = "toggle", name = L["Critical Text Shake"] },
			cycleColors = { order = 11, type = "toggle", name = L["Cycle Spell Colors"] }
		}},
		fonts = { order = 3, type = "group", name = "", guiInline = true, args = {
			header = { order = 0, name = FCT:ColorOption(L["Fonts"]), type = "header" },
			fontSize = { order = 3, name = _G.FONT_SIZE, type = "range", min = 4, max = 60, step = 1 },
			font = { type = "select", dialogControl = 'LSM30_Font', order = 1, name = L["Font"], values = _G.AceGUIWidgetLSMlists.font },
			fontOutline = { order = 2, name = L["Font Outline"], desc = L["Set the font outline."], type = "select", values = {
				['NONE'] = _G.NONE,
				['OUTLINE'] = 'OUTLINE',
				['MONOCHROMEOUTLINE'] = 'MONOCROMEOUTLINE',
				['THICKOUTLINE'] = 'THICKOUTLINE'
		}}	}},
		settings = { order = 4, type = "group", name = "", guiInline = true, args = {
			header = { order = 0, name =  FCT:ColorOption(L["Settings"]), type = "header" },
			mode = { order = 1, name = L["Mode"], type = "select", values = { ['Simpy'] = L["Fade"], ['LS'] = L["Animation"] } },
			numberStyle = { order = 2, name = L["Number Style"], type = "select", values = { ['NONE'] = _G.NONE, ['SHORT'] = L["Short"], ['BLIZZARD'] = L["Blizzard"] }},
			iconSize = { order = 3, name = L["Icon Size"], type = "range", min = 10, max = 30, step = 1 },
			shakeDuration = { order = 4, name = L["Shake Duration"], type = "range", min = 0, max = 1, step = 0.1 }
		}},
		offsets = { order = 5, type = "group", name = "", guiInline = true, args = {
			header = { order = 0, name =  FCT:ColorOption(L["Offsets"]), type = "header" },
			textY = { order = 1, name = L["Text Y"], desc = L["Only applies to Fade mode."], type = "range", min = -100, max = 100, step = 1 },
			textX = { order = 2, name = L["Text X"], desc = L["Only applies to Fade mode."], type = "range", min = -100, max = 100, step = 1 },
			iconY = { order = 3, name = L["Icon Y"], type = "range", min = -100, max = 100, step = 1 },
			iconX = { order = 4, name = L["Icon X"], type = "range", min = -100, max = 100, step = 1 },
			spellY = { order = 5, name = L["Spell Y"], type = "range", min = -100, max = 100, step = 1 },
			spellX = { order = 6, name = L["Spell X"], type = "range", min = -100, max = 100, step = 1 },
		}},
		advanced = { order = 6, type = "group", name = "", guiInline = true, args = {
			header = { order = 0, name =  FCT:ColorOption(L["Animations"], L["Only applies on Animation mode."]), type = "header" },
			anim = { order = 1, name = L["Animation"], type = "select", values = {
				["fountain"] = L["Fountain"],
				["vertical"] = L["Vertical"],
				["horizontal"] = L["Horizontal"],
				["diagonal"] = L["Diagonal"],
				["static"] = L["Static"],
				["random"] = L["Random"]
			}},
			AlternateX = { order = 2, type = "toggle", name = L["Alternate X"] },
			AlternateY = { order = 3, type = "toggle", name = L["Alternate Y"] },
			spacer1 = { order = 4, type = "description", name = " ", width = "full" },
			numTexts = { order = 5, name = L["Text Amount"], type = "range", min = 1, max = 30, step = 1 },
			radius = { order = 6, name = L["Radius"], type = "range", min = 0, max = 256, step = 1 },
			ScrollTime = { order = 7, name = L["Scroll Time"], type = "range", min = 0, max = 5, step = 0.1 },
			FadeTime = { order = 8, name = L["Fade Time"], type = "range", min = 0, max = 5, step = 0.1 },
			DirectionX = { order = 9, name = L["Direction X"], type = "range", min = -100, max = 100, step = 1 },
			DirectionY = { order = 10, name = L["Direction Y"], type = "range", min = -100, max = 100, step = 1 },
			OffsetX = { order = 11, name = L["Offset X"], type = "range", min = -100, max = 100, step = 1 },
			OffsetY = { order = 12, name = L["Offset Y"], type = "range", min = -100, max = 100, step = 1 },
		}}
	}

	E.Options.args.ElvFCT = { order = 1337, type = 'group', name = title, childGroups = "tab", args = {
		name = {
			order = 1,
			type = "header",
			name = title.." "..version.." "..by,
		},
		nameplates = {
			order = 2,
			type = "group",
			name = L["NamePlates"],
			get = function(info) return FCT.db.nameplates[ info[#info] ] end,
			set = function(info, value) FCT.db.nameplates[ info[#info] ] = value; FCT:UpdateNamePlates() end,
			args = { enable = { order = 1, type = "toggle", name = L["Enable"] } }
		},
		unitframes = {
			order = 3,
			type = "group",
			name = L["UnitFrames"],
			get = function(info) return FCT.db.unitframes[ info[#info] ] end,
			set = function(info, value) FCT.db.unitframes[ info[#info] ] = value; FCT:UpdateUnitFrames() end,
			args = { enable = { order = 1, type = "toggle", name = L["Enable"] } }
		},
		colors = {
			order = 4,
			type = "group",
			name = L["Colors"],
			get = function(info)
				local t = FCT.db.colors[ info[#info] ]
				local d = ns.colors[ info[#info] ]
				return t.r, t.g, t.b, t.a, d.r, d.g, d.b, d.a
			end,
			set = function(info, r, g, b)
				local t = FCT.db.colors[ info[#info] ]
				t.r, t.g, t.b = r, g, b
				FCT:UpdateColors();
			end,
			args = {}
	}	}}

	for name in pairs(ns.defaults.nameplates.frames) do
		FCT:AddOptions('nameplates', name)
	end
	for name in pairs(ns.defaults.unitframes.frames) do
		FCT:AddOptions('unitframes', name)
	end
	for index in pairs(ns.colors) do
		FCT:AddOptions('colors', index)
	end
end

-- Shamelessy taken from AceDB-3.0 and stripped down by Simpy
local function copyDefaults(dest, src)
	for k, v in pairs(src) do
		if type(v) == "table" then
			if not rawget(dest, k) then rawset(dest, k, {}) end
			if type(dest[k]) == "table" then copyDefaults(dest[k], v) end
		elseif rawget(dest, k) == nil then
			rawset(dest, k, v)
		end
	end
end

local function removeDefaults(db, defaults)
	setmetatable(db, nil)

	for k,v in pairs(defaults) do
		if type(v) == "table" and type(db[k]) == "table" then
			removeDefaults(db[k], v)
			if next(db[k]) == nil then db[k] = nil end
		elseif db[k] == defaults[k] then
			db[k] = nil
		end
	end
end

function FCT:PLAYER_LOGOUT()
	removeDefaults(_G.ElvFCT, FCT.data)
end

function FCT:FetchDB(Module, Type)
	return FCT.db[Module].frames[FCT.frameTypes[Type]]
end

function FCT:ToggleFrame(frame)
	if not FCT.db then return end

	if (self ~= FCT) and not frame.ElvFCT then
		frame.ElvFCT = FCT:Build(frame, (self == NP and frame.RaisedElement) or frame.RaisedElementParent)
	end

	if frame.unitframeType then
		FCT:Toggle(frame, 'unitframes', FCT:FetchDB('unitframes', frame.unitframeType))
	elseif frame.frameType then
		FCT:Toggle(frame, 'nameplates', FCT:FetchDB('nameplates', frame.frameType))
	end
end

function FCT:Build(frame, RaisedElement)
	local raised = CreateFrame('Frame', frame:GetDebugName()..'RaisedElvFCT', frame)
	raised:SetFrameLevel(RaisedElement:GetFrameLevel() + 50)
	raised:SetAllPoints()

	return { owner = frame, parent = raised }
end

function FCT:UpdateColors()
	for k, v in pairs(FCT.db.colors) do
		k = tonumber(k)
		if not ns.color[k] then
			ns.color[k] = {}
		end

		ns.color[k][1] = v.r
		ns.color[k][2] = v.g
		ns.color[k][3] = v.b
	end
end

function FCT:Initialize()
	_G.ElvUI_FCT = FCT

	FCT.orders = {
		-- Nameplates
		Player = {1, "Player"},
		FriendlyPlayer = {3, "FRIENDLY_PLAYER"},
		FriendlyNPC = {4, "FRIENDLY_NPC"},
		EnemyPlayer = {5, "ENEMY_PLAYER"},
		EnemyNPC = {6, "ENEMY_NPC"},

		-- Unitframes
		Target = {2, "Target"},
		TargetTarget = {3, "TargetTarget"},
		TargetTargetTarget = {4, "TargetTargetTarget"},
		Focus = {5, "Focus"},
		FocusTarget = {6, "FocusTarget"},
		Pet = {7, "Pet"},
		PetTarget = {8, "PetTarget"},
		Arena = {9, "Arena"},
		Boss = {10, "Boss"},
		Party = {11, "Party"},
		Raid = {12, "Raid"},
		Raid40 = {13, "Raid-40"},
		RaidPet = {14, "Raid Pet"},
		Assist = {15, "Assist"},
		Tank = {16, "Tank"},
	}

	FCT.frameTypes = {
		-- NamePlates
		["PLAYER"] = "Player",
		["FRIENDLY_PLAYER"] = "FriendlyPlayer",
		["FRIENDLY_NPC"] = "FriendlyNPC",
		["ENEMY_PLAYER"] = "EnemyPlayer",
		["ENEMY_NPC"] = "EnemyNPC",

		-- Unitframes
		["arena"] = "Arena",
		["assist"] = "Assist",
		["party"] = "Party",
		["raid"] = "Raid",
		["raid40"] = "Raid40",
		["tank"] = "Tank",
		["focus"] = "Focus",
		["focustarget"] = "FocusTarget",
		["pet"] = "Pet",
		["pettarget"] = "PetTarget",
		["player"] = "Player",
		["target"] = "Target",
		["targettarget"] = "TargetTarget",
		["targettargettarget"] = "TargetTargetTarget",
	}

	-- Database
	FCT.data = {}; copyDefaults(FCT.data, ns.defaults)
	FCT.data.colors = {}; copyDefaults(FCT.data.colors, ns.colors)
	for name in pairs(ns.defaults.nameplates.frames) do copyDefaults(FCT.data.nameplates.frames[name], ns.frames) end
	for name in pairs(ns.defaults.unitframes.frames) do copyDefaults(FCT.data.unitframes.frames[name], ns.frames) end
	FCT.db = {}; copyDefaults(FCT.db, FCT.data)

	_G.ElvFCT = E:CopyTable(FCT.db, _G.ElvFCT)

	FCT:UpdateColors()

	-- Events
	FCT:RegisterEvent("PLAYER_LOGOUT")
	FCT:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

	E.Libs.EP:RegisterPlugin(addon, FCT.Options)
end

hooksecurefunc(E, 'Initialize', FCT.Initialize)
hooksecurefunc(NP, 'UpdatePlate', FCT.ToggleFrame)
hooksecurefunc(UF, 'Configure_HealthBar', FCT.ToggleFrame)
