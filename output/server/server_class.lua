dofile (CLIENT_CODE_DIRECTORY .. "scripts\\protocol.lua")

dofile (CLIENT_CODE_DIRECTORY .. "scripts\\archetypes\\archetype_library.lua")
dofile "server\\world_archetypes\\world_archetypes.lua"

dofile "server\\components\\client.lua"
dofile "server\\components\\replication.lua"
dofile "server\\components\\client_controller.lua"
dofile "server\\components\\orientation.lua"

dofile (CLIENT_CODE_DIRECTORY .. "scripts\\game\\weapons.lua")

dofile (CLIENT_CODE_DIRECTORY .. "scripts\\sync_modules\\modules.lua")
dofile (CLIENT_CODE_DIRECTORY .. "scripts\\sync_modules\\movement_sync.lua")
dofile (CLIENT_CODE_DIRECTORY .. "scripts\\sync_modules\\crosshair_sync.lua")
dofile (CLIENT_CODE_DIRECTORY .. "scripts\\sync_modules\\client_info_sync.lua")
dofile (CLIENT_CODE_DIRECTORY .. "scripts\\sync_modules\\health_sync.lua")
dofile (CLIENT_CODE_DIRECTORY .. "scripts\\sync_modules\\item_sync.lua")
dofile (CLIENT_CODE_DIRECTORY .. "scripts\\sync_modules\\gun_sync.lua")

dofile (CLIENT_CODE_DIRECTORY .. "scripts\\components\\weapon.lua")
dofile (CLIENT_CODE_DIRECTORY .. "scripts\\components\\health.lua")
dofile (CLIENT_CODE_DIRECTORY .. "scripts\\components\\wield.lua")
dofile (CLIENT_CODE_DIRECTORY .. "scripts\\components\\item.lua")
dofile (CLIENT_CODE_DIRECTORY .. "scripts\\components\\inventory.lua")

dofile (CLIENT_CODE_DIRECTORY .. "scripts\\systems\\protocol_system.lua")
dofile (CLIENT_CODE_DIRECTORY .. "scripts\\systems\\weapon_system.lua")
dofile (CLIENT_CODE_DIRECTORY .. "scripts\\systems\\wield_system.lua")

dofile (CLIENT_CODE_DIRECTORY .. "scripts\\systems\\item_system.lua")

dofile "server\\systems\\inventory_system.lua"
dofile (CLIENT_CODE_DIRECTORY .. "scripts\\systems\\inventory_system_shared.lua")

dofile "server\\systems\\wield_system.lua"

dofile "server\\systems\\client_controller_system.lua"
dofile "server\\systems\\client_system.lua"
dofile "server\\systems\\replication_system.lua"
dofile "server\\systems\\orientation_system.lua"
dofile "server\\systems\\bullet_broadcast_system.lua"

server_class = inherits_from()

function server_class:constructor()
	self.server = network_interface()
	
	self.server:occasional_ping(true)
	self.server:set_timeout_all(7000)
	
	self.received = network_packet()
	self.user_map = guid_to_object_map()

	self.entity_system_instance = entity_system:create(function () self.current_map.world_object:call_deletes() end)
	
	self.entity_system_instance:register_messages {
		"network_message",
		"shot_message",
		"item_wielder_change",
		
		"pick_item",
		"drop_item"
	}
	
	self.entity_system_instance:register_messages (protocol.message_names)
	
	self.entity_system_instance:register_message_group ("INVENTORY_REQUESTS", {
		"PICK_ITEM_REQUEST",
		"SELECT_ITEM_REQUEST",
		"HOLSTER_ITEM",
		"DROP_ITEM_REQUEST"
	})
	
	-- create all necessary systems
	self.systems = {}
	self.systems.replication = replication_system:create()
	self.systems.client = client_system:create(self.server)
	self.systems.client_controller = client_controller_system:create()
	self.systems.protocol = protocol_system:create(function (msg) end, function (in_bs) end )
	self.systems.orientation = orientation_system:create()
	self.systems.weapon = weapon_system:create(nil, nil)
	self.systems.bullet_broadcast = bullet_broadcast_system:create()
	self.systems.wield = wield_system:create()
	self.systems.item = item_system:create()
	self.systems.inventory = inventory_system:create()
	
	self.entity_system_instance:register_systems(self.systems)
	
	self.entity_system_instance:register_callbacks {
		item_wielder_change = function(msg) 
			self.systems.wield:handle_wielder_change(msg)
			self.systems.wield:broadcast_changes(msg)
		end
	}
	
	
	self.global_timer = timer()
	
	set_rate(self, "update", 60)
end

function server_class:start(port, max_players, max_connections)
	self.server:listen(port, max_players, max_connections)
	
	if config_table.simulate_lag ~= 0 then
		print "Simulating lag..."
		self.server:enable_lag(config_table.packet_loss, config_table.min_latency, config_table.jitter)
	end
end

function server_class:set_current_map(map_filename, loader_filename)
	self.current_map = scene_class:create()
	self.current_map:load_map(map_filename, loader_filename)
	
	self.current_map.blank_sprite = create_sprite {
		image = self.current_map.sprite_library["blank"],
		color = rgba(0, 255, 0, 255),
		size = vec2(37, 37)
	}
	
	self.systems.weapon.physics = self.current_map.world_object.physics_system
	self.systems.item.world_object = self.current_map.world_object
	
	create_weapons(self.current_map, false)
	
	table.insert(self.current_map.world_object.prestep_callbacks, function()
		self.systems.client:substep()
		self.systems.client_controller:substep()
	end)
