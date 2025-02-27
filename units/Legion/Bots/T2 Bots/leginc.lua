return {
	leginc = {
		acceleration = 0.0552,
		brakerate = 0.43125,
		buildcostenergy = 46000,
		buildcostmetal = 2300,
		buildpic = "LEGINC.DDS",
		buildtime = 55000,
		canmove = true,
		category = "BOT MOBILE WEAPON ALL NOTSUB NOTSHIP NOTAIR NOTHOVER SURFACE EMPABLE",
		collisionvolumeoffsets = "0 4 -3",
		collisionvolumescales = "42 34 44",
		collisionvolumetype = "Box",
		corpse = "DEAD",
		explodeas = "explosiont3med",
		footprintx = 3,
		footprintz = 3,
		idleautoheal = 5,
		idletime = 1800,
		mass = 5001,
		maxdamage = 7000,
		maxslope = 15,
		maxvelocity = 0.75,
		maxwaterdepth = 23,
		movementclass = "HBOT4",
		nochasecategory = "VTOL",
		objectname = "Units/scavboss/leginc.s3o",
		pushresistant = true,
		script = "Units/scavboss/leginc.cob",
		seismicsignature = 0,
		selfdestructas = "explosiont3",
		sightdistance = 650,
		turninplace = true,
		turninplaceanglelimit = 90,
		turninplacespeedlimit = 0.495,
		turnrate = 120,
		customparams = {
			unitgroup = 'weapon',
			model_author = "Beherith",
			normaltex = "unittextures/cor_normal.dds",
			paralyzemultiplier = 1,
			subfolder = "corbots/t2",
			techlevel = 2,
		},
		featuredefs = {
			dead = {
				blocking = true,
				category = "corpses",
				collisionvolumeoffsets = "-2.34260559082 -0.241825708008 -1.33148193359",
				collisionvolumescales = "60.9344787598 36.418548584 64.3249511719",
				collisionvolumetype = "Box",
				damage = 4500,
				energy = 0,
				featuredead = "HEAP",
				featurereclamate = "SMUDGE01",
				footprintx = 3,
				footprintz = 3,
				height = 20,
				hitdensity = 100,
				metal = 1400,
				object = "Units/scavboss/leginc_dead.s3o",
				reclaimable = true,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "All Worlds",
			},
			heap = {
				blocking = false,
				category = "heaps",
				collisionvolumescales = "55.0 4.0 6.0",
				collisionvolumetype = "cylY",
				damage = 2500,
				energy = 0,
				featurereclamate = "SMUDGE01",
				footprintx = 3,
				footprintz = 3,
				height = 4,
				hitdensity = 100,
				metal = 550,
				object = "Units/cor3X3A.s3o",
				reclaimable = true,
				resurrectable = 0,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "All Worlds",
			},
		},
		sfxtypes = {
			pieceexplosiongenerators = {
				[1] = "deathceg2",
				[2] = "deathceg3",
				[3] = "deathceg4",
			},
		},
		sounds = {
			canceldestruct = "cancel2",
			underattack = "warning1",
			cant = {
				[1] = "cantdo4",
			},
			count = {
				[1] = "count6",
				[2] = "count5",
				[3] = "count4",
				[4] = "count3",
				[5] = "count2",
				[6] = "count1",
			},
			ok = {
				[1] = "kbcormov",
			},
			select = {
				[1] = "kbcorsel",
			},
		},
		weapondefs = {
			heatraylarge = {
				areaofeffect = 72,
				avoidfeature = false,
				beamtime = 0.033,
				camerashake = 0.1,
				--collidefriendly = false,
				corethickness = 0.3,
				craterareaofeffect = 72,
				craterboost = 0,
				cratermult = 0,
				edgeeffectiveness = 0.15,
				energypershot = 17,
				explosiongenerator = "custom:genericshellexplosion-medium-beam",
				firestarter = 90,
				firetolerance = 300,
				impulseboost = 0,
				impulsefactor = 0,
				laserflaresize = 6,
				name = "KrogHeatRay",
				noselfdamage = true,
				proximitypriority = -1,
				range = 800,
				reloadtime = 1000,
				rgbcolor = "1 0.8 0",
				rgbcolor2 = "0.8 0 0",
				soundhitdry = "",
				soundhitwet = "sizzle",
				soundstart = "burn02",
				soundstartvolume = 20,
				soundtrigger = 1,
				--sweepfire = true,
				targetmoveerror = 0.1,
				thickness = 4.5,
				turret = true,
				weapontype = "BeamLaser",
				weaponvelocity = 1500,
				customparams = {
					expl_light_life_mult = 1.1,
					light_mult = 2.66,
					light_radius_mult = 0.6,
				},
				damage = {
					commanders = 16,
					default = 33,
					vtol = 11,
				},
			},
			targetray = {
				areaofeffect = 72,
				avoidfeature = false,
				beamtime = 0.033,
				camerashake = 0.1,
				--collidefriendly = false,
				corethickness = 0.3,
				craterareaofeffect = 72,
				craterboost = 0,
				cratermult = 0,
				edgeeffectiveness = 0.15,
				energypershot = 0,
				explosiongenerator = "custom:genericshellexplosion-medium-beam",
				firestarter = 90,
				firetolerance = 300,
				impulseboost = 0,
				impulsefactor = 0,
				laserflaresize = 6,
				name = "KrogHeatRay",
				noselfdamage = true,
				proximitypriority = -1,
				range = 800,
				reloadtime = 0.033,
				rgbcolor = "1 0.8 0",
				rgbcolor2 = "0.8 0 1",
				soundhitdry = "",
				soundhitwet = "sizzle",
				soundstart = "burn02",
				soundstartvolume = 20,
				soundtrigger = 1,
				--sweepfire = true,
				targetmoveerror = 0.1,
				thickness = 4.5,
				turret = true,
				weapontype = "BeamLaser",
				weaponvelocity = 1500,
				customparams = {
					expl_light_life_mult = 1.1,
					light_mult = 2.66,
					light_radius_mult = 0.6,
				},
				damage = {
					commanders = 16,
					default = 33,
					vtol = 11,
				},
			},
		},
		weapons = {
			[1] = {
				def = "heatraylarge",
				onlytargetcategory = "SURFACE",
			},
			[2] = {
				def = "targetray",
				onlytargetcategory = "SURFACE",
			},
		},
	},
}
