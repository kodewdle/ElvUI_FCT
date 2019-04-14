local addon, ns = ...

local E, L, V, P, G = unpack(ElvUI)
local FCT = E.Libs.AceAddon:NewAddon(addon, 'AceEvent-3.0')

local _G = _G
local ipairs = ipairs
local format = format
local hooksecurefunc = hooksecurefunc

local Version = GetAddOnMetadata(addon, "Version")
local version = format("[v|cFF508cf7%s|r]", Version)
local title = '|cfffe7b2cElvUI|r: |cFFF76ADBFCT|r'
local by = 'by |cFF8866ccSimpy|r and |cFF34dd61Lightspark|r (ls-)'

function FCT.AddOptions(arg1, arg2)
	if E.Options.args.ElvFCT.args[arg1].args[arg2] then return end
	E.Options.args.ElvFCT.args[arg1].args[arg2] = {
		order = FCT.OptionsTable[arg2][1],
		name = L[FCT.OptionsTable[arg2][2]],
		type = "group",
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

	-- Database
	FCT.db = E:CopyTable({}, ns.defaults)
	_G.ElvFCT = E:CopyTable(FCT.db, _G.ElvFCT)

	FCT:RegisterEvent("PLAYER_LOGOUT")

	E.Libs.EP:RegisterPlugin(addon, FCT.Options)
end

hooksecurefunc(E, 'Initialize', FCT.Initialize)
