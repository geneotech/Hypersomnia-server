npc_system = inherits_from (processing_system)

function npc_system:add_entity(new_entity)
	new_entity.npc.owner = new_entity
	new_entity.npc.entity = new_entity.cpp_entity
	processing_system.add_entity(self, new_entity)
end

function npc_system:get_required_components()
	return { "npc" }
end

function npc_system:loop()
	for i=1, #self.targets do	
		local target = self.targets[i]
		local npc = target.npc
		
		local entity = target.cpp_entity
		local behaviours = npc.steering_behaviours
		local target_entities = npc.target_entities
	
		local body = entity.physics.body
		local myvel = body:GetLinearVelocity()
		
		
		-- general steering towards a predefined target
		
		--target_entities.forward.transform.current.pos = entity.transform.current.pos + vec2(myvel.x, myvel.y) * 50
		
		if entity.pathfinding and (entity.pathfinding:is_still_pathfinding() or entity.pathfinding:is_still_exploring()) then
			target_entities.navigation.transform.current.pos = entity.pathfinding:get_current_navigation_target()
			
			behaviours.sensor_avoidance.enabled = true
			behaviours.obstacle_avoidance.enabled = true
			if behaviours.sensor_avoidance.last_output_force:non_zero() then
				behaviours.target_seeking.enabled = false
				behaviours.forward_seeking.enabled = true
				behaviours.obstacle_avoidance.enabled = true
			else
				behaviours.target_seeking.enabled = true
				behaviours.forward_seeking.enabled = false
				--behaviours.obstacle_avoidance.enabled = false
			end
		else
			behaviours.target_seeking.enabled = false
			behaviours.forward_seeking.enabled = false
			
		end
		
			behaviours.obstacle_avoidance.enabled = false
			--behaviours.sensor_avoidance.enabled = false
		behaviours.sensor_avoidance.max_intervention_length = (entity.transform.current.pos - target_entities.navigation.transform.current.pos):length() --- 70
		
		--	behaviours.sensor_avoidance.enabled = true
		--	player_behaviours.obstacle_avoidance.enabled = true
		--player_behaviours.forward_seeking.enabled = true
		
		local pos = entity.transform.current.pos
		local radius = entity.visibility:get_layer(visibility_component.DYNAMIC_PATHFINDING).square_side
		local half_diag = radius/2
		local physics = self.world_object.physics_system
		local targets_in_proximity = physics:query_aabb(pos - vec2(half_diag, half_diag), pos + vec2(half_diag, half_diag), create_query_filter({"CHARACTER", "DROPPED_ITEM"}), entity)
		
		--clearlc(2)
		--debuglc(2, rgba(0, 255, 255, 255),pos - vec2(half_diag, half_diag), pos + vec2(half_diag, half_diag) )
		
		npc.seen_enemies = {}
		npc.seen_items = {}
		
		for candidate in targets_in_proximity.bodies do
			local script = body_to_entity(candidate).script
			
			-- if it's visible
			
			if script and ((target.pos - script.pos):length() < 2 or not physics:ray_cast(target.pos, script.pos, create_query_filter({"STATIC_OBJECT"}), target.cpp_entity).hit) then
				if script.client_controller then
					print "adding!"
					npc.seen_enemies[#npc.seen_enemies + 1] = script
				elseif script.item then
					npc.seen_items[#npc.seen_items + 1] = script
				end	
			end
		end
		
		npc:closest_visible_enemy(table.best(npc.seen_enemies, function(a, b) return (a.pos - target.pos):length_sq() < (b.pos - target.pos):length_sq() end))
		npc:update_escape()
		--body:ApplyForce(to_meters(behaviours.target_seeking.last_output_force:set_length(100)), body:GetWorldCenter(), true)
		--body:ApplyForce(to_meters(behaviours.wandering.last_output_force*0), body:GetWorldCenter(), true)
		--behaviours.wandering.enabled = false
		
	end
end

