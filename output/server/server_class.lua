dofile (CLIENT_CODE_DIRECTORY .. "scripts\\protocol.lua")

dofile "server\\world_archetypes\\world_archetypes.lua"

dofile "server\\messages\\network_message.lua"
dofile "server\\messages\\client_commands.lua"

dofile "server\\components\\client.lua"
dofile "server\\components\\synchronization.lua"
dofile "server\\components\\character.lua"


dofile (CLIENT_CODE_DIRECTORY .. "scripts\\sync_modules\\modules.lua")
dofile (CLIENT_CODE_DIRECTORY .. "scripts\\sync_modules\\movement_sync.lua")

dofile "server\\systems\\character_system.lua"
dofile "server\\systems\\client_system.lua"
dofile "server\\systems\\synchronization_system.lua"


server_class = inherits_from()

function server_class:constructor()
	self.server = network_interface()
	self.received = network_packet()
	self.user_map = guid_to_object_map()

	self.entity_system_instance = entity_system:create()
	
	self.entity_system_instance:register_messages {
		"network_message",
		"client_commands"
	}
	
	-- create all necessary systems
	self.systems = {}
	self.systems.synchronization = synchronization_system:create()
	self.systems.client = client_system:create(self.server)
	self.systems.character = character_system:create()
	
	self.entity_system_instance:register_systems(self.systems)
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
end

function server_class:new_client(new_guid)
	local world_character = world_archetypes.create_player(self.current_map, vec2(0, 0))

	local client_modules = {}
	table.insert(client_modules, sync_modules.movement:create(world_character))
	
	local new_client = components.create_components {
		client = {
			guid = new_guid
		},
		
		synchronization = {
			modules = client_modules
		},
		
		character = {},
		
		cpp_entity = world_character
	}
	
	self.entity_system_instance:add_entity(new_client)	
	self.user_map:add(new_guid, new_client)
	
	print "New client connected."
end

function server_class:remove_client(guid)	
	self.entity_system_instance:remove_entity(self.user_map:at(guid))
	self.user_map:remove(guid)
	
	print "A client has disconnected or lost the connection."
end

function server_class:loop()
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
			self.entity_system_instance:post(network_message:create { 
				subject = self.user_map:at(guid),
				data = packet
			})
		end
	end

	self.systems.client:handle_incoming_commands()
	
	-- some systems may post reliable commands because of the incoming network messages
	self.systems.character:update()

	
	-- after all reliable messages were possibly posted, do the update tick
	self.systems.client:update_tick()
	
	self.entity_system_instance:flush_messages()
	
	-- tick the game world
	self.current_map:loop()
end