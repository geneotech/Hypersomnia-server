dofile (CLIENT_CODE_DIRECTORY .. "scripts\\protocol.lua")

dofile (CLIENT_CODE_DIRECTORY .. "scripts\\archetypes\\archetype_library.lua")
dofile "server\\world_archetypes\\world_archetypes.lua"

dofile "server\\components\\client.lua"
dofile "server\\components\\replication.lua"
dofile "server\\components\\client_controller.lua"
dofile "server\\components\\orientation.lua"

dofile "server\\components\\npc.lua"

dofile (CLIENT_CODE_DIRECTORY .. "scripts\\game\\weapons.lua")

dofile (CLIENT_CODE_DIRECTORY .. "scripts\\sync_modules\\modules.lua")
dofile (CLIENT_CODE_DIRECTORY .. "scripts\\sync_modules\\movement_sync.lua")
dofile (CLIENT_CODE_DIRECTORY .. "scripts\\sync_modules\\crosshair_sync.lua")
dofile (CLIENT_CODE_DIRECTORY .. "scripts\\sync_modules\\client_info_sync.lua")
dofile (CLIENT_CODE_DIRECTORY .. "scripts\\sync_modules\\health_sync.lua")
dofile (CLIENT_CODE_DIRECTORY .. "scripts\\sync_modules\\item_sync.lua")
dofile (CLIENT_CODE_DIRECTORY .. "scripts\\sync_modules\\gun_sync.lua")
dofile (CLIENT_CODE_DIRECTORY .. "scripts\\sync_modules\\label_sync.lua")

dofile (CLIENT_CODE_DIRECTORY .. "scripts\\components\\weapon.lua")
dofile (CLIENT_CODE_DIRECTORY .. "scripts\\components\\health.lua")
dofile (CLIENT_CODE_DIRECTORY .. "scripts\\components\\wield.lua")
dofile (CLIENT_CODE_DIRECTORY .. "scripts\\components\\item.lua")
dofile (CLIENT_CODE_DIRECTORY .. "scripts\\components\\inventory.lua")
dofile (CLIENT_CODE_DIRECTORY .. "scripts\\components\\label.lua")

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

dofile "server\\systems\\npc_system.lua"

dofile "server\\systems\\health_system.lua"

dofile "server\\chat.lua"

server_class = inherits_from()
dofile "server\\session_creation.lua"

function server_class:constructor()
	self.server = network_interface()
	
	self.server:occasional_ping(true)
	self.server:set_timeout_all(17000)
	
	self.received = network_packet()
	self.user_map = guid_to_object_map()

	self.entity_system_instance = entity_system:create(function () self.current_map.world_object:call_deletes() end)
	
	self.entity_system_instance:register_messages {
		"network_message",
		"shot_message",
		"item_wielder_change",
		
		"pick_item",
		"drop_item",
		
		"damage_message",
		
		"begin_swinging",
		"swing_hitcheck"
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
	self.systems.npc = npc_system:create()
	
	self.entity_system_instance:register_systems(self.systems)
	
	self.entity_system_instance:register_callbacks {
		item_wielder_change = function(msg) 
			self.systems.wield:handle_wielder_change(msg)
			self.systems.wield:broadcast_changes(msg)
		end,
		
		damage_message = handle_damage_message
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

function server_class:new_connection(new_guid)
	self.user_map:add(new_guid, {
		connection_duration = timer()
	})
	
	print "New incoming connection."
end

function server_class:remove_client(guid)	
	local client = self.user_map:at(guid)
	
	if client.client and client.client.controlled_object ~= nil then
		self.entity_system_instance:remove_entity(client.client.controlled_object)
		self.entity_system_instance:remove_entity(client)
	end
	
	self.user_map:remove(guid)
	
	print "A client has disconnected or lost the connection."
end

function server_class:loop()
	--print(self.global_timer:extract_milliseconds())

	local packet = self.received
	
	if self.server:receive(packet) then
		local message_type = packet:byte(0)
		local guid = packet:guid()
		
		local is_reliable_transmission = message_type == protocol.RELIABLE_TRANSMISSION
		
		if message_type == network_event.ID_NEW_INCOMING_CONNECTION then
			self:new_connection(guid)
		elseif message_type == network_event.ID_DISCONNECTION_NOTIFICATION then
			self:remove_client(guid)
		elseif message_type == network_event.ID_CONNECTION_LOST then
			self:remove_client(guid)
		elseif message_type == protocol.GAME_TRANSMISSION or is_reliable_transmission then
			local entity = self.user_map:at(guid)
			local target_channel;
			
			if entity.client then
				target_channel = entity.client.net_channel
			end
			
			self.entity_system_instance:post_table("network_message", { 
				["guid"] = guid,
				subject = entity,
				data = packet,
				channel = target_channel,
				["is_reliable_transmission"] = is_reliable_transmission
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
	
	self.systems.npc:loop()
	
	broadcast_chat_messages(self.entity_system_instance)
	self:create_incoming_sessions()
	
	self.entity_system_instance:flush_messages()
	
	cpp_world:consume_events()
end
