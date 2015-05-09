flee_steering = create_steering {
	behaviour_type = flee_behaviour,
	weight = 3,
	radius_of_effect = 700,
	force_color = rgba(255, 0, 0, 120)
}
		
seek_archetype = {
	behaviour_type = seek_behaviour,
	weight = 1,
	force_color = rgba(255, 255, 255, 255)
}			

target_seek_steering = create_steering (override(seek_archetype, {
	radius_of_effect = 150
}))

forward_seek_steering = create_steering (override(seek_archetype, {
	radius_of_effect = 0
}))

containment_archetype = {
	behaviour_type = containment_behaviour,
	weight = 3, 
	
	ray_filter = filters.AVOIDANCE,
	
	ray_count = 5,
	randomize_rays = true,
	only_threats_in_OBB = false,
	
	force_color = rgba(0, 255, 255, 0),
	intervention_time_ms = 200,
	avoidance_rectangle_width = 10
}

containment_steering = create_steering (containment_archetype) 

obstacle_avoidance_archetype = {
	weight = 1, 
	behaviour_type = obstacle_avoidance_behaviour,
	visibility_type = visibility_component.DYNAMIC_PATHFINDING,
	
	force_color = rgba(255, 255, 0, 255),
	intervention_time_ms = 800,
	avoidance_rectangle_width = 2,
	ignore_discontinuities_narrower_than = 1
}

wander_steering = create_steering {
	weight = 1, 
	behaviour_type = wander_behaviour,
	
	circle_radius = 200,
	circle_distance = 1540,
	displacement_degrees = 15,
	
	force_color = rgba(0, 255, 255, 0)
}

strafing_steering = create_steering {
	weight = 1, 
	behaviour_type = wander_behaviour,
	
	circle_radius = 200,
	circle_distance = 100,
	displacement_degrees = 85,
	
	force_color = rgba(0, 255, 255, 0)
}

obstacle_avoidance_steering = create_steering (override(obstacle_avoidance_archetype, {
	navigation_seek = target_seek_steering,
	navigation_correction = containment_steering
}))

sensor_avoidance_steering = create_steering (override(containment_archetype, {
	weight = 0,
	intervention_time_ms = 200,
	force_color = rgba(0, 0, 255, 0),
	avoidance_rectangle_width = 0
}))

pursuit_steering = create_steering {
	behaviour_type = seek_behaviour,
	weight = 1,
	radius_of_effect = 20,
	force_color = rgba(255, 0, 255, 255),
	
	max_target_future_prediction_ms = 400
}


components.npc = inherits_from()

function components.npc:constructor(init_table)
	rewrite(self, init_table)
	
	self.steering_behaviours = {
		target_seeking = behaviour_state(target_seek_steering),
		forward_seeking = behaviour_state(forward_seek_steering),
		
		sensor_avoidance = behaviour_state(sensor_avoidance_steering),
		wandering = behaviour_state(wander_steering),
		obstacle_avoidance = behaviour_state(containment_steering),
		pursuit = behaviour_state(pursuit_steering),
		
		strafing = behaviour_state(strafing_steering),
		
		evasion = behaviour_state(flee_steering)
	}
	
	self.target_entities = {
		navigation = init_table.owner_world:create_entity({ transform = {} }),
		forward = init_table.owner_world:create_entity({ transform = {} }),
		last_seen = init_table.owner_world:create_entity({ transform = {} })
	}
	
	
	-- we have up to only one fighting target
	-- we pick the closest one to us
	self.was_seen = false
	self.is_seen = false
	self.last_seen_velocity = vec2(0, 0)
		
	self.alertness_time = 10000
	
	local behaviours = self.steering_behaviours
	
	behaviours.forward_seeking.target_from:set(self.target_entities.forward)
	behaviours.target_seeking.target_from:set(self.target_entities.navigation)
	behaviours.sensor_avoidance.target_from:set(self.target_entities.navigation)
	
	self.last_seen_timer = timer()
end

function components.npc:reset_steering()
	local behaviours = self.steering_behaviours
	
	behaviours.pursuit.enabled = false
	behaviours.evasion.enabled = false
	
	behaviours.wandering.enabled = false
	behaviours.strafing.enabled = false
	
	behaviours.target_seeking.enabled = false
	behaviours.forward_seeking.enabled = false
	
	behaviours.sensor_avoidance.enabled = false
	behaviours.obstacle_avoidance.enabled = false
	behaviours.wandering.weight_multiplier = 1
	
	self.entity.pathfinding.favor_velocity_parallellness = false
	self.entity.pathfinding.custom_exploration_hint.enabled = false
	self.entity.pathfinding:clear_pathfinding_info()
--print(debug.traceback())
end

function components.npc:update_avoidance(navigating_behaviour, use_sensor)
	if not navigating_behaviour then navigating_behaviour = "target_seeking" end
	if use_sensor == nil then use_sensor = true end
	
	local entity = self.entity
	local behaviours = self.steering_behaviours
	local target_entities = self.target_entities
	
	local body = entity.physics.body
	local myvel = to_pixels(body:GetLinearVelocity())
	if myvel:length() <= 0 then myvel = vec2(10, 0) end
		
	behaviours.sensor_avoidance.enabled = use_sensor
	behaviours.obstacle_avoidance.enabled = true
	
	if use_sensor then
		behaviours.sensor_avoidance.max_intervention_length = (entity.transform.current.pos - target_entities.navigation.transform.current.pos):length() --- 70
		target_entities.forward.transform.current.pos = self.owner.pos + to_pixels(myvel)
		
		if behaviours.sensor_avoidance.last_output_force:non_zero() then
			behaviours[navigating_behaviour].enabled = false
			behaviours.forward_seeking.enabled = true
		else
			behaviours[navigating_behaviour].enabled = true
			behaviours.forward_seeking.enabled = false
			--behaviours.obstacle_avoidance.enabled = false
		end
	else
		behaviours[navigating_behaviour].enabled = not behaviours.obstacle_avoidance.last_output_force:non_zero()
	end
