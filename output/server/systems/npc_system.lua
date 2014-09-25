
npc_system = inherits_from (processing_system)

--function npc_system:constructor()
--	processing_system.constructor(self)
--end

function npc_system:get_required_components()
	return { "npc" }
end

function npc_system:loop()
	for i=1, #self.targets do	
		local npc = self.targets[i].npc
		
		local entity = self.targets[i].cpp_entity
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
		
		--components.npc.escape_from(self.targets[i], vec2(0, 0))
			--behaviours.obstacle_avoidance.enabled = false
			--behaviours.sensor_avoidance.enabled = false
		behaviours.sensor_avoidance.max_intervention_length = (entity.transform.current.pos - target_entities.navigation.transform.current.pos):length() --- 70
		
		--	behaviours.sensor_avoidance.enabled = true
		--	player_behaviours.obstacle_avoidance.enabled = true
		--player_behaviours.forward_seeking.enabled = true
		
		body:SetLinearVelocity(to_meters(vec2(0, 0)))
		--body:ApplyForce(to_meters(behaviours.target_seeking.last_output_force:set_length(100)), body:GetWorldCenter(), true)
		--body:ApplyForce(to_meters(behaviours.wandering.last_output_force*0), body:GetWorldCenter(), true)
		--behaviours.wandering.enabled = false
		
	end
end

