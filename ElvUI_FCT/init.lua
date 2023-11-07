local E, _, V, P, G = unpack(ElvUI)
local UF = E:GetModule('UnitFrames')
local addon, ns = ...

local FCT = E.Libs.AceAddon:NewAddon(addon, 'AceEvent-3.0')
ns[1], ns[2] = addon, FCT

local _G, select, tostring, strfind = _G, select, tostring, strfind
local type, pairs, format, tonumber = type, pairs, format, tonumber
local next, wipe = next, wipe

local UIParent = UIParent
local CreateFrame = CreateFrame
local GetSpellInfo = GetSpellInfo
local GetSpellSubtext = GetSpellSubtext
local UnitIsEnemy = UnitIsEnemy
local UnitIsPlayer = UnitIsPlayer
local UnitIsPVPSanctuary = UnitIsPVPSanctuary
local UnitIsUnit = UnitIsUnit
local UnitReaction = UnitReaction
local GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit
local GetNamePlates = C_NamePlate.GetNamePlates
local hooksecurefunc = hooksecurefunc

local NPDriver = NamePlateDriverFrame
local Version = GetAddOnMetadata(addon, 'Version')
local version = format('[|cFF508cf7v%s|r]', Version)
local title = '|cFFdd2244Floating Combat Text|r'
local by = 'by |cFF8866ccSimpy|r and |cFF34dd61Lightspark|r (ls-)'

local subsetting = {
	advanced = true
}

FCT.orders = {
	colors = {
		['1'] = 1, -- Damage
		['2'] = 2, -- Holy
		['4'] = 3, -- Fire
		['8'] = 4, -- Nature
		['16'] = 5, -- Frost
		['32'] = 6, -- Shadow
		['64'] = 7, -- Arcane
		Standard = 8,
		Physical = 9,
		Ranged = 10,
		Heal = 11,
		Prefix = 12
	},

	-- Nameplates
	Player = {1, 'Player'},
	FriendlyPlayer = {3, 'FRIENDLY_PLAYER'},
	FriendlyNPC = {4, 'FRIENDLY_NPC'},
	EnemyPlayer = {5, 'ENEMY_PLAYER'},
	EnemyNPC = {6, 'ENEMY_NPC'},

	-- Unitframes
	Target = {2, 'Target'},
	TargetTarget = {3, 'TargetTarget'},
	TargetTargetTarget = {4, 'TargetTargetTarget'},
	Focus = {5, 'Focus'},
	FocusTarget = {6, 'FocusTarget'},
	Pet = {7, 'Pet'},
	PetTarget = {8, 'PetTarget'},
	Arena = {9, 'Arena'},
	Boss = {10, 'Boss'},
	Party = {11, 'Party'},
	Raid1 = {12, 'Raid 1'},
	Raid2 = {13, 'Raid 2'},
	Raid3 = {14, 'Raid 3'},
	RaidPet = {15, 'Raid Pet'},
	Assist = {16, 'Assist'},
	Tank = {17, 'Tank'},
}

FCT.nameplateTypes = {
	PLAYER = 'Player',
	FRIENDLY_PLAYER = 'FriendlyPlayer',
	FRIENDLY_NPC = 'FriendlyNPC',
	ENEMY_PLAYER = 'EnemyPlayer',
	ENEMY_NPC = 'EnemyNPC',
}

FCT.unitframeTypes = {
	arena = 'Arena',
	assist = 'Assist',
	boss = 'Boss',
	party = 'Party',
	raid1 = 'Raid1',
	raid2 = 'Raid2',
	raid3 = 'Raid3',
	tank = 'Tank',
	focus = 'Focus',
	focustarget = 'FocusTarget',
	pet = 'Pet',
	pettarget = 'PetTarget',
	player = 'Player',
	target = 'Target',
	targettarget = 'TargetTarget',
	targettargettarget = 'TargetTargetTarget',
}

function FCT:ColorOption(name, desc)
	if desc then
		return format('|cFF508cf7%s:|r |cFFffffff%s|r', name, desc)
	else
		return format('|cFF508cf7%s|r', name)
	end
end

