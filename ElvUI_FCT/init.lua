local addon, ns = ...
local E, L, V, P, G = unpack(ElvUI)

local format = format
local version = GetAddOnMetadata(addon, "Version")
local title = '|cfffe7b2cElvUI|r: |cFFF76ADBFCT|r'
local by = '|cFF8866ccSimpy|r and |cFF34dd61Lightspark|r (ls-)'
local ver = format("[v|cFF508cf7%s|r]", version)

local function options()
	E.Options.args.ElvFCT = {
		order = 1337,
		type = 'group',
		name = title,
		get = function(info) return ElvFCT[ info[#info] ] end,
		set = function(info, value) ElvFCT[ info[#info] ] = value end,
		args = {
			name = {
				order = 1,
				type = "header",
				name = title.." "..ver.." "..by,
			},
		},
	}
end

LibStub("LibElvUIPlugin-1.0"):RegisterPlugin(addon, options)
