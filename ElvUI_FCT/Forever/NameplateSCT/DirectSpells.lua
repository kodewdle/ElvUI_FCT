local _, ns = ...

-- The spells that hit directly, by the spell ID of their cast: a direct hit,
-- a weapon strike, a leech such as Death Coil, or a ranged attack, whose Hits
-- come with shot Log Lines. For each, the school its Hit reports, or that it
-- learns its school from its Hits, as a wand sets Shoot's. Which casts can
-- be a Hit's spell is decided in Identity's canHit (ADR 0004); a cast of a
-- spell in neither table, such as a buff or a Voidwalker's Torment, is never
-- one. The pets' spells are here so that they compete with the player's,
-- though they never win. Spells that also tick are in TickSpells.lua.
--
-- From Forever's spell data (wago.tools DB2, build 1.60.1.70888: SpellEffect
-- school damage, health leech and weapon damage effects, SpellMisc school),
-- for the cast of every spell in a class or pet skill line or a talent
-- (TraitDefinition), also where no trainer or talent is known to teach it,
-- and the ranged attacks; the Classic spells' schools agree with the Classic
-- Era data. Left out, among others: spells whose damage comes from another
-- spell (Arcane Missiles, Hellfire, Execute), procs (poisons, weapon enchants;
-- a Seal Proc has its own rule, see ns.Seals), totems, and Mana Burn. Holy
-- Shock, whose damage a script makes, is in, so that its Hit on an enemy gets its icon; the cost is
-- that its cast on a friend, which heals, competes with the casts that could
-- have made a Holy Hit.
--
-- Build 70888 took some IDs out of the skill lines (Primal Bite 1238073, Frost
-- Blast, and Forever's Lava Burst ranks). They stay, as a cast that no player
-- makes costs nothing.

local PHYSICAL, HOLY, FIRE, NATURE, FROST, SHADOW, ARCANE = 1, 2, 4, 8, 16, 32, 64

local spells = {}
ns.DirectSpells = spells

-- The ranks of a spell share one table, as nothing changes an entry.
local function addSpell(spell, ids)
	for _, id in ipairs(ids) do
		spells[id] = spell
	end
end

local function hits(school, ids)
	addSpell({ school = school }, ids)
end

-- A ranged attack: its Hits come with shot Log Lines, not direct ones.
local function shoots(school, ids)
	addSpell({ school = school, shot = true }, ids)
end

-- How long after its cast a Judgement's Hit can come. A live Paladin's 11 Hits and
-- misses came up to 0.166 s after it, and other players' 34 within 0.1 s. Its
-- damage is another spell, so only this nearness ties it to the cast.
local JUDGEMENT_WINDOW = 0.2

local function judges(ids)
	addSpell({ school = HOLY, window = JUDGEMENT_WINDOW }, ids)
end

-- The Seals, by the spell ID of their cast, from Forever's spell data, each with
-- whether its Seal Proc gets an icon (see Identity's sealProc). Any Seal's cast
-- replaces the Active Seal. Seal of Martyrdom also procs Holy damage, but no
-- Trace has it, so it only replaces the last Seal.
local seals = {}
ns.Seals = seals

local function sealsWith(proc, ids)
	for _, id in ipairs(ids) do
		seals[id] = proc
	end
end

sealsWith(true, { 20154, 20287, 20288, 20289, 20290, 20291, 20292, 20293, 21084 }) -- Righteousness
sealsWith(true, { 20375, 20915, 20918, 20919, 20920 }) -- Command
sealsWith(true, { 20163, 20419, 20421, 20422, 20423, 1311649, 1311656 }) -- Fury, Forever only
sealsWith(false, { 20164 }) -- Justice
sealsWith(false, { 20165, 20347, 20348, 20349 }) -- Light
sealsWith(false, { 20166, 20356, 20357 }) -- Wisdom
sealsWith(false, { 20162, 20305, 20306, 20307, 20308, 21082 }) -- the Crusader
sealsWith(false, { 407798 }) -- Martyrdom

-- Consecration's casts. Its ticks are direct Holy Hits with no cast of their
-- own, so during it they cannot be told from a Seal Proc (see Identity).
ns.ConsecrationSpells = { [20116] = true, [20922] = true, [20923] = true, [20924] = true, [26573] = true }

-- A Next-Swing Ability: its frame has an Empty Report before the real Hit (see
-- Pairing.New). Seen on Heroic Strike in the Warrior Trace and on other
-- players' Heroic Strikes in the open-world Traces. Unverified on Maul, Raptor
-- Strike, and Cleave, which replace a swing in the same way.
local function replacesSwing(ids)
	addSpell({ school = PHYSICAL, nextSwing = true }, ids)
end

do
	-- Ranged attacks
	spells[5019] = { learns = true, shot = true } -- Shoot, whose school its wand sets
	shoots(PHYSICAL, { 75 }) -- Auto Shot
	shoots(PHYSICAL, { 2480, 7918, 7919 }) -- Shoot Bow, Shoot Gun, Shoot Crossbow
	shoots(PHYSICAL, { 2764 }) -- Throw
	-- Druid
	hits(PHYSICAL, { 769, 779, 780, 9754, 9908 }) -- Swipe
	hits(ARCANE, { 2912, 8949, 8950, 8951, 9875, 9876, 25298 }) -- Starfire
	hits(PHYSICAL, { 1082, 3029, 5201, 9849, 9850 }) -- Claw
	hits(NATURE, { 5176, 5177, 5178, 5179, 5180, 6780, 8905, 9912 }) -- Wrath
	hits(PHYSICAL, { 5221, 6800, 8992, 9829, 9830 }) -- Shred
	hits(PHYSICAL, { 6785, 6787, 9866, 9867 }) -- Ravage
	replacesSwing({ 6807, 6808, 6809, 8972, 9745, 9880, 9881 }) -- Maul
	hits(PHYSICAL, { 22568, 22827, 22828, 22829, 31018 }) -- Ferocious Bite
	hits(PHYSICAL, { 1328618 }) -- Ferocious Bite, Forever only (a Druid's cast in the BFD group Trace)
	hits(PHYSICAL, { 407995, 1238069, 1238070, 1238073 }) -- Primal Bite, Forever only (the first rank is Mangle's ID)

	-- Hunter
	hits(PHYSICAL, { 1495, 14269, 14270, 14271 }) -- Mongoose Bite
	hits(PHYSICAL, { 2643 }) -- Multi-Shot
	hits(PHYSICAL, { 2974, 14267, 14268, 27633 }) -- Wing Clip
	hits(ARCANE, { 3044, 14281, 14282, 14283, 14284, 14285, 14286, 14287 }) -- Arcane Shot
	replacesSwing({ 2973, 14260, 14261, 14262, 14263, 14264, 14265, 14266 }) -- Raptor Strike
	hits(PHYSICAL, { 19306, 20909, 20910 }) -- Counterattack
	hits(PHYSICAL, { 19434, 20900, 20901, 20902, 20903, 20904, 27632 }) -- Aimed Shot
	hits(PHYSICAL, { 19503 }) -- Scatter Shot
	hits(PHYSICAL, { 1242634 }) -- Counterattack, Forever's rank
	hits(PHYSICAL, { 1310687, 1310785, 1310786 }) -- Sniper Shot, Forever only
	hits(PHYSICAL, { 1317257 }) -- Strider Kick, Forever only
	-- The cast's own hit; the hawk's attacks after it are not the player's.
	hits(PHYSICAL, { 1293241, 1293525, 1293526, 1293527 }) -- Summon Hawk, Forever only

	-- Mage
	hits(FROST, { 116, 205, 837, 7322, 8406, 8407, 8408, 10179, 10180, 10181, 25304 }) -- Frostbolt
	hits(FROST, { 120, 8492, 10159, 10160, 10161 }) -- Cone of Cold
	hits(FROST, { 122, 865, 6131, 10230 }) -- Frost Nova
	hits(ARCANE, { 1449, 8437, 8438, 8439, 10201, 10202 }) -- Arcane Explosion
	hits(FIRE, { 2136, 2137, 2138, 8412, 8413, 10197, 10199 }) -- Fire Blast
	hits(FIRE, { 2948, 8444, 8445, 8446, 10205, 10206, 10207 }) -- Scorch
	hits(FIRE, { 11113, 13018, 13019, 13020, 13021 }) -- Blast Wave
	hits(FIRE, { 2120, 2121, 8422, 8423, 10215, 10216 }) -- Flamestrike; its DoT is left out (TickSpells.lua)
	hits(FIRE, { 24530 }) -- Felfire
	hits(ARCANE, { 400574 }) -- Arcane Blast
	hits(FROST, { 400640 }) -- Ice Lance
	hits(ARCANE, { 1239696, 1239697, 1239699, 1239700 }) -- Arcane Blast, Forever's ranks
	hits(FROST, { 1240044, 1240045, 1240046, 1240047, 1312002 }) -- Ice Lance, Forever's ranks
	hits(FROST, { 1326053, 1326054, 1326055 }) -- Frost Blast, Forever only
	hits(ARCANE, { 1326079, 1326080, 1326081, 1326082 }) -- Arcane Wrath, Forever only

	-- Paladin
	hits(HOLY, { 879, 5614, 5615, 10312, 10313, 10314 }) -- Exorcism
	hits(HOLY, { 2812, 10318 }) -- Holy Wrath
	hits(HOLY, { 24239, 24274, 24275 }) -- Hammer of Wrath
	-- Weapon damage plus Holy damage; which school the Hit reports is untested.
	hits(HOLY, { 678, 679, 680, 1866, 2495, 5569, 10332, 10333 }) -- Holy Strike, Forever only
	hits(HOLY, { 1311606, 20473, 20929, 20930 }) -- Holy Shock; Forever's first rank, then the Classic ranks
	hits(HOLY, { 407632 }) -- Hammer of the Righteous
	judges({ 20271 }) -- Judgement

	-- Priest
	hits(HOLY, { 585, 591, 598, 984, 1004, 6060, 10933, 10934 }) -- Smite
	hits(SHADOW, { 8092, 8102, 8103, 8104, 8105, 8106, 10945, 10946, 10947 }) -- Mind Blast
	hits(HOLY, { 15237, 15430, 15431, 27799, 27800, 27801 }) -- Holy Nova
	hits(HOLY, { 1277331, 1277332, 1277333, 1277334, 1277335 }) -- Chastise, Forever only
	hits(SHADOW, { 1309595, 1309633, 1309635, 1309636 }) -- Shadow Word: Death, Forever only

	-- Rogue
	hits(PHYSICAL, { 53, 2589, 2590, 2591, 8721, 11279, 11280, 11281, 25300 }) -- Backstab
	hits(PHYSICAL, { 1752, 1757, 1758, 1759, 1760, 8621, 11293, 11294 }) -- Sinister Strike
	hits(PHYSICAL, { 1766, 1767, 1768, 1769 }) -- Kick
	hits(PHYSICAL, { 1776, 1777, 8629, 11285, 11286 }) -- Gouge
	hits(PHYSICAL, { 2098, 6760, 6761, 6762, 8623, 8624, 11299, 11300, 31016 }) -- Eviscerate
	hits(PHYSICAL, { 8676, 8724, 8725, 11267, 11268, 11269 }) -- Ambush
	hits(PHYSICAL, { 14251 }) -- Riposte
	hits(PHYSICAL, { 14278 }) -- Ghostly Strike
	hits(PHYSICAL, { 16511 }) -- Hemorrhage
	hits(PHYSICAL, { 1329283, 1329549 }) -- Shank, Forever only
	-- The casts. Each one makes two Hits, a main-hand and an off-hand strike
	-- (untested), and a cast gives its spell to one Hit, so only the first
	-- gets the icon.
	hits(PHYSICAL, { 1310707, 399956, 1241582, 1241584 }) -- Mutilate, Forever only

	-- Shaman
	hits(NATURE, { 403, 529, 548, 915, 943, 6041, 10391, 10392, 15207, 15208 }) -- Lightning Bolt
	hits(NATURE, { 421, 930, 2860, 10605 }) -- Chain Lightning
	hits(NATURE, { 8042, 8044, 8045, 8046, 10412, 10413, 10414 }) -- Earth Shock
	hits(FROST, { 8056, 8058, 10472, 10473 }) -- Frost Shock
	hits(PHYSICAL, { 17364 }) -- Stormstrike
	hits(FIRE, { 408490 }) -- Lava Burst
	hits(FIRE, { 1238299, 1238300, 1326047 }) -- Lava Burst, Forever's ranks

	-- Warlock
	hits(SHADOW, { 686, 695, 705, 1088, 1106, 7641, 11659, 11660, 11661, 25307 }) -- Shadow Bolt
	hits(FIRE, { 5676, 17919, 17920, 17921, 17922, 17923 }) -- Searing Pain
	hits(FIRE, { 6353, 17924 }) -- Soul Fire
	hits(SHADOW, { 6789, 17925, 17926 }) -- Death Coil
	hits(SHADOW, { 17877, 18867, 18868, 18869, 18870, 18871 }) -- Shadowburn
	hits(FIRE, { 17962, 18930, 18931, 18932 }) -- Conflagrate
	hits(FIRE, { 412758 }) -- Incinerate
	hits(FIRE, { 1293812, 1293813 }) -- Incinerate, Forever's ranks
	hits(FIRE, { 1293817, 1293818 }) -- Conflagrate, Forever's ranks

	-- Warrior
	hits(PHYSICAL, { 72, 1671, 1672 }) -- Shield Bash
	replacesSwing({ 78, 284, 285, 1608, 11564, 11565, 11566, 11567, 25286, 25712 }) -- Heroic Strike
	hits(PHYSICAL, { 694, 7400, 7402, 20559, 20560 }) -- Mocking Blow
	replacesSwing({ 845, 7369, 11608, 11609, 20569 }) -- Cleave
	hits(PHYSICAL, { 1464, 8820, 11604, 11605 }) -- Slam
	hits(PHYSICAL, { 1680 }) -- Whirlwind
	hits(PHYSICAL, { 1715, 7372, 7373, 27584 }) -- Hamstring
	hits(PHYSICAL, { 6343, 8198, 8204, 8205, 11580, 11581 }) -- Thunder Clap
	hits(PHYSICAL, { 6552, 6554 }) -- Pummel
	hits(PHYSICAL, { 6572, 6574, 7379, 11600, 11601, 25288 }) -- Revenge
	hits(PHYSICAL, { 7384, 7887, 11584, 11585 }) -- Overpower
	hits(PHYSICAL, { 12294, 21551, 21552, 21553, 27580 }) -- Mortal Strike
	hits(PHYSICAL, { 23881, 23892, 23893, 23894 }) -- Bloodthirst
	hits(PHYSICAL, { 23922, 23923, 23924, 23925 }) -- Shield Slam
	hits(PHYSICAL, { 402927 }) -- Victory Rush
	hits(PHYSICAL, { 1240193 }) -- Slam, Forever's rank
	hits(PHYSICAL, { 1310222 }) -- Spearing Strike, Forever only

	-- Pets
	hits(FIRE, { 3110, 7799, 7800, 7801, 7802, 9057, 11762, 11763, 15598, 18187 }) -- Firebolt, the Imp's
	hits(SHADOW, { 7814, 7815, 7816, 11778, 11779, 11780 }) -- Lash of Pain, the Succubus's
	hits(PHYSICAL, { 3009, 3010, 16827, 16828, 16829, 16830, 16831, 16832 }) -- Claw
	hits(PHYSICAL, { 17253, 17255, 17256, 17257, 17258, 17259, 17260, 17261 }) -- Bite
	hits(NATURE, { 24844, 25008, 25009, 25010, 25011, 25012 }) -- Lightning Breath
	hits(PHYSICAL, { 24423, 24577, 24578, 24579 }) -- Demoralizing Screech (Screech in Classic)
	hits(NATURE, { 26090, 26187, 26188, 1264455 }) -- Thunderstomp
	hits(FIRE, { 444678, 444681 }) -- Lava Breath
	hits(NATURE, { 1264478, 1264479, 1264480, 1264481, 1264482 }) -- Sonic Blast, Forever only
	hits(PHYSICAL, { 1264494, 1264497, 1264498, 1264501, 1264502 }) -- Swipe, Forever only
	hits(PHYSICAL, { 1264735, 1264736, 1264739, 1264741, 1264742 }) -- Pinch, Forever only
	hits(PHYSICAL, { 1264758, 1264927, 1264929, 1264930, 1264933 }) -- Dismember, Forever only
	hits(PHYSICAL, { 1265054, 1265055, 1265056, 1265057, 1265058 }) -- Mine!, Forever only
end
