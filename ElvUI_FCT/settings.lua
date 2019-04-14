local _, ns = ...

ns.defaults = {
	nameplates = {
		enable = false,
		frames = {
			Player = {},
			Target = {},
			FriendlyPlayer = {},
			FriendlyNPC = {},
			EnemyPlayer = {},
			EnemyNPC = {},
		}
	},
	unitframes = {
		enable = false,
		frames = {
			TargetTarget = {},
			TargetTargetTarget = {},
			Focus = {},
			FocusTarget = {},
			Pet = {},
			PetTarget = {},
			Arena = {},
			Boss = {},
			Party = {},
			Raid = {},
			Raid40 = {},
			RaidPet = {},
			Assist = {},
			Tank = {},
		}
	}
}

ns.frameDefaults = {
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
	exclude = {
		[145109] = true, -- Ysera's Gift (self healing)
	}
}
