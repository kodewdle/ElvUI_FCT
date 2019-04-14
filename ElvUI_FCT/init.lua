local addon, ns = ...

local E, L, V, P, G = unpack(ElvUI)
local FCT = E.Libs.AceAddon:NewAddon(addon, 'AceEvent-3.0')
ns[1] = addon
ns[2] = FCT

local _G = _G
local next = next
local type = type
local pairs = pairs
local format = format
local setmetatable = setmetatable
local hooksecurefunc = hooksecurefunc

local Version = GetAddOnMetadata(addon, "Version")
local version = format("[v|cFF508cf7%s|r]", Version)
local title = '|cfffe7b2cElvUI|r: |cFFF76ADBFCT|r'
local by = 'by |cFF8866ccSimpy|r and |cFF34dd61Lightspark|r (ls-)'

FCT.options = {
	enable = {
		order = 1,
		type = "toggle",
		name = L["Enable"],
	},
	showIcon = {
		order = 2,
		type = "toggle",
		name = L["Show Icon"],
	},
	alternateIcon = {
		order = 3,
		type = "toggle",
		name = L["Alternate Icon"],
	},
	showName = {
		order = 4,
		type = "toggle",
		name = L["Show Name"],
	},
	showHots = {
		order = 5,
		type = "toggle",
		name = L["Show Hots"],
	},
	showDots = {
		order = 6,
		type = "toggle",
		name = L["Show Dots"],
	},
	isTarget = {
		order = 7,
		type = "toggle",
		name = L["Is Target"],
	},
	isPlayer = {
		order = 8,
		type = "toggle",
		name = L["From Player"],
	},
	showPet = {
		order = 9,
		type = "toggle",
		name = L["Show Pet"],
	},
	critShake = {
		order = 10,
		type = "toggle",
		name = L["Crit Shake"],
	},
	textShake = {
		order = 11,
		type = "toggle",
		name = L["Text Shake"],
	},
	shakeDuration = {
		order = 12,
		name = L["Shake Duration"],
		type = "range",
		min = 0, max = 1, step = 0.1,
	},
	spacer1 = {
		order = 13,
		type = "description",
		name = " ",
		width = "full"
	},
	font = {
		type = "select", dialogControl = 'LSM30_Font',
		order = 14,
		name = L["Font"],
	},
	fontOutline = {
		order = 15,
		name = L["Font Outline"],
		desc = L["Set the font outline."],
		type = "select",
		values = {
			['NONE'] = _G.NONE,
			['OUTLINE'] = 'OUTLINE',
			['MONOCHROMEOUTLINE'] = 'MONOCROMEOUTLINE',
			['THICKOUTLINE'] = 'THICKOUTLINE',
		},
	},
	fontSize = {
		order = 16,
		name = _G.FONT_SIZE,
		type = "range",
		min = 4, max = 60, step = 1,
	},
	spacer2 = {
		order = 17,
		type = "description",
		name = " ",
		width = "full"
	},
	numTexts = {
		order = 18,
		name = L["Text Amount"],
		type = "range",
		min = 1, max = 30, step = 1,
	},
	mode = {
		order = 19,
		name = L["Mode"],
		type = "select",
		values = {
			['Simpy'] = 'Static',
			['LS'] = 'Animation'
		},
	},
	anim = {
		order = 20,
		name = L["Animation"],
		type = "select",
		values = {
			["fountain"] = L["Fountain"],
			["vertical"] = L["Vertical"],
			["horizontal"] = L["Horizontal"],
			["diagonal"] = L["Diagonal"],
			["static"] = L["Static"],
			["random"] = L["Random"]
		},
	},
}