end

function server_class:new_client(new_guid)
	local world_character = world_archetypes.create_player(self.current_map, self.current_map.teleport_shuffler:next_value().pos)
	
	local public_character_modules = create_replica { "movement", "crosshair", "health" }
	local owner_character_modules = create_replica { "movement", "health" }
	
	local owner_gun_modules = create_replica { "gun_init_info", "item" }
	local public_owned_gun_modules = create_replica { "item" }
	local public_dropped_gun_modules = create_replica { "item", "movement_rotated" }
	
	local owner_shotgun_modules = create_replica { "gun_init_info", "item" }
	local public_owned_shotgun_modules = create_replica { "item" }
	local public_dropped_shotgun_modules = create_replica { "item", "movement_rotated" }
	
	local inventory_modules = create_replica { "item" }
	
	--local client_modules = {}
	--client_modules["client_info"] = replication_module:create(protocol.replication_tables.client_info)
	
	local new_client = components.create_components {
		client = {
			guid = new_guid
		}
		
		--client_info = {},
		--
		--replication = {
		--	module_sets = {
		--		PUBLIC = {
		--			replica = client_modules,
		--			archetype_name = "CLIENT_INFO"
		--		}
		--	}
		--}
	}
	
	local new_gun = components.create_components {
		replication = {
			module_sets = {
				DROPPED_PUBLIC = {
					replica = public_dropped_gun_modules,
					archetype_name = "m4a1"
				},
				
				PUBLIC = {
					replica = public_owned_gun_modules,
					archetype_name = "m4a1"
				},
					
				OWNER = {
					replica = owner_gun_modules,
					archetype_name = "m4a1"
				}
			},
			
			upload_rate = 1,
			
			public_group_name = "DROPPED_PUBLIC"
		},
		
		weapon = self.current_map.weapons.m4a1.weapon_info,
		item = self.current_map.weapons.m4a1.item_info
	}
	
	local new_shotgun = components.create_components {
		replication = {
			module_sets = {
				DROPPED_PUBLIC = {
					replica = public_dropped_shotgun_modules,
					archetype_name = "shotgun"
				},
				
				PUBLIC = {
					replica = public_owned_shotgun_modules,
					archetype_name = "shotgun"
				},
					
				OWNER = {
					replica = owner_shotgun_modules,
					archetype_name = "shotgun"
				}
			},
			
			upload_rate = 1,
			
			public_group_name = "DROPPED_PUBLIC"
		},
		
		weapon = self.current_map.weapons.shotgun.weapon_info,
		item = self.current_map.weapons.shotgun.item_info
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
	self.entity_system_instance:add_entity(new_gun)
	self.entity_system_instance:add_entity(new_shotgun)
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
	
	new_gun.cpp_entity.physics.body:SetTransform(to_meters(world_character.transform.current.pos), 0.1)
	new_shotgun.cpp_entity.physics.body:SetTransform(to_meters(world_character.transform.current.pos), 0.1)
	
	new_gun.weapon.current_rounds = 30
	new_shotgun.weapon.current_rounds = 6
	
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

function server_class:remove_client(guid)	
	local client = self.user_map:at(guid)
	
	if client.client.controlled_object ~= nil then
		self.entity_system_instance:remove_entity(client.client.controlled_object)
	end
	
	self.entity_system_instance:remove_entity(client)
	
	self.user_map:remove(guid)
	
	print "A client has disconnected or lost the connection."
end

function server_class:loop()
	--print(self.global_timer:extract_milliseconds())

	local packet = self.received
	
	if self.server:receive(packet) then
		local message_type = packet:byte(0)
		local guid = packet:guid()
		
		if message_type == network_event.ID_NEW_INCOMING_CONNECTION then
			self:new_client(guid)
		elseif message_type == network_event.ID_DISCONNECTION_NOTIFICATION then
			self:remove_client(guid)
		elseif message_type == network_event.ID_CONNECTION_LOST then
			self:remove_client(guid)
		elseif message_type == protocol.GAME_TRANSMISSION then
			local entity = self.user_map:at(guid) 
			self.entity_system_instance:post_table("network_message", { 
				subject = entity,
				data = packet,
				channel = entity.client.net_channel
			})
		end
	end
	
	-- tick the game world
	local cpp_world = self.current_map.world_object
	
	cpp_world:handle_input()
	cpp_world:handle_physics()
	
	cpp_world:process_all_systems()
	cpp_world:render()
	
	self.systems.protocol:handle_incoming_commands()
	
	self.systems.inventory:handle_item_requests(cpp_world)
	self.systems.inventory:translate_item_events()

	if #self.systems.client.targets > 0 and self:update_ready() then
		self.systems.client:update_replicas_and_states()
		
		self.entity_system_instance:handle_removed_entities()
		
		-- after all reliable messages (incl. DELETE_OBJECTS) were possibly posted, call network channels
		self.systems.client:send_all_pending_data()		
	end
	
	-- some systems may post reliable commands because of the incoming network messages
	self.systems.client_controller:update()
	
	self.systems.orientation:update()
	
	self.systems.bullet_broadcast:translate_shot_requests()
	self.systems.weapon:update()
	self.systems.bullet_broadcast:broadcast_bullets(self:update_time_remaining())
	self.systems.bullet_broadcast:handle_hit_requests()
	
	self.entity_system_instance:flush_messages()
	
	cpp_world:consume_events()
end
