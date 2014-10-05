dofile "server\\world_archetypes\\soldier_tree.lua"

world_archetypes.spawn_soldier = function(owner_server, pos)
	local public_soldier_modules = create_replica { "movement", "orientation", "health" }
		
	local soldier_entity = owner_server.current_map.world_object:create_entity  {
		render = {
			layer = render_layers.PLAYERS,
			model = owner_server.current_map.blank_sprite
		},
		
		transform = {
			pos = position
		},
		
		physics = {
			body_type = Box2D.b2_dynamicBody,
			
			body_info = {
				filter = filters.CHARACTER,
				shape_type = physics_info.RECT,
				rect_size = vec2(37, 37),
				
				angular_damping = 5,
				--linear_damping = 18,
				--max_speed = 3300,
				
				fixed_rotation = true,
				density = 0.1,
				angled_damping = true
			},
		},
	
		lookat = {
			easing_mode = lookat_component.EXPONENTIAL,
			smoothing_average_factor = 0.5,
			averages_per_sec = 80
		},
			
		movement = {
			input_acceleration = vec2(10000, 10000),
			max_accel_len = 10000,
			air_resistance = 0.2,
			braking_damping = 18
		},
		
		steering = {
			apply_force = true,
			max_speed = 24000,
			max_resultant_force = 24000
		},
		
		visibility = {
			visibility_layers = {
				[visibility_component.DYNAMIC_PATHFINDING] = {
					square_side = 5000,
					color = rgba(0, 255, 255, 120),
					filter = filters.AVOIDANCE
				}
			}
		},
	
		pathfinding = {
			mark_touched_as_discovered = true,
			force_persistent_navpoints = true,
			enable_backtracking = true,
			target_offset = 100,
			rotate_navpoints = 10,
			distance_navpoint_hit = 2,
			favor_velocity_parallellness = true
		},
		
		behaviour_tree = {
			trees = {
				npc_legs_behaviour_tree.legs,
				npc_hands_behaviour_tree.hands
			}
		}
	}

	--soldier_entity.pathfinding:start_exploring()
	
	local new_soldier = components.create_components {
		cpp_entity = soldier_entity,
		
		replication = {
			module_sets = {
				PUBLIC = {
					replica = public_soldier_modules,
					archetype_name = "SOLDIER"
				}
			},
			
			upload_rate = 60
		},
		
		health = {
			hp = 100
		},
		
		orientation = {},
		
		wield = {},
		
		npc = {
			owner_world = owner_server.current_map.world_object
		}
	}
	
	local new_character_inventory = components.create_components {		
		inventory = {},
		
		item = {},
		
		wield = {}
	}
	
	owner_server.entity_system_instance:add_entity(new_soldier)
	owner_server.entity_system_instance:add_entity(new_character_inventory)
	
	new_soldier.npc:refresh_behaviours()
	
	new_soldier.wield.on_item_unwielded = function (subject, dropped_item)
		if dropped_item.cpp_entity.physics == nil then return end
		
		local body = dropped_item.cpp_entity.physics.body
		local force = (subject.orientation.crosshair_position):normalize() * 100
		
		if subject.orientation.crosshair_position:length() < 0.01 then
			force = vec2(100, 0)
		end
		
		body:ApplyLinearImpulse(to_meters(force), body:GetWorldCenter(), true)
		body:ApplyAngularImpulse(4, true)
	end
	
	new_soldier.health.on_death = function(this)
		--self.entity_system_instance:post_remove(this)
		this.replication:broadcast_reliable(protocol.write_msg("DAMAGE_MESSAGE", {
					victim_id = this.replication.id,
					amount = this.health.hp - 100
				}))
		this.health.hp = 100
				
		this.cpp_entity.physics.body:SetTransform(to_meters(owner_server.current_map.teleport_shuffler:next_value().pos), 0)
	end
		
	owner_server.entity_system_instance:post_table("item_wielder_change", { 
		wield = true,
		subject = new_soldier,
		item = new_character_inventory,
		wielding_key = components.wield.keys.INVENTORY
	})

	--local soldiers_gun = world_archetypes.spawn_gun(owner_server, "m4a1", vec2(0, 0))
	--
	--owner_server.entity_system_instance:post_table("pick_item", { 
	--	subject = new_soldier,
	--	item = soldiers_gun
	--})
	--
	--owner_server.entity_system_instance:post_table("select_item", { 
	--	subject = new_soldier,
	--	item_id = soldiers_gun.replication.id
	--})
	
	
	return new_soldier
end