end

function components.npc:exit_avoidance()
	self:reset_steering()
end

function components.npc:update_pathfinding()
	local entity = self.entity
		
	if entity.pathfinding and (entity.pathfinding:is_still_pathfinding() or entity.pathfinding:is_still_exploring()) then
		self.target_entities.navigation.transform.current.pos = entity.pathfinding:get_current_navigation_target()
		self.steering_behaviours.wandering.enabled = true
		self:update_avoidance()
	end
end

function components.npc:exit_pathfinding()
	self:reset_steering()
	self:exit_avoidance()
end

function components.npc:start_patrol()
	print "started patrol"
	self.steering_behaviours.wandering.enabled = true
	self.entity.pathfinding.favor_velocity_parallellness = true
	self.entity.pathfinding:start_exploring()
end

function components.npc:update_patrol()
	self:update_pathfinding()
end

function components.npc:exit_patrol()
	self:reset_steering()
end



function components.npc:start_escape()
	self.steering_behaviours.wandering.enabled = true
	self.entity.pathfinding.favor_velocity_parallellness = true
	self.entity.pathfinding.custom_exploration_hint.enabled = true
	self.entity.pathfinding:start_exploring()
end

function components.npc:update_escape()
	if self.last_seen then
		self.entity.pathfinding.custom_exploration_hint.origin = self.owner.pos
		self.entity.pathfinding.custom_exploration_hint.target = self.owner.pos + (self.owner.pos - self.last_seen)
		
		self.steering_behaviours.evasion.enabled = self.is_seen
		
		if self.is_seen then
			self.steering_behaviours.evasion.target_from:set(self.closest_enemy.cpp_entity)
		end
		
		self:update_pathfinding()
	end
end

function components.npc:stop_escape()
	self:reset_steering()
end

function components.npc:pursue_target(target_entity)
	self.target_entities.navigation.transform.current.pos = target_entity.pos
	self.steering_behaviours.pursuit.target_from:set(target_entity.cpp_entity)
	self.steering_behaviours.pursuit.enabled = true
end

function components.npc:stop_pursuit()
	self:reset_steering()
end

function components.npc:all_possessed_items()
	local wielded = self.owner.wield.wielded_items
	local primary = wielded[components.wield.keys.PRIMARY_WEAPON]
	local all = {}
	
	rewrite(all, wielded[components.wield.keys.INVENTORY].wield.wielded_items)
	
	if primary then
		all[primary.replication.id] = primary
	end
	
	return all
end

function components.npc:find_best_weapon()
	return table.best(self:all_possessed_items(), function(a, b) 
		if not a.weapon then 
			return false
		end
		
		return a.weapon.current_rounds > b.weapon.current_rounds 
	end, "pairs")
end

function components.npc:get_closest_needed_item()
	local candidate_weapons = {}
	
	for i=1, #self.seen_items do
		-- later we will only look for ammunition as the npcs will have their own weapons
		
		-- for now just pick any weapon with current_rounds > 0 because our capacity does not yet play any role
		if self.seen_items[i].weapon and self.seen_items[i].weapon.current_rounds > 0 then
			candidate_weapons[#candidate_weapons + 1] = self.seen_items[i]
		end
	end
	
	return table.best(candidate_weapons, closest_to(self.owner.pos))
end

function components.npc:get_selected_item()
	return self.owner.wield.wielded_items[components.wield.keys.PRIMARY_WEAPON]
end

function components.npc:holster_item()
	self.owner.owner_entity_system:post_table("holster_item", { 
		subject = self.owner
	})
end

function components.npc:select_item(item)
	self.owner.owner_entity_system:post_table("select_item", { 
		subject = self.owner,
		item_id = item.replication.id
	})
end

function components.npc:pick(picked_item)
	self.owner.owner_entity_system:post_table("pick_item", {
		subject = self.owner,
		item = picked_item
	})
end
						
function components.npc:closest_visible_enemy(new_target)
	if new_target then
		self.was_seen = true
		self.is_seen = true
		
		self.last_seen_vel = new_target.vel
		self.last_seen = vec2(new_target.pos)
		self.last_seen_timer:reset()
		
		if self.closest_enemy ~= new_target then
			self.closest_enemy = new_target
		end
	else
		self.is_seen = false
	end
end

function components.npc:fade_alertness()
	if self.was_seen and self.last_seen_timer:get_milliseconds() > self.alertness_time then
		self.was_seen = false
		
		return true
	else
		return false
	end
end

function components.npc:refresh_behaviours()
	local this = self.owner
	local entity = this.cpp_entity
	
	entity.steering:clear_behaviours()
	
	for k, v in pairs(this.npc.steering_behaviours) do
		entity.steering:add_behaviour(v)
	end
	
	self:reset_steering()
end

