mobs:register_mob("kpgmobs:deer", {
	type = "animal",
	hp_min = 4,
	hp_max = 8,
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1, 0.4},
	textures = {
		{"mobs_deer.png"},
	},
	visual = "mesh",
	mesh = "mobs_deer2.x",
	makes_footstep_sound = true,
	walk_velocity = 1,
	armor = 200,
	drops = {
		{name = "mobs:meat_raw",
		chance = 1,
		min = 2,
		max = 3,},
		{name = "mobs:leather", chance = 1, min = 1, max = 2},
	},
	drawtype = "front",
	water_damage = 1,
	lava_damage = 5,
	light_damage = 0,
	animation = {
		speed_normal = 15,
		stand_start = 25,		stand_end = 75,
		walk_start = 75,		walk_end = 100,
	},
	follow = "farming:wheat",
	view_range = 5,
	fear_height = 2,
	
	on_rightclick = function(self, clicker)
		if mobs:feed_tame(self, clicker, 8, true, true) then
			return
		end
		mobs:capture_mob(self, clicker, 0, 5, 60, false, nil)
	end,
})
mobs:register_spawn("kpgmobs:deer", {"default:dirt_with_grass"}, 20, 8, 9000, 1, 31000)
mobs:register_egg("kpgmobs:deer", "Deer", "wool_violet.png", 1)