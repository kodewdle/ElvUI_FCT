local _, ns = ...

ns.defaults = {
	colors = {},
	exclude = {},
	stacks = {
		overtime = true,
		showCrits = false,
		sendDelay = 0.3,
		tickWait = 5,
		hitsDetect = true,
		hitsWait = 5,
		hitAmount = 5,
		prefix = 'x',
		exclude = {}
	},
	nameplates = {
		enable = true,
		frames = {
			Player = {},
			FriendlyPlayer = {
				enable = true,
				mode = 'LS',
				alternateIcon = true,
				isTarget = true,
				showIcon = true,
				showHots = true,
				showDots = true,
				iconX = -5,
				spellY = 5
			},
			FriendlyNPC = {
				enable = true,
				mode = 'LS',
				alternateIcon = true,
				isTarget = true,
				showIcon = true,
				showHots = true,
				showDots = true,
				iconX = -5,
				spellY = 5
			},
			EnemyPlayer = {
				enable = true,
				mode = 'LS',
				alternateIcon = true,
				isTarget = true,
				showIcon = true,
				showHots = true,
				showDots = true,
				iconX = -5,
				spellY = 5
			},
			EnemyNPC = {
				enable = true,
				mode = 'LS',
				alternateIcon = true,
				isTarget = true,
				showIcon = true,
				showHots = true,
				showDots = true,
				iconX = -5,
				spellY = 5
			},
		}
	},
	unitframes = {
		enable = true,
		frames = {
			Player = {
				enable = true,
				showName = true,
				showHots = true,
				showDots = true,
				stackingOthers = true,
				iconX = -5,
				spellY = 2
			},
			Target = {
				enable = true,
				showName = true,
				showHots = true,
				showDots = true,
				stackingOthers = true,
				iconX = -5,
				spellY = 2
			},
			TargetTarget = {},
			TargetTargetTarget = {},
			Focus = {
				enable = true,
				showIcon = true,
				iconX = -5,
				spellY = 2
			},
			FocusTarget = {
				enable = true,
				showIcon = true,
				iconX = -5,
				spellY = 2
			},
			Pet = {},
			PetTarget = {},
			Arena = {},
			Boss = {
				enable = true,
				showIcon = true,
				iconX = -5,
				spellY = 2
			},
			Party = {},
			Raid1 = {},
			Raid2 = {},
			Raid3 = {},
			RaidPet = {},
			Assist = {},
			Tank = {},
		}
	}
}

ns.frames = {
	enable = false,
	font = 'Expressway',
	fontSize = 14,
	fontOutline = 'OUTLINE',
	critFont = 'Expressway',
	critFontSize = 18,
	critFontOutline = 'OUTLINE',
	mode = 'Simpy',
	stackingSelf = true,
	stackingOthers = false,
	alternateIcon = false,
	shakeDuration = 0.25,
	critShake = false,
	textShake = false,
	showIcon = false,
	showName = false,
	showHots = false,
	showDots = false,
	isTarget = false,
	isPlayer = true,
	showPet = true,
	iconSize = 16,
	followSize = false,
	cycleColors = true,
	numberStyle = 'SHORT',
	prefix = '*',
	textY = 0,
	textX = 0,
	iconY = 0,
	iconX = 0,
	spellY = 0,
	spellX = 0,
	advanced = {
		anim = 'fountain',
		radius = 64,
		numTexts = 25,
		ScrollTime = 1.5,
		FadeTime = 0.5,
		DirectionX = 1,
		DirectionY = 1,
		OffsetX = 24,
		OffsetY = 8,
		AlternateX = true,
		AlternateY = false,
	}
}

ns.colors = {
	Stack    = {r=0.46, g=0.33, b=1.00, n='Stack Prefix'},    --[7755FF]
	Prefix   = {r=0.00, g=0.60, b=1.00, n='Critical Prefix'}, --[0099FF]
	Heal     = {r=0.20, g=1.00, b=0.20, n='Heal'},            --[32FF32]
	Ranged   = {r=0.40, g=0.40, b=0.40, n='Ranged'},          --[666666]
	Physical = {r=0.60, g=0.40, b=0.20, n='Physical'},        --[996633]
	Standard = {r=1.00, g=1.00, b=1.00, n='Standard'},	      --[FFFFFF]
	[01] = {r=1.00, g=0.20, b=0.20, n='Damage'}, --[FF3232]
	[02] = {r=1.00, g=1.00, b=0.29, n='Holy'},   --[FFFF4B]
	[04] = {r=1.00, g=0.39, b=0.00, n='Fire'},   --[FF6400]
	[08] = {r=0.59, g=1.00, b=0.20, n='Nature'}, --[96FF32]
	[16] = {r=0.29, g=1.00, b=1.00, n='Frost'},  --[4BFFFF]
	[32] = {r=0.69, g=0.29, b=1.00, n='Shadow'}, --[AF4BFF]
	[64] = {r=1.00, g=0.29, b=0.69, n='Arcane'}  --[FF4BAF]
}
