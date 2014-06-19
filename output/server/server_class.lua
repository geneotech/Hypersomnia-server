server_class = inherits_from()

function server_class:constructor()
	self.server = network_interface()
	
	self.received = network_packet()
	
	self.user_map = guid_to_object_map()

	self.all_clients = {}
end

function server_class:start(port, max_players, max_connections)
	self.server:listen(port, max_players, max_connections)
	
	if config_table.simulate_lag ~= 0 then
		print "Simulating lag..."
		server:enable_lag(config_table.packet_loss, config_table.min_latency, config_table.jitter)
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

function server_class:new_client(guid)
	local new_client = client_class:create(self.server, guid)
	new_client:create_character(self.current_map, vec2(#self.all_clients*(-40), 0))
	new_client:pass_initial_state(self.all_clients)
	new_client:broadcast_new_client()
	
	table.insert(self.all_clients, new_client)
	
	self.user_map:add(guid, new_client)		
	
	print "New client connected."
end

function server_class:remove_client(guid)
	local removed_client = self.user_map:at(guid)
	removed_client:close_connection(self.current_map)

	table.erase(self.all_clients, removed_client)
	self.user_map:remove(guid)
	
	print "A client has disconnected or lost the connection."
end

function server_class:loop()
	local packet = self.received
	
	if self.server:receive(packet) then
		local message_type = packet:byte(0)
		local guid = packet:guid()
		
		if message_type == network_message.ID_NEW_INCOMING_CONNECTION then
			self:new_client(guid)
		elseif message_type == network_message.ID_DISCONNECTION_NOTIFICATION then
			self:remove_client(guid)
		elseif message_type == network_message.ID_CONNECTION_LOST then
			self:remove_client(guid)
		else
			self.user_map:at(guid):handle_message(packet)
		end
	end
	
	for j=1, #self.all_clients do
		self.all_clients[j]:loop(self.all_clients)
	end
	
	-- tick the game world
	self.current_map:loop()
end