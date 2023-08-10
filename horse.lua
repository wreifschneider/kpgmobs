-- horse functions

local function is_ground(pos)
	local nn = minetest.get_node(pos).name
	return minetest.get_item_group(nn, "crumbly") ~= 0
	or minetest.get_item_group(nn, "cracky") ~= 0
	or minetest.get_item_group(nn, "choppy") ~= 0
	or minetest.get_item_group(nn, "snappy") ~= 0
	or minetest.get_item_group(nn, "unbreakable") ~= 0
end

local function get_sign(i)
	if i == 0 then
		return 0
	else
		return i/math.abs(i)
	end
end

local function get_velocity(v, yaw, y)
	local x = math.cos(yaw)*v
	local z = math.sin(yaw)*v
	return {x=x, y=y, z=z}
end

local function get_v(v)
	return math.sqrt(v.x^2+v.z^2)
end

function merge(a, b)
   if type(a) == 'table' and type(b) == 'table' then
        for k,v in pairs(b) do if type(v)=='table' and type(a[k] or false)=='table' then merge(a[k],v) else a[k]=v end end
    end
    return a
end

-- HORSE go go goooo :)

local horse = {
	physical = true,
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1, 0.4},
	visual = "mesh",
	stepheight = 1.1,
	visual_size = {x=1,y=1},
	mesh = "mobs_horseh1.x",
	driver = nil,
	v = 0,
	removed = false,
	last_v = 0,
}

function horse.on_rightclick (self, clicker)
	if not clicker or not clicker:is_player() then
		return
	end

	local name = clicker:get_player_name()

	if self.driver and clicker == self.driver then
		self.driver = nil
		clicker:set_detach()
		default.player_attached[name] = false
		default.player_set_animation(clicker, "stand" , 30)
		local pos = clicker:getpos()
		pos = {x = pos.x, y = pos.y + 0.2, z = pos.z}
		minetest.after(0.1, function()
			clicker:setpos(pos)
		end)
	elseif not self.driver then
		local attach = clicker:get_attach()
		if attach and attach:get_luaentity() then
			local luaentity = attach:get_luaentity()
			if luaentity.driver then
				luaentity.driver = nil
			end
			clicker:set_detach()
		end
		self.driver = clicker
		clicker:set_attach(self.object, "",
			{x = -3, y = 21, z = 0}, {x = 0, y = 90, z = 0})
		default.player_attached[name] = true
		minetest.after(0.2, function()
			default.player_set_animation(clicker, "sit" , 30)
		end)
		self.object:setyaw(clicker:get_look_horizontal() + math.pi / 2 )
	end
end

function horse.on_activate(self, staticdata, dtime_s)
	self.object:set_armor_groups({immortal=1})
	if staticdata then
		self.v = tonumber(staticdata)
	end
	self.last_v = self.v

	print (self.jmp)
end

function horse.get_staticdata(self)
	return tostring(self.v)
end

function horse.on_punch(self, puncher)--, time_from_last_punch, tool_capabilities, direction)

	if not puncher or not puncher:is_player() or self.removed then
		return
	end
	if self.driver and puncher == self.driver then
		self.driver = nil
		puncher:set_detach()
		default.player_attached[puncher:get_player_name()] = false
	end
	if not self.driver then
		self.removed = true
		-- delay remove to ensure player is detached
		minetest.after(0.1, function()
			self.object:remove()
		end)
		if not minetest.setting_getbool("creative_mode") then
			local inv = puncher:get_inventory()
			if inv:room_for_item("main", self.name) then
				inv:add_item("main", self.name)
			else
				minetest.add_item(self.object:getpos(), self.name)
			end
		end
	end
end