function FCT:AddOptions(arg1, arg2)
	if E.Options.args.ElvFCT.args[arg1].args[arg2] then return end

	if arg1 == 'colors' then
		E.Options.args.ElvFCT.args[arg1].args[arg2] = {
			order = FCT.orders[arg2],
			name = L[ns.colors[arg2].n],
			type = 'color',
		}
	else
		E.Options.args.ElvFCT.args[arg1].args[arg2] = {
			order = FCT.orders[arg2][1],
			name = L[FCT.orders[arg2][2]],
			type = "group",
			get = function(info) return FCT.db[arg1].frames[arg2][ info[#info] ] end,
			set = function(info, value) FCT.db[arg1].frames[arg2][ info[#info] ] = value end,
			args = FCT.options
		}
	end
end

function FCT:Options()
	FCT.options.font.values = _G.AceGUIWidgetLSMlists.font

	E.Options.args.ElvFCT = {
		order = 1337,
		type = 'group',
		name = title,
		childGroups = "tab",
		args = {
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
				set = function(info, value) FCT.db.nameplates[ info[#info] ] = value end,
				args = {
					enable = {
						order = 1,
						type = "toggle",
						name = L["Enable"],
					}
				}
			},
			unitframes = {
				order = 3,
				type = "group",
				name = L["UnitFrames"],
				get = function(info) return FCT.db.unitframes[ info[#info] ] end,
				set = function(info, value) FCT.db.unitframes[ info[#info] ] = value end,
				args = {
					enable = {
						order = 1,
						type = "toggle",
						name = L["Enable"],
					}
				}
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
				end,
				args = {}
			}
		},
	}

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

-- Shamelessy taken from AceDB-3.0
local function removeDefaults(db, defaults, blocker)
	-- remove all metatables from the db, so we don't accidentally create new sub-tables through them
	setmetatable(db, nil)
	-- loop through the defaults and remove their content
	for k,v in pairs(defaults) do
		if k == "*" or k == "**" then
			if type(v) == "table" then
				-- Loop through all the actual k,v pairs and remove
				for key, value in pairs(db) do
					if type(value) == "table" then
						-- if the key was not explicitly specified in the defaults table, just strip everything from * and ** tables
						if defaults[key] == nil and (not blocker or blocker[key] == nil) then
							removeDefaults(value, v)
							-- if the table is empty afterwards, remove it
							if next(value) == nil then
								db[key] = nil
							end
						-- if it was specified, only strip ** content, but block values which were set in the key table
						elseif k == "**" then
							removeDefaults(value, v, defaults[key])
						end
					end
				end
			elseif k == "*" then
				-- check for non-table default
				for key, value in pairs(db) do
					if defaults[key] == nil and v == value then
						db[key] = nil
					end
				end
			end
		elseif type(v) == "table" and type(db[k]) == "table" then
			-- if a blocker was set, dive into it, to allow multi-level defaults
			removeDefaults(db[k], v, blocker and blocker[k])
			if next(db[k]) == nil then
				db[k] = nil
			end
		else
			-- check if the current value matches the default, and that its not blocked by another defaults table
			if db[k] == defaults[k] and (not blocker or blocker[k] == nil) then
				db[k] = nil
			end
		end
	end
end

function FCT:PLAYER_LOGOUT()
	removeDefaults(_G.ElvFCT, ns.defaults)
end

function FCT:Initialize()
	_G.ElvUI_FCT = FCT

	FCT.orders = {
		-- Nameplates
		Player = {1, "Player"},
		Target = {2, "Target"},
		FriendlyPlayer = {3, "FRIENDLY_PLAYER"},
		FriendlyNPC = {4, "FRIENDLY_NPC"},
		EnemyPlayer = {5, "ENEMY_PLAYER"},
		EnemyNPC = {6, "ENEMY_NPC"},
		-- Unitframes
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

	-- Database
	FCT.db = E:CopyTable({}, ns.defaults)
	FCT.db.colors = E:CopyTable({}, ns.colors)

	for name in pairs(ns.defaults.nameplates.frames) do
		E:CopyTable(FCT.db.nameplates.frames[name], ns.frames)
	end
	for name in pairs(ns.defaults.unitframes.frames) do
		E:CopyTable(FCT.db.unitframes.frames[name], ns.frames)
	end

	_G.ElvFCT = E:CopyTable(FCT.db, _G.ElvFCT)

	-- Events
	FCT:RegisterEvent("PLAYER_LOGOUT")
	FCT:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

	E.Libs.EP:RegisterPlugin(addon, FCT.Options)
end

hooksecurefunc(E, 'Initialize', FCT.Initialize)
