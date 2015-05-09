world_archetypes.spawn_gun = function(owner_server, gun_name, pos)
	local owner_gun_modules = create_replica { "gun_init_info", "item" }
	local public_owned_gun_modules = create_replica { "item" }
	local public_dropped_gun_modules = create_replica { "item", "movement_rotated" }
	
	local new_gun = components.create_components {
		replication = {
			module_sets = {
				DROPPED_PUBLIC = {
					replica = public_dropped_gun_modules,
					archetype_name = gun_name
				},
				
				PUBLIC = {
					replica = public_owned_gun_modules,
					archetype_name = gun_name
				},
					
				OWNER = {
					replica = owner_gun_modules,
					archetype_name = gun_name
				}
			},
			
			upload_rate = 1,
			
			public_group_name = "DROPPED_PUBLIC"
		},
		
		weapon = owner_server.current_map.weapons[gun_name].weapon_info,
		item = owner_server.current_map.weapons[gun_name].item_info
	}

	new_gun.weapon.current_rounds = owner_server.current_map.weapons[gun_name].weapon_info.current_rounds
	
	new_gun.weapon:create_smoke_group(owner_server.current_map.world_object.world)
	owner_server.entity_system_instance:add_entity(new_gun)
	
	new_gun.cpp_entity.physics.body:SetTransform(to_meters(pos), 0.0)
	
	return new_gun
end