function horse.on_step(self, dtime)

	self.v = get_v(self.object:getvelocity())*get_sign(self.v)

	if self.driver then

		local ctrl = self.driver:get_player_control()

		if ctrl.up then
			self.v = self.v + self.jmp
		end
		if ctrl.down then
			self.v = self.v-0.5
		end
		if ctrl.left then
			self.object:setyaw(self.object:getyaw()+math.pi/20+dtime*math.pi/50)
		end
		if ctrl.right then
			self.object:setyaw(self.object:getyaw()-math.pi/20-dtime*math.pi/50)
		end
		if ctrl.jump then
			local p = self.object:getpos()
			p.y = p.y-0.5
			if is_ground(p) then
				local pos = self.object:getpos()
				pos.y = math.floor(pos.y)+4
				self.object:setpos(pos)
				self.object:setvelocity(get_velocity(self.v, self.object:getyaw(), 0))
			end
		end
	end

	local s = get_sign(self.v)
	self.v = self.v - 0.02*s

	if s ~= get_sign(self.v) then
		self.object:setvelocity({x=0, y=0, z=0})
		self.v = 0
		return
	end

	if math.abs(self.v) > self.spd then
		self.v = 10*get_sign(self.v)
	end

	local p = self.object:getpos()
	p.y = p.y-0.5

	if not is_ground(p) then
		if minetest.registered_nodes[minetest.get_node(p).name].liquidtype ~= "none" then
			self.object:setacceleration({x=0, y=0, z=0})
			self.object:setvelocity({x=0, y=0, z=0})
		else
			self.object:setacceleration({x=0, y=-10, z=0})
			self.object:setvelocity(get_velocity(self.v, self.object:getyaw(), self.object:getvelocity().y))
		end
	else
		self.object:setacceleration({x=0, y=0, z=0})
		-- falling
		if math.abs(self.object:getvelocity().y) < 1 then
			local pos = self.object:getpos()
			pos.y = math.floor(pos.y)+0.5
			self.object:setpos(pos)
			self.object:setvelocity(get_velocity(self.v, self.object:getyaw(), 0))
		else
			self.object:setvelocity(get_velocity(self.v, self.object:getyaw(), self.object:getvelocity().y))
		end
	end
end

--END HORSE

-- backup table
local hbak = horse

-- Brown Horse

local hrs = {
	textures = {"mobs_horseh1.png"},
	spd = 10,
	jmp = 2,
}
minetest.register_entity("kpgmobs:horseh1", merge(hrs, horse))

-- White Horse

horse = hbak
local peg = {
	textures = {"mobs_horsepegh1.png"},
	spd = 12,
	jmp = 3,
}
minetest.register_entity("kpgmobs:horsepegh1", merge(peg, horse))

-- Black Horse

horse = hbak
local ara = {
	textures = {"mobs_horsearah1.png"},
	spd = 11,
	jmp = 2,
}
minetest.register_entity("kpgmobs:horsearah1", merge(ara, horse))

minetest.register_craftitem("kpgmobs:horseh1", {
	description = "Brown Horse with Saddle",
	inventory_image = "mobs_horse_inv.png",
	wield_image = "mobs_horse_inv.png",
	liquids_pointable = true,

	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" then return end
		pointed_thing.under.y = pointed_thing.under.y + 0.5
		minetest.add_entity(pointed_thing.under, "kpgmobs:horseh1")
		if not minetest.setting_getbool("creative_mode") then
			itemstack:take_item()
		end
		return itemstack
	end,
})
minetest.register_craftitem("kpgmobs:horsepegh1", {
	description = "White Horse with Saddle",
	inventory_image = "mobs_horse_peg_inv.png",
	wield_image = "mobs_horse_peg_inv.png",
	liquids_pointable = true,

	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" then return end
		pointed_thing.under.y = pointed_thing.under.y + 0.5
		minetest.add_entity(pointed_thing.under, "kpgmobs:horsepegh1")
		if not minetest.setting_getbool("creative_mode") then
			itemstack:take_item()
		end
		return itemstack
	end,
})
minetest.register_craftitem("kpgmobs:horsearah1", {
	description = "Arabic Horse with Saddle",
	inventory_image = "mobs_horse_ara_inv.png",
	wield_image = "mobs_horse_ara_inv.png",
	liquids_pointable = true,

	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" then return end
		pointed_thing.under.y = pointed_thing.under.y + 0.5
		minetest.add_entity(pointed_thing.under, "kpgmobs:horsearah1")
		if not minetest.setting_getbool("creative_mode") then
			itemstack:take_item()
		end
		return itemstack
	end,
})

-- tamed horse spawn eggs
-- mobs:register_egg("kpgmobs:horseh1", "Brown Horse with Saddle", "mobs_horse_inv.png", 0)
-- mobs:register_egg("kpgmobs:horsepegh1", "White Horse with Saddle", "mobs_horse_peg_inv.png", 0)
-- mobs:register_egg("kpgmobs:horsearah1", "Arabic Horse with Saddle", "mobs_horse_ara_inv.png", 0)

-- saddle
minetest.register_craftitem("kpgmobs:saddle", {
	description = "Saddle",
	inventory_image = "mobs_saddle.png",
})

minetest.register_craft({
	output = "kpgmobs:saddle",
	recipe = {
		{'mobs:leather', 'mobs:leather', 'mobs:leather'},
		{'mobs:leather', 'default:steel_ingot', 'mobs:leather'},
		{'mobs:leather', 'default:steel_ingot', 'mobs:leather'},
	}
})
local HColors = {
	"brown",
	"white",
	"black",
}