function FCT:UpdateNamePlates()
	for _, nameplate in pairs(GetNamePlates()) do
		FCT:ToggleFrame(nameplate)
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

	-- assist, tank, party, raid1-3, raidpet
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

function FCT:GetSpellNameRank(id)
	local name = tonumber(id) and GetSpellInfo(id)
	if not name then return tostring(id) end

	local rank = not E.Retail and GetSpellSubtext(id)
	if not rank or not strfind(rank, '%d') then
		return format('%s |cFF888888(%s)|r', name, id)
	end

	return format('%s %s[%s]|r |cFF888888(%s)|r', name, E.media.hexvaluecolor, rank, id)
end

do
	local spellList = {}
	function FCT:ExcludeList(db)
		wipe(spellList)

		for spell in pairs(db) do
			spellList[spell] = FCT:GetSpellNameRank(spell)
		end

		if not next(spellList) then
			spellList[''] = _G.NONE
		end

		return spellList
	end
end

function FCT:AddOptions(arg1, arg2)
	local i = (type(arg2) == 'number' and tostring(arg2)) or arg2
	local path = E.Options.args.ElvFCT.args[arg1]

	local L = FCT.L
	local db = FCT.db[arg1]
	if arg1 == 'stacks' then
		path.args.exclude.args.spells.values[arg2] = FCT:GetSpellNameRank(arg2)
	elseif path.args[i] then
		return
	elseif arg1 == 'colors' then
		path.args[i] = {
			order = FCT.orders.colors[i],
			name = L[ns.colors[arg2].n],
			type = 'color',
		}
	elseif arg1 == 'exclude' then
		local spellName = FCT:GetSpellNameRank(arg2)
		local option = { order = 3, type = 'group', name = spellName, args = {
			name = { order = 1, type = 'header', name = spellName },
			global = { order = 2, type = 'toggle', name = L["Global"] },
			nameplates = { order = 3, type = 'group', name = L["Nameplates"], inline = true, args = {} },
			unitframes = { order = 4, type = 'group', name = L["UnitFrames"], inline = true, args = {} }
		}}

		path.args[i] = option
		option.get = function(info) return db[arg2][ info[#info] ] end
		option.set = function(info, value)
			local which = info[#info]
			if which == 'global' then
				if value then wipe(db[arg2]) end
				db[arg2].global = value or nil
			else
				if value then db[arg2].global = nil end
				db[arg2][which] = value or nil
			end
		end

		for key, name in next, FCT.nameplateTypes do
			option.args.nameplates.args[key] = { order = FCT.orders[name][1], type = 'toggle', name = L[FCT.orders[name][2]] }
		end
		for key, name in next, FCT.unitframeTypes do
			option.args.unitframes.args[key] = { order = FCT.orders[name][1], type = 'toggle', name = L[FCT.orders[name][2]] }
		end
	else
		path.args[arg2] = {
			order = FCT.orders[arg2][1],
			name = L[FCT.orders[arg2][2]],
			args = FCT.options,
			type = 'group',
			get = function(info)
				local sub = info[4]
				if subsetting[sub] then
					return db.frames[arg2][sub][ info[#info] ]
				else
					return db.frames[arg2][ info[#info] ]
				end
			end,
			set = function(info, value)
				local sub = info[4]
				if subsetting[sub] then
					db.frames[arg2][sub][ info[#info] ] = value
				else
					db.frames[arg2][ info[#info] ] = value
				end

				if arg1 == 'unitframes' then
					FCT:UpdateUnitFrames()
				else
					FCT:UpdateNamePlates()
				end
			end
		}
	end
end

function FCT:Options()
	FCT.L = E.Libs.ACL:GetLocale('ElvUI', E.global.general.locale or 'enUS')
	local C = E.Config[1]
	local L = FCT.L

	FCT.options = {
		enable = { order = 1, type = 'toggle', name = L["Enable"] },
		toggles = { order = 2, type = 'group', name = '', guiInline = true, args = {
			header = { order = 0, name = FCT:ColorOption(L["Toggles"]), type = 'header' },
			alternateIcon = { order = 1, type = 'toggle', name = L["Alternate Icon"] },
			showIcon = { order = 2, type = 'toggle', name = L["Show Icon"] },
			showName = { order = 3, type = 'toggle', name = L["Show Name"] },
			showPet = { order = 4, type = 'toggle', name = L["Show Pet"] },
			showHots = { order = 5, type = 'toggle', name = L["Show Hots"] },
			showDots = { order = 6, type = 'toggle', name = L["Show Dots"] },
			isTarget = { order = 7, type = 'toggle', name = L["Is Target"] },
			isPlayer = { order = 8, type = 'toggle', name = L["From Player"] },
			stackingSelf = { order = 9, type = 'toggle', name = E.NewSign..L["Stacking Self"] },
			stackingOthers = { order = 10, type = 'toggle', name = E.NewSign..L["Stacking Others"] },
			critShake = { order = 11, type = 'toggle', name = L["Critical Frame Shake"] },
			textShake = { order = 12, type = 'toggle', name = L["Critical Text Shake"] },
			cycleColors = { order = 13, type = 'toggle', name = L["Cycle Spell Colors"] }
		}},
		fonts = { order = 3, type = 'group', name = '', guiInline = true, args = {
			header = { order = 0, name = FCT:ColorOption(L["Fonts"]), type = 'header' },
			font = { order = 1, type = 'select', dialogControl = 'LSM30_Font', name = L["Font"], values = _G.AceGUIWidgetLSMlists.font },
			fontOutline = { order = 2, name = L["Font Outline"], desc = L["Set the font outline."], type = 'select', sortByValue = true, values = C.Values.FontFlags},
			fontSize = { order = 3, name = _G.FONT_SIZE, type = 'range', min = 4, max = 60, step = 1 },
			spacer1 = { order = 4, type = 'description', name = ' ', width = 'full' },
			critFont = { order = 5, type = 'select', dialogControl = 'LSM30_Font', name = L["Critical Font"], values = _G.AceGUIWidgetLSMlists.font },
			critFontOutline = { order = 6, name = L["Critical Font Outline"], desc = L["Set the font outline."], type = 'select', sortByValue = true, values = C.Values.FontFlags},
			critFontSize = { order = 7, name = L["Critical Font Size"], type = 'range', min = 4, max = 60, step = 1 },
			prefix = { order = 8, type = 'input', name = L["Critical Prefix"] }
		}},
		settings = { order = 4, type = 'group', name = '', guiInline = true, args = {
			header = { order = 0, name =  FCT:ColorOption(L["Settings"]), type = 'header' },
			mode = { order = 1, name = L["Mode"], type = 'select', values = { Simpy = L["Fade"], LS = L["Animation"] } },
			numberStyle = { order = 2, name = L["Number Style"], type = 'select', values = { NONE = _G.NONE, PERCENT = L["Percent"], SHORT = L["Short"], BLIZZARD = L["Blizzard"], BLIZZTEXT = L["Blizzard Text"] }},
			iconSize = { order = 3, name = L["Icon Size"], type = 'range', min = 10, max = 30, step = 1 },
			followSize = { order = 4, name = L["Icon Follow Text Size"], type = 'toggle' },
			shakeDuration = { order = 5, name = L["Shake Duration"], type = 'range', min = 0, max = 1, step = 0.1 }
		}},
		offsets = { order = 6, type = 'group', name = '', guiInline = true, args = {
			header = { order = 0, name =  FCT:ColorOption(L["Offsets"]), type = 'header' },
			textY = { order = 1, name = L["Text Y"], desc = L["Only applies to Fade mode."], type = 'range', min = -100, max = 100, step = 1 },
			textX = { order = 2, name = L["Text X"], desc = L["Only applies to Fade mode."], type = 'range', min = -100, max = 100, step = 1 },
			iconY = { order = 3, name = L["Icon Y"], type = 'range', min = -100, max = 100, step = 1 },
			iconX = { order = 4, name = L["Icon X"], type = 'range', min = -100, max = 100, step = 1 },
			spellY = { order = 5, name = L["Spell Y"], type = 'range', min = -100, max = 100, step = 1 },
			spellX = { order = 6, name = L["Spell X"], type = 'range', min = -100, max = 100, step = 1 },
		}},
		advanced = { order = 7, type = 'group', name = '', guiInline = true, args = {
			header = { order = 0, name =  FCT:ColorOption(L["Animations"], L["Only applies on Animation mode."]), type = 'header' },
			anim = { order = 1, name = L["Animation"], type = 'select', values = {
				fountain = L["Fountain"],
				vertical = L["Vertical"],
				horizontal = L["Horizontal"],
				diagonal = L["Diagonal"],
				static = L["Static"],
				random = L["Random"]
			}},
			AlternateX = { order = 2, type = 'toggle', name = L["Alternate X"] },
			AlternateY = { order = 3, type = 'toggle', name = L["Alternate Y"] },
			spacer1 = { order = 4, type = 'description', name = ' ', width = 'full' },
			numTexts = { order = 5, name = L["Text Amount"], type = 'range', min = 1, max = 30, step = 1 },
			radius = { order = 6, name = L["Radius"], type = 'range', min = 0, max = 256, step = 1 },
			ScrollTime = { order = 7, name = L["Scroll Time"], type = 'range', min = 0, max = 5, step = 0.1 },
			FadeTime = { order = 8, name = L["Fade Time"], type = 'range', min = 0, max = 5, step = 0.1 },
			DirectionX = { order = 9, name = L["Direction X"], type = 'range', min = -100, max = 100, step = 1 },
			DirectionY = { order = 10, name = L["Direction Y"], type = 'range', min = -100, max = 100, step = 1 },
			OffsetX = { order = 11, name = L["Offset X"], type = 'range', min = -100, max = 100, step = 1 },
			OffsetY = { order = 12, name = L["Offset Y"], type = 'range', min = -100, max = 100, step = 1 },
		}}
	}

	E.Options.args.ElvFCT = { order = 6, type = 'group', name = title, childGroups = 'tab', args = {
		name = {
			order = 1,
			type = 'header',
			name = title..' '..version..' '..by,
		},
		nameplates = {
			order = 2,
			type = 'group',
			childGroups = 'tab',
			name = L["Nameplates"],
			get = function(info) return FCT.db.nameplates[ info[#info] ] end,
			set = function(info, value) FCT.db.nameplates[ info[#info] ] = value; FCT:UpdateNamePlates() end,
			args = { enable = { order = 1, type = 'toggle', name = L["Enable"] } }
		},
		unitframes = {
			order = 3,
			type = 'group',
			childGroups = 'tab',
			name = L["UnitFrames"],
			get = function(info) return FCT.db.unitframes[ info[#info] ] end,
			set = function(info, value) FCT.db.unitframes[ info[#info] ] = value; FCT:UpdateUnitFrames() end,
			args = { enable = { order = 1, type = 'toggle', name = L["Enable"] } }
		},
		colors = {
			order = 4,
			type = 'group',
			name = L["Colors"],
			get = function(info)
				local i = tonumber(info[#info]) or info[#info]
				local t, d = FCT.db.colors[i], ns.colors[i]
				return t.r, t.g, t.b, t.a, d.r, d.g, d.b, d.a
			end,
			set = function(info, r, g, b)
				local t = FCT.db.colors[ tonumber(info[#info]) or info[#info] ]
				t.r, t.g, t.b = r, g, b
				FCT:UpdateColors();
			end,
			args = {}
		},
		stacks = { order = 5, type = 'group', name = E.NewSign..L["Stacks"], args = {
			sendDelay = { order = 1, name = L["Send Delay"], desc = L["How far apart each stack will display."], type = 'range', min = 0.01, max = 10, step = 0.01, bigStep = 0.1 },
			tickWait = { order = 2, name = L["Tick Wait"], desc = L["How long to gather stacks."], type = 'range', min = 0.01, max = 30, step = 0.01, bigStep = 0.1 },
			hitsWait = { order = 3, name = L["Hits Wait"], desc = L["How long to gather hits."], type = 'range', min = 0.01, max = 30, step = 0.01, bigStep = 0.1 },
			hitAmount = { order = 4, name = L["Hits Amount"], desc = L["How many hits until it is considered a stacking aura."], type = 'range', min = 2, max = 30, step = 1 },
			prefix = { order = 10, type = 'input', name = L["Stack Prefix"] },
			overtime = { order = 11, type = 'toggle', name = L["Overtime Spells"], desc = L["Heals over time and Damage over time spells to stack."] },
			showCrits = { order = 12, type = 'toggle', name = L["Show Crits"], desc = L["Display criticals beside stack count."]},
			hitsDetect = { order = 13, type = 'toggle', name = L["Detect Hits"], desc = L["Required to gather fast spells to stack."] },
			spacer1 = { order = 14, type = 'description', name = ' ', width = 'full' },
			exclude = { order = -1, type = 'group', name = L["Exclude"], inline = true, args = {
				remove = {
					order = 1,
					name = L["Remove Spell"],
					type = 'select',
					values = function() return FCT:ExcludeList(FCT.db.stacks.exclude) end,
					confirm = function(_, value) return format(L["Remove Spell - %s"], FCT:GetSpellNameRank(value)) end,
					get = function() return '' end,
					set = function(_, value)
						FCT.db.stacks.exclude[value] = nil
						E.Options.args.ElvFCT.args.stacks.args.exclude.args.spells.values[value] = nil
					end
				},
				add = {
					order = 2,
					name = L["Add SpellID"],
					type = 'input',
					get = function(_) return '' end,
					set = function(_, str)
						local value = tonumber(str)
						if not value then return end

						local spellName = GetSpellInfo(value)
						if not spellName then return end

						FCT.db.stacks.exclude[value] = true
						FCT:AddOptions('stacks', value)
					end
				},
				spells = {
					order = 5,
					name = '',
					values = {},
					type = 'multiselect',
					hidden = function() return not next(FCT.db.stacks.exclude) end,
					get = function(_, value) return FCT.db.stacks.exclude[value] end,
					set = function(_, value)
						FCT.db.stacks.exclude[value] = not FCT.db.stacks.exclude[value]
						FCT:AddOptions('stacks', value)
					end
				}}
			}},
			get = function(info) return FCT.db.stacks[ info[#info] ] end,
			set = function(info, value)
				FCT.db.stacks[ info[#info] ] = value

				FCT:UpdateStacks(FCT.db.stacks)
			end},
		exclude = {
			order = 6,
			type = 'group',
			name = L["Exclude"],
			args = {
				remove = {
					order = 1,
					name = L["Remove Spell"],
					type = 'select',
					values = function() return FCT:ExcludeList(FCT.db.exclude) end,
					confirm = function(_, value) return format(L["Remove Spell - %s"], FCT:GetSpellNameRank(value)) end,
					get = function() return '' end,
					set = function(_, value)
						FCT.db.exclude[value] = nil

						local id = tostring(value)
						if id then E.Options.args.ElvFCT.args.exclude.args[id] = nil end
					end
				},
				add = {
					order = 2,
					name = L["Add SpellID"],
					type = 'input',
					get = function(_) return '' end,
					set = function(_, str)
						local value = tonumber(str)
						if not value then return end

						local spellName = GetSpellInfo(value)
						if not spellName then return end

						local exists = FCT.db.exclude[value]
						if exists then
							wipe(exists)
							exists.global = true
						else
							FCT.db.exclude[value] = { global = true }
							FCT:AddOptions('exclude', value)
							E.Libs.AceConfigDialog:SelectGroup('ElvUI', 'ElvFCT', 'exclude', str)
						end
					end
				}
			}
		}
	}}

	for name in pairs(ns.defaults.nameplates.frames) do
		FCT:AddOptions('nameplates', name)
	end
	for name in pairs(ns.defaults.unitframes.frames) do
		FCT:AddOptions('unitframes', name)
	end
	for index in pairs(ns.colors) do
		FCT:AddOptions('colors', index)
	end
	for spell in pairs(FCT.db.exclude) do
		FCT:AddOptions('exclude', spell)
	end
	for spell in pairs(FCT.db.stacks.exclude) do
		FCT:AddOptions('stacks', spell)
	end
end

function FCT:PLAYER_LOGOUT()
	E:RemoveDefaults(_G.ElvFCT, FCT.data)
end

function FCT:FetchDB(Module, Type)
	local db = FCT.db[Module]
	if db then
		return db.frames[FCT.nameplateTypes[Type] or FCT.unitframeTypes[Type]]
	end
end

function FCT:GetFrameType(unit) -- logic should match ElvUI NP:UpdatePlateType
	if not unit then return end

	local isMe = UnitIsUnit(unit, 'player')
	local isPVPSanctuary = UnitIsPVPSanctuary(unit)
	local isEnemy = UnitIsEnemy('player', unit)
	local reaction = UnitReaction('player', unit)
	local isPlayer = UnitIsPlayer(unit)

	if isMe then
		return 'PLAYER'
	elseif isPVPSanctuary then
		return 'FRIENDLY_PLAYER'
	elseif not isEnemy and (not reaction or reaction > 4) then
		return (isPlayer and 'FRIENDLY_PLAYER') or 'FRIENDLY_NPC'
	else
		return (isPlayer and 'ENEMY_PLAYER') or 'ENEMY_NPC'
	end
end

function FCT:ToggleFrame(frame)
	if not FCT.db then return end

	local unit
	if self == NPDriver then
		unit = frame
		frame = GetNamePlateForUnit(unit)

		if not frame then
			return -- forbidden
		end
	else
		unit = frame.namePlateUnitToken
	end

	local info = frame.ElvFCT
	if not info then
		frame.ElvFCT = FCT:Build(frame, unit)
		info = frame.ElvFCT
	end

	info.unit = unit or frame.unit
	info.isNameplate = not not unit
	info.frametype = (unit and FCT:GetFrameType(unit)) or frame.unitframeType

	local db = FCT:FetchDB(info.isNameplate and 'nameplates' or 'unitframes', info.frametype)
	if db then FCT:Toggle(frame, info.isNameplate and FCT.db.nameplates or FCT.db.unitframes, db) end
end

function FCT:Build(frame, unit)
	local raised = CreateFrame('Frame', frame:GetDebugName()..'RaisedElvFCT', (unit and UIParent) or frame)
	raised:SetIgnoreParentScale(true)
	raised:SetFrameStrata('MEDIUM')
	raised:SetScale(E.uiscale)
	raised:SetAllPoints(frame)
	raised:SetFrameLevel(200)

	return { owner = frame, raised = raised }
end

function FCT:UpdateColors()
	for k, v in pairs(FCT.db.colors) do
		if not ns.color[k] then
			ns.color[k] = {}
		end

		ns.color[k][1] = v.r
		ns.color[k][2] = v.g
		ns.color[k][3] = v.b
	end
end

function FCT:Initialize()
	-- Database
	FCT.data = {}; E:CopyDefaults(FCT.data, ns.defaults)
	FCT.data.colors = {}; E:CopyDefaults(FCT.data.colors, ns.colors)
	for name in pairs(ns.defaults.nameplates.frames) do E:CopyDefaults(FCT.data.nameplates.frames[name], ns.frames) end
	for name in pairs(ns.defaults.unitframes.frames) do E:CopyDefaults(FCT.data.unitframes.frames[name], ns.frames) end
	FCT.db = {}; E:CopyDefaults(FCT.db, FCT.data)

	-- Globals
	_G.ElvUI_FCT = FCT
	_G.ElvFCT = E:CopyTable(FCT.db, _G.ElvFCT)

	-- Settings
	FCT:UpdateColors()
	FCT:UpdateStacks(FCT.db.stacks)

	-- Events
	FCT:RegisterEvent('PLAYER_LOGOUT')
	FCT:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')

	-- Register
	E.Libs.EP:RegisterPlugin(addon, FCT.Options)
end

hooksecurefunc(E, 'Initialize', FCT.Initialize)
hooksecurefunc(UF, 'Configure_HealthBar', FCT.ToggleFrame)
hooksecurefunc(NPDriver, 'OnNamePlateAdded', FCT.ToggleFrame)
hooksecurefunc(NPDriver, 'OnUnitFactionChanged', FCT.ToggleFrame)
