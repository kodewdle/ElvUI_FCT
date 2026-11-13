local _, ns = ...

local Flow = {}
ns.Flow = Flow

-- Who swung, "player" or "pet", for a Hit that is a swing or a swing miss, or
-- nil. how is the rule that paired it (see Pairing.New). With no Line Kind, a
-- Hit that paired as melee is the best sign of a swing; a swing whose line came
-- in its own frame then does not count. A Weapon Proc's Hit pairs as melee too,
-- so it looks like a swing: the Hits of a proc and of its swing cannot be told
-- apart. The pet's swing lines are marked (see Adapter.New).
local function swingerOf(how, line)
	if how == "melee" or ns.LineKind.IsMelee(line.lineKind) then
		return line.pet and "pet" or "player"
	end
end

-- Connects the adapter, Pairing and Spell Identity, and sends on Your Hits
-- on enemies. Raw events go in through Push, in the shape of Trace entries.
-- Tick(now) closes the open frame and ends the holds that are over; call it
-- once each frame. show(hit, spellID, late, swinger, how, lineKind) gets Your
-- Hit on an enemy Nameplate, with the spell that made it or nil (see
-- Identity.New), and who swung (see swingerOf). how and lineKind, the Line Kind
-- of its Log Line or nil when the colour told none, say how it was decided;
-- the renderer needs neither. noPlate(hit, how), which is optional, gets Your
-- Hit on target or a soft target that has no Nameplate.
-- spellFacts, which is required, holds the Spell Facts, which
-- Identity changes in place. Hits on the player or the pet go nowhere: they
-- are there to use up the Log Lines of heals and self-damage.
-- A Hit decided after its Nameplate hid, such as a killing blow whose Log
-- Line came late, is a late Hit: its token can by then name another unit, or
-- none. show gets it with late, the Nameplate as it hid: { frame, wasTarget,
-- classification, isBoss, isPlayer }, from the NAME_PLATE_UNIT_REMOVED entry
-- (Events.lua), which the adapter keeps on the Hit's plate life. A late Hit
-- whose frame the game gave to a new unit since the hide is not shown, as
-- its text would show where that unit is or was.
function Flow.New(options)
	local show, noPlate = options.show, options.noPlate
	local identity = ns.Identity.New(options.spellFacts)
	-- Pairing's decisions of Your Hits on enemies, and the casts, in the order
	-- they came. Identity takes the decisions that come together as one group,
	-- so it can see two ticks that come at once. Identity and show run after
	-- Pairing returns, so an error in them cannot drop the rest of Pairing's
	-- frame; it drops the rest of the queue.
	local pending = {}

	local pairing = ns.Pairing.New({
		onDecision = function(hit, line, how)
			if line and not ns.Adapter.OWN_UNITS[hit.unit] then
				pending[#pending + 1] = { hit = hit, line = line, how = how }
			end
		end,
		schoolOf = identity.SchoolOf,
	})
	-- A cast goes in after Pairing has decided the frames before it.
	local adapter = ns.Adapter.New(function(record)
		if record.kind == "line" then
			identity.Line(record)
		end
		pairing.Push(record)
		if record.kind == "cast" then
			pending[#pending + 1] = { cast = record }
		end
	end)

	local function send(decisions)
		if #decisions == 0 then
			return
		end
		local spellIDs = identity.OfAll(decisions)
		for i, decision in ipairs(decisions) do
			local hit, life = decision.hit, decision.hit.life
			if not life then
				if noPlate then
					noPlate(hit, decision.how)
				end
			elseif not life.reused then
				show(hit, spellIDs[i], life.hid, swingerOf(decision.how, decision.line), decision.how, decision.line.lineKind)
			end
		end
	end

	local function flush()
		if #pending == 0 then
			return
		end
		local items = pending
		pending = {}
		local decisions = {}
		for _, item in ipairs(items) do
			if item.cast then
				send(decisions)
				decisions = {}
				identity.Cast(item.cast)
			else
				decisions[#decisions + 1] = item
			end
		end
		send(decisions)
	end

	local function tick(now)
		adapter.Tick(now)
		pairing.Tick(now)
		flush()
	end

	local flow = {}

	function flow.Push(entry)
		if entry[2] == "NAME_PLATE_UNIT_REMOVED" then
			-- Decide the Hits from before this moment first, as the live Tick of
			-- each frame does, so the result is the same at any tick rate.
			tick(entry[1])
		end
		adapter.Push(entry)
		flush()
	end

	flow.Tick = tick

	return flow
end