local TexturesSub = ""
local InvSub = ""

for _, colors in ipairs(HColors) do

	if colors == "brown" then
		TexturesSub = "mobs_horse.png"
	elseif colors == "white" then
		TexturesSub = "mobs_horsepeg.png"
	else
		TexturesSub = "mobs_horseara.png"
	end

	mobs:register_mob("kpgmobs:horse_" .. colors, {
		type = "animal",
		hp_min = 10,
		hp_max = 20,
		collisionbox = {-0.4, -0.01, -0.4, 0.4, 1, 0.4},
		textures = {{TexturesSub,}},
		visual = "mesh",
		mesh = "mobs_horse.x",
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
		fear_height = 2,
		animation = {
			speed_normal = 15,
			stand_start = 25,		stand_end = 75,
			walk_start = 75,		walk_end = 100,
		},
		follow = {"farming:wheat" ,"farming:barley",},
		view_range = 5,
		owner = "",

		on_rightclick = function(self, clicker)
			if mobs:feed_tame(self, clicker, 8, true, true) then
				if self.owner
				and self.owner == clicker:get_player_name() then
					local pos = self.object:getpos()
					local mob = minetest.add_entity( pos, "kpgmobs:horse_" .. colors .. "_tamed")
					local ent = mob:get_luaentity()
					ent.owner = clicker:get_player_name()
					ent.tamed = true
					self.object:remove()
				end
				return
			end
			minetest.chat_send_player(clicker:get_player_name(), "Not tamed")
		end,
	})
	mobs:register_spawn("kpgmobs:horse_" .. colors, {"default:dirt_with_grass"}, 20, 8, 11000, 1, 31000)
end

for _, colors in ipairs(HColors) do

	if colors == "brown" then
		TexturesSub = "mobs_horse.png"
		InvSub = "mobs_horse_inv.png"
	elseif colors == "white" then
		TexturesSub = "mobs_horsepeg.png"
		InvSub = "mobs_horse_peg_inv.png"
	else
		TexturesSub = "mobs_horseara.png"
		InvSub = "mobs_horse_ara_inv.png"
	end

	mobs:register_mob("kpgmobs:horse_" .. colors .. "_tamed", {
		type = "npc",
		hp_min = 10,
		hp_max = 20,
		collisionbox = {-0.4, -0.01, -0.4, 0.4, 1, 0.4},
		textures = {{TexturesSub},},
		visual = "mesh",
		mesh = "mobs_horse.x",
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
		fear_height = 2,
		animation = {
			speed_normal = 15,
			stand_start = 25,		stand_end = 75,
			walk_start = 75,		walk_end = 100,
		},
		follow = {"farming:wheat" ,"farming:barley",},
		view_range = 5,
		owner = "",
		order = "follow",

		on_rightclick = function(self, clicker)
			if mobs:feed_tame(self, clicker, 8, true, true) then
				return
			end

			local tool = clicker:get_wielded_item()
			local name = clicker:get_player_name()
			local pos = self.object:getpos()
			local mname = self.textures[1]
			mobs:capture_mob(self, clicker, 0, 5, 60, false, nil)

			if self.owner
			and self.owner == clicker:get_player_name()
			and tool:get_name() == "kpgmobs:saddle"
			and not self.child then
				if (mname == "mobs_horse.png") then
					minetest.add_entity(pos, "kpgmobs:horseh1")
				elseif (mname == "mobs_horsepeg.png") then
					minetest.add_entity(pos, "kpgmobs:horsepegh1")
				elseif (mname == "mobs_horseara.png") then
					minetest.add_entity(pos, "kpgmobs:horsearah1")
				end
				self.object:remove()
			    clicker:get_inventory():remove_item("main", "kpgmobs:saddle")
				minetest.chat_send_player(name, "Horse is ready to ride.")
				return
	        end

			if self.owner
			and self.owner == name
			and not self.child then
				if tool:get_name() == "mobs:magic_lasso" then
					return
				end
				if self.order == "follow" then
					self.order = "stand"
					minetest.chat_send_player(name, "Horse stands still.")
				else
					self.order = "follow"
					minetest.chat_send_player(name, "Horse will follow you.")
				end
			end
		end,
	})
	mobs:register_egg("kpgmobs:horse_" .. colors .. "_tamed", colors:gsub("^%l", string.upper) .. " Horse", InvSub, 0)
end
