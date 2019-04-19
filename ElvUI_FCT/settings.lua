local _, ns = ...

ns.defaults = {
	colors = {},
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
				iconX = -5,
				spellY = 5
			},
			FriendlyNPC = {
				enable = true,
				mode = 'LS',
				alternateIcon = true,
				isTarget = true,
				showIcon = true,
				iconX = -5,
				spellY = 5
			},
			EnemyPlayer = {
				enable = true,
				mode = 'LS',
				alternateIcon = true,
				isTarget = true,
				showIcon = true,
				iconX = -5,
				spellY = 5
			},
			EnemyNPC = {
				enable = true,
				mode = 'LS',
				alternateIcon = true,
				isTarget = true,
				showIcon = true,
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
				iconX = -5,
				spellY = 2
			},
			Target = {
				enable = true,
				showName = true,
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
			Raid = {},
			Raid40 = {},
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
	mode = 'Simpy',
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
	cycleColors = true,
	numberStyle = 'SHORT',
	textY = 0,
	textX = 0,
	iconY = 0,
	iconX = 0,
	spellY = 0,
	spellX = 0,
	exclude = {
		[145109] = true, -- Ysera's Gift (self healing)
	},
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
	['-3'] = {r=050/255, g=255/255, b=050/255, n='Heal'},     --[32FF32]
	['-2'] = {r=102/255, g=102/255, b=102/255, n='Ranged'},   --[666666]
	['-1'] = {r=153/255, g=102/255, b=051/255, n='Physical'}, --[996633]
	['00'] = {r=255/255, g=255/255, b=255/255, n='Standard'}, --[FFFFFF]
	['01'] = {r=255/255, g=050/255, b=050/255, n='Damage'},   --[FF3232]
	['02'] = {r=255/255, g=255/255, b=075/255, n='Holy'},     --[FFFF4B]
	['04'] = {r=255/255, g=100/255, b=000/255, n='Fire'},     --[FF6400]
	['08'] = {r=150/255, g=255/255, b=050/255, n='Nature'},   --[96FF32]
	['16'] = {r=075/255, g=255/255, b=255/255, n='Frost'},    --[4BFFFF]
	['32'] = {r=175/255, g=075/255, b=255/255, n='Shadow'},   --[AF4BFF]
	['64'] = {r=255/255, g=075/255, b=175/255, n='Arcane'}    --[FF4BAF]
}
