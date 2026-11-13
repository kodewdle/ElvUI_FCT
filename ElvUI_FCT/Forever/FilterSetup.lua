local _, ns = ...
local queued

local function status()
	if QUICKBUTTON_NAME_MY_ACTIONS then
		return ns.LogFilter.Check(Blizzard_CombatLog_Filters, QUICKBUTTON_NAME_MY_ACTIONS)
	end
end

function ns.AddLogFilterOptions(args)
	local L = ns[2].L
	local function filterName()
		return QUICKBUTTON_NAME_MY_ACTIONS or L["My actions"]
	end

	args.foreverLogStatus = {
		order = 1.2, type = 'description', width = 'full',
		name = function()
			local state = status()
			if state == 'ok' then
				return L["Combat log filter ready for player and pet damage."]
			elseif state == 'fixable' then
				return L["Configure the '%s' combat log filter to identify your hits and your pet's hits."]:format(filterName())
			elseif state == 'foreign' then
				return L["To identify your hits, select '%s' in the Combat Log tab, then reopen these options."]:format(filterName())
			elseif state == 'gone' then
				return L["Restore the '%s' filter in the Combat Log settings, then reopen these options."]:format(filterName())
			end
			return L["Open the Combat Log tab to load its filters, then reopen these options."]
		end,
	}
	args.foreverLogSetup = {
		order = 1.3, type = 'execute', name = L["Configure combat log and reload"],
		hidden = function() return status() ~= 'fixable' end,
		disabled = function() return InCombatLockdown() end,
		confirm = function()
			return L["Select '%s', limit its sources to you and your pet, enable damage and miss messages, update its event colors, and reload the UI?"]:format(filterName())
		end,
		func = function()
			if InCombatLockdown() or status() ~= 'fixable' then return end
			queued = true
			C_UI.Reload()
		end,
	}
end

-- Blizzard reads these settings on login. Apply only the confirmed change
-- during logout so it takes effect when the UI loads again.
function ns.ApplyQueuedLogFilter()
	if queued and status() == 'fixable' then
		ns.LogFilter.Fix(Blizzard_CombatLog_Filters, QUICKBUTTON_NAME_MY_ACTIONS)
	end
	queued = nil
end
