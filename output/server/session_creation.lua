function server_class:create_incoming_sessions()
	local msgs = self.entity_system_instance.messages["BEGIN_SESSION"]
	
	for i=1, #msgs do
		local msg = msgs[i]
		local new_guid = msg.guid
	
		local world_character = world_archetypes.create_player(self.current_map, self.current_map.teleport_shuffler:next_value().pos)
		
		local public_character_modules = create_replica { "movement", "crosshair", "health", "label" }
		local owner_character_modules = create_replica { "movement", "health", "label" }
		
		local inventory_modules = create_replica { "item" }
		
		local new_client = components.create_components {
			client = {
				guid = new_guid,
				nickname = msg.data.nickname
			}
		}
	
		local new_controlled_character = components.create_components {
			client_controller = {
				owner_client = new_client
			},
			
			cpp_entity = world_character,
			
			replication = {
				module_sets = {
					PUBLIC = {
						replica = public_character_modules,
						archetype_name = "REMOTE_PLAYER"
					},
						
					OWNER = {
						replica = owner_character_modules,
						archetype_name = "CONTROLLED_PLAYER"
					}
				}
			},
			
			health = {
				hp = 100
			},
			
			label = {
				label_str = msg.data.nickname
			},
			
			orientation = {},
			
			wield = {}
		}
		
		local new_character_inventory = components.create_components {
			replication = {
				module_sets = {
					OWNER = {
						replica = inventory_modules,
						archetype_name = "INVENTORY" 
					}
				}
			},
			
			inventory = {},
			
			item = {},
			
			wield = {}
		}
		
		self.entity_system_instance:add_entity(new_client)
		self.entity_system_instance:add_entity(new_controlled_character)
		world_archetypes.spawn_gun(self, "m4a1", world_character.transform.current.pos)
		world_archetypes.spawn_gun(self, "shotgun", world_character.transform.current.pos)
		self.entity_system_instance:add_entity(new_character_inventory)
		
		new_client.client.controlled_object = new_controlled_character
		
		self.entity_system_instance:post_table("item_wielder_change", { 
			wield = true,
			subject = new_controlled_character,
			item = new_character_inventory,
			wielding_key = components.wield.keys.INVENTORY
		})
		
		--self.entity_system_instance:post_table("pick_item", { 
		--	subject = new_controlled_character,
		--	item = new_gun
		--})			
		
		new_client.client.group_by_id[new_controlled_character.replication.id] = "OWNER"
		
		new_controlled_character.wield.on_item_unwielded = function (subject, dropped_item)
			if dropped_item.cpp_entity.physics == nil then return end
			
			local body = dropped_item.cpp_entity.physics.body
			local force = (subject.orientation.crosshair_position):normalize() * 100
			
			if subject.orientation.crosshair_position:length() < 0.01 then
				force = vec2(100, 0)
			end
			
			body:ApplyLinearImpulse(to_meters(force), body:GetWorldCenter(), true)
			body:ApplyAngularImpulse(4, true)
		end
		
		new_controlled_character.health.on_death = function(this)
			--self.entity_system_instance:post_remove(this)
			this.replication:broadcast_reliable(protocol.write_msg("DAMAGE_MESSAGE", {
						victim_id = this.replication.id,
						amount = this.health.hp - 100
					}))
			this.health.hp = 100
					
			this.cpp_entity.physics.body:SetTransform(to_meters(self.current_map.teleport_shuffler:next_value().pos), 0)
		end
		
		self.user_map:add(new_guid, new_client)
		
		print "New client connected."
	end
end