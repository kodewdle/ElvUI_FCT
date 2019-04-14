local addon = ...

local E, L, V, P, G = unpack(ElvUI)
local FCT = E.Libs.AceAddon:NewAddon(addon)

local format = format
local version = GetAddOnMetadata(addon, "Version")
local title = '|cfffe7b2cElvUI|r: |cFFF76ADBFCT|r'
local by = 'by |cFF8866ccSimpy|r and |cFF34dd61Lightspark|r (ls-)'
local ver = format("[v|cFF508cf7%s|r]", version)

function FCT.AddOptions(arg1, arg2)
	if E.Options.args.ElvFCT.args[arg1].args[arg2] then return end
	E.Options.args.ElvFCT.args[arg1].args[arg2] = {
		order = FCT.OptionsTable[arg2][1],
		type = "group",
		name = L[FCT.OptionsTable[arg2][2]],
		args = {}
	}
end

function FCT.Options()
	E.Options.args.ElvFCT = {
		order = 1337,
		type = 'group',
		name = title,
		childGroups = "tab",
		args = {
			name = {
				order = 1,
				type = "header",
				name = title.." "..ver.." "..by,
			},
			nameplates = {
				order = 2,
				type = "group",
				name = L["NamePlates"],
				get = function(info) return ElvFCT.np[ info[#info] ] end,
				set = function(info, value) ElvFCT.np[ info[#info] ] = value end,
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
				get = function(info) return ElvFCT.uf[ info[#info] ] end,
				set = function(info, value) ElvFCT.uf[ info[#info] ] = value end,
				args = {
					enable = {
						order = 1,
						type = "toggle",
						name = L["Enable"],
					}
				}
			}
		},
	}

	for _, name in ipairs({'Player','Target','FriendlyPlayer','FriendlyNPC','EnemyPlayer','EnemyNPC'}) do
		FCT.AddOptions('nameplates', name)
	end
	for _, name in ipairs({'Player','Target','TargetTarget','TargetTargetTarget','Focus','FocusTarget','Pet','PetTarget','Arena','Boss','Party','Raid','Raid40','RaidPet','Assist','Tank'}) do
		FCT.AddOptions('unitframes', name)
	end
end

function FCT:Initialize()
	FCT.OptionsTable = {
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

	E.Libs.EP:RegisterPlugin(addon, FCT.Options)
end

hooksecurefunc(E, 'Initialize', FCT.Initialize)
