flee_steering = create_steering {
	behaviour_type = flee_behaviour,
	weight = 1,
	radius_of_effect = 500,
	force_color = rgba(255, 0, 0, 0)
}
		
seek_archetype = {
	behaviour_type = seek_behaviour,
	weight = 1,
	force_color = rgba(0, 255, 255, 255)
}			

target_seek_steering = create_steering (override(seek_archetype, {
	radius_of_effect = 150
}))

forward_seek_steering = create_steering (override(seek_archetype, {
	radius_of_effect = 0
}))

containment_archetype = {
	behaviour_type = containment_behaviour,
	weight = 1, 
	
	ray_filter = filters.AVOIDANCE,
	
	ray_count = 5,
	randomize_rays = true,
	only_threats_in_OBB = false,
	
	force_color = rgba(0, 255, 255, 0),
	intervention_time_ms = 240,
	avoidance_rectangle_width = 0
}

containment_steering = create_steering (containment_archetype) 

obstacle_avoidance_archetype = {
	weight = 1, 
	behaviour_type = obstacle_avoidance_behaviour,
	visibility_type = visibility_component.DYNAMIC_PATHFINDING,
	
	force_color = rgba(255, 255, 255, 255),
	intervention_time_ms = 100,
	avoidance_rectangle_width = 0,
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
	force_color = rgba(255, 255, 255, 255),
	
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
		obstacle_avoidance = behaviour_state(obstacle_avoidance_steering),
		pursuit = behaviour_state(pursuit_steering)
	}
	
	self.target_entities = {
		navigation = init_table.owner_world:create_entity({ transform = {} }),
		forward = init_table.owner_world:create_entity({ transform = {} }),
		last_seen = init_table.owner_world:create_entity({ transform = {} })
	}
	
	
	-- we always have only one fighting target
	-- we pick the closest one to us
	self.was_seen = false
	self.is_seen = false
	self.is_alert = false
	self.last_seen_velocity = vec2(0, 0)
		
	self.steering_behaviours.forward_seeking.target_from:set(self.target_entities.forward)
	self.steering_behaviours.target_seeking.target_from:set(self.target_entities.navigation)
	self.steering_behaviours.sensor_avoidance.target_from:set(self.target_entities.navigation)
	
	self.steering_behaviours.pursuit.enabled = false
end

function components.npc:start_patrol()
	self.entity.pathfinding.enable_backtracking = true
	self.entity.pathfinding.favor_velocity_parallellness = true
	self.entity.pathfinding.custom_exploration_hint.enabled = false
	self.entity.pathfinding:start_exploring()
end

function components.npc:update_escape()
	if self.last_seen then
		self.entity.pathfinding.custom_exploration_hint.origin = self.owner.pos
		self.entity.pathfinding.custom_exploration_hint.target = self.owner.pos + (self.owner.pos - self.last_seen)
	end
end

function components.npc:escape_from(attacker_pos)
	self.attacker_pos = attacker_pos
	self.entity.pathfinding.enable_backtracking = true
	self.entity.pathfinding.favor_velocity_parallellness = true
	self.entity.pathfinding.custom_exploration_hint.enabled = true
	self.entity.pathfinding:start_exploring()
end

function components.npc:stop_escape()
	self.entity.pathfinding.custom_exploration_hint.enabled = false
	self.entity.pathfinding:clear_pathfinding_info()
end

function components.npc:pursue_target(target_entity)
	self.pursued_target = target_entity
	self.steering_behaviours.pursuit.target_from:set(target_entity)
	self.steering_behaviours.pursuit.enabled = true
	self.steering_behaviours.obstacle_avoidance.enabled = false
	self.steering_behaviours.sensor_avoidance.target_from:set(target_entity)
end


function components.npc:update_pursuit()

end

function components.npc:stop_pursuit()
	self.pursued_target = nil
	self.steering_behaviours.pursuit.enabled = false
	self.steering_behaviours.obstacle_avoidance.enabled = true
	self.steering_behaviours.sensor_avoidance.target_from:set(self.target_entities.navigation)
end

function components.npc:closest_visible_enemy(new_target)
	if new_target then
		if not self.is_seen or self.closest_enemy ~= new_target then
			self:escape_from(new_target.pos)
			print "ESCAPE!!"
		end
		
		self.was_seen = true
		self.is_seen = true
		self.is_alert = true
		
		self.last_seen = vec2(new_target.pos)
		
		if self.closest_enemy ~= new_target then
			self.closest_enemy = new_target
		end
	else
		self.is_seen = false
	end
end

function components.npc:refresh_behaviours()
	local this = self.owner
	local entity = this.cpp_entity
	
	entity.steering:clear_behaviours()
	
	for k, v in pairs(this.npc.steering_behaviours) do
		entity.steering:add_behaviour(v)
	end
end

