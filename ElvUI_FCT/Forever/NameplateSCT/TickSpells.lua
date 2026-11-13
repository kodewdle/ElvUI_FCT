local _, ns = ...

-- The damage spells that tick, by the spell ID of their cast. For each: the
-- time between ticks, and the longest time any rank ticks for with its
-- talents, in seconds; the school of its ticks, which is also the school of
-- its direct hit (a spell in this table needs no Spell Facts); whether its
-- cast also hits; whether it travels to its target first; and whether it is
-- an area spell, whose ticks come as direct Log Lines. Spell Identity reads
-- ticks only from this table (ADR 0004).
--
-- From Forever's spell data (wago.tools DB2, build 1.60.1.70888: SpellEffect
-- periodic damage and leech auras and school damage effects, SpellMisc school
-- and missile speed, SpellDuration), for the cast of every spell in a class
-- or pet skill line or a talent (TraitDefinition), also where no trainer or
-- talent is known to teach it; the Classic spells' values agree with the
-- Classic Era data. Left out: ticks with no cast of their own (Ignite, Deep
-- Wounds, Deadly Poison), traps, totems (the totem is the source), Hellfire
-- and Arcane Missiles (their damage hits rather than ticks), Wyvern Sting,
-- Curse of Doom (Bane of Doom on Forever; one tick at 60 s), and the area
-- spells that are not channels (Consecration, Flamestrike's DoT). Corruption,
-- Bane of Agony, Immolate, Drain Life and Drain Soul are checked against the
-- Warlock Traces.
--
-- On Forever the area spells tick from an area trigger, not Classic's area
-- aura, at the same interval, and each tick is a direct hit of another spell
-- ID: Rain of Fire's in the Rain of Fire Trace, the others untested. Only the
-- channelled ones are here (Blizzard, Hurricane, Rain of Fire, Volley): the
-- player can neither swing nor cast while channelling, and the channel's stop
-- ends the ticks, so a proc with no cast, such as a seal's, seldom lands on
-- the tick grid. During Consecration such procs would take its icon.
--
-- Ticks come only from the player's casts. The pets' spells are here so that
-- a pet's missed application competes with the player's casts, as in
-- DirectSpells.lua.

local PHYSICAL, HOLY, FIRE, NATURE, FROST, SHADOW, ARCANE = 1, 2, 4, 8, 16, 32, 64

local spells = {}
ns.TickSpells = spells

-- The ranks of a spell share one table, as nothing changes an entry.
local function ticks(interval, school, duration, kind, ids)
	local spell = {
		interval = interval,
		school = school,
		duration = duration,
		hits = kind.hits == true,
		travels = kind.travels == true,
		area = kind.area == true,
	}
	for _, id in ipairs(ids) do
		spells[id] = spell
	end
end

do
	-- Druid
	ticks(3, NATURE, 27, {}, { 339, 1062, 5195, 5196, 9852, 9853 }) -- Entangling Roots
	ticks(2, PHYSICAL, 12, {}, { 1079, 9492, 9493, 9752, 9894, 9896 }) -- Rip
	ticks(3, PHYSICAL, 9, { hits = true }, { 1822, 1823, 1824, 9904 }) -- Rake
	ticks(2, NATURE, 12, {}, { 5570, 24974, 24975, 24976, 24977 }) -- Insect Swarm
	ticks(3, ARCANE, 12, { hits = true }, { 8921, 8924, 8925, 8926, 8927, 8928, 8929, 9833, 9834, 9835 }) -- Moonfire
	ticks(1, NATURE, 10, { area = true }, { 16914, 17401, 17402 }) -- Hurricane
	ticks(3, PHYSICAL, 15, {}, { 414644 }) -- Lacerate
	ticks(3, PHYSICAL, 18, {}, { 9005, 9823, 9827 }) -- Pounce; its ticks are Pounce Bleed's
	ticks(3, PHYSICAL, 15, {}, { 1235826, 1235827, 1328616, 1328617 }) -- Lacerate, Forever's ranks (interval untested)

	-- Hunter
	ticks(1, ARCANE, 6, { travels = true, area = true }, { 1510, 14294, 14295 }) -- Volley
	ticks(3, NATURE, 15, { travels = true }, { 1978, 13549, 13550, 13551, 13552, 13553, 13554, 13555, 25295 }) -- Serpent Sting
	ticks(2, SHADOW, 30, { travels = true }, { 3674, 14296 }) -- Black Arrow
	ticks(3, PHYSICAL, 21, {}, { 24118, 24119, 24120, 1299332 }) -- Lacerate, the Hunter's

	-- Mage
	ticks(1, FROST, 8, { area = true }, { 10, 6141, 8427, 10185, 10186, 10187 }) -- Blizzard
	ticks(2, FIRE, 8, { hits = true, travels = true }, { 133, 143, 145, 3140, 8400, 8401, 8402, 10148, 10149, 10150, 10151, 25306 }) -- Fireball
	ticks(3, FIRE, 12, { hits = true, travels = true }, { 11366, 12505, 12522, 12523, 12524, 12525, 12526, 18809 }) -- Pyroblast
	ticks(3, FIRE + FROST, 9, { hits = true, travels = true }, { 401502 }) -- Frostfire Bolt
	ticks(3, FIRE + FROST, 9, { hits = true, travels = true }, { 1237312, 1237313 }) -- Frostfire Bolt, Forever's ranks (interval untested)

	-- Priest
	-- Shadow Word: Pain lasts 18 s, and Improved Shadow Word: Pain adds 6.
	ticks(3, SHADOW, 24, {}, { 589, 594, 970, 992, 2767, 10892, 10893, 10894 }) -- Shadow Word: Pain
	ticks(3, SHADOW, 24, {}, { 2944, 19276, 19277, 19278, 19279, 19280 }) -- Devouring Plague
	ticks(1, ARCANE, 6, {}, { 10797, 19296, 19299, 19302, 19303, 19304, 19305 }) -- Starshards
	ticks(2, HOLY, 10, { hits = true }, { 14914, 15261, 15262, 15263, 15264, 15265, 15266, 15267 }) -- Holy Fire
	ticks(1, SHADOW, 3, {}, { 15407, 17311, 17312, 17313, 17314, 18807 }) -- Mind Flay
	ticks(1, HOLY, 2, { hits = true }, { 402174, 1240720, 1240721, 1316995 }) -- Penance, Forever only (untested; may hit, not tick)

	-- Rogue
	ticks(3, PHYSICAL, 18, {}, { 703, 8631, 8632, 8633, 11289, 11290 }) -- Garrote
	ticks(2, PHYSICAL, 16, {}, { 1943, 8639, 8640, 11273, 11274, 11275 }) -- Rupture
	ticks(6, PHYSICAL, 6, {}, { 1316709, 1325756, 1325757, 1325758 }) -- Death Mark, Forever only (one tick as it ends; untested)

	-- Shaman
	ticks(3, FIRE, 12, { hits = true }, { 8050, 8052, 8053, 10447, 10448, 29228 }) -- Flame Shock

	-- Warlock
	ticks(3, SHADOW, 18, {}, { 172, 6222, 6223, 7648, 11671, 11672, 25311 }) -- Corruption
	ticks(3, FIRE, 15, { hits = true }, { 348, 707, 1094, 2941, 11665, 11667, 11668, 25309 }) -- Immolate
	ticks(1, SHADOW, 5, {}, { 689, 699, 709, 7651, 11699, 11700 }) -- Drain Life
	ticks(2, SHADOW, 24, {}, { 980, 1014, 6217, 11711, 11712, 11713 }) -- Curse of Agony; Bane of Agony on Forever
	ticks(3, SHADOW, 15, {}, { 1120, 8288, 8289, 11675 }) -- Drain Soul
	ticks(2, FIRE, 8, { area = true }, { 5740, 6219, 11677, 11678 }) -- Rain of Fire
	ticks(3, SHADOW, 30, {}, { 18265, 18879, 18880, 18881 }) -- Siphon Life
	ticks(1, SHADOW, 6, {}, { 1316697 }) -- Wrack, Forever only (a channel)

	-- Warrior
	ticks(3, PHYSICAL, 21, {}, { 772, 6546, 6547, 6548, 11572, 11573, 11574 }) -- Rend

	-- Pets
	ticks(2, NATURE, 10, {}, { 24583, 24586, 24587, 24640 }) -- Scorpid Poison
	ticks(3, PHYSICAL, 9, {}, { 1265038, 1265039, 1265040, 1265041, 1265042 }) -- Tendon Rip, Forever only
	ticks(3, PHYSICAL, 18, {}, { 1265065, 1265066, 1265067, 1265068, 1265069 }) -- Savage Rend, Forever only
	ticks(1, NATURE, 4, {}, { 1265843, 1265878, 1265880, 1265881, 1265883 }) -- Web, Forever only
end
