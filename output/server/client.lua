client_class = inherits_from ()

network_message.ID_INITIAL_STATE = network_message.ID_USER_PACKET_ENUM + 1
network_message.ID_MOVEMENT = network_message.ID_USER_PACKET_ENUM + 2
network_message.ID_NEW_PLAYER = network_message.ID_USER_PACKET_ENUM + 3
network_message.ID_PLAYER_DISCONNECTED = network_message.ID_USER_PACKET_ENUM + 4
network_message.ID_COMMAND = network_message.ID_USER_PACKET_ENUM + 5


intent_to_name = {
	[intent_message.MOVE_FORWARD] = "forward",
	[intent_message.MOVE_BACKWARD] = "backward",
	[intent_message.MOVE_LEFT] = "left",
	[intent_message.MOVE_RIGHT] = "right"
}

name_to_command = {
	["+forward"] = 1,
	["-forward"] = 2,
	["+backward"] = 3,
	["-backward"] = 4,
	["+left"] = 5,
	["-left"] = 6,
	["+right"] = 7,
	["-right"] = 8
}

name_to_intent = {}
command_to_name = {}

for k, v in pairs (name_to_command) do
	command_to_name[v] = k
end

for k, v in pairs (intent_to_name) do
	name_to_intent[v] = k
end


function client_class:constructor(owner_scene, guid)
	self.position_history = {}
	self.guid = guid
	
	-- create new entity here
	self.controlled_character = create_basic_player(owner_scene, teleport_position)
	print "A connection is incoming."
	
	-- firstly notify this one about the game state
	local bsOut = BitStream()
	bsOut:WriteByte(UnsignedChar(network_message.ID_INITIAL_STATE))
	WriteUint(bsOut, user_map:size())
	
	for i=1, #all_clients do
		WriteRakNetGUID(bsOut, all_clients[i].guid)
	end
	
	server:send(bsOut, send_priority.HIGH_PRIORITY, send_reliability.RELIABLE_ORDERED, 0, guid, false)
	
	bsOut = BitStream()
	bsOut:WriteByte(UnsignedChar(network_message.ID_NEW_PLAYER))
	WriteRakNetGUID(bsOut, guid)
	
	-- notify all others that the client was created
	server:send(bsOut, send_priority.HIGH_PRIORITY, send_reliability.RELIABLE_ORDERED, 0, guid, true)
end


function client_class:close_connection()
	sample_scene.world_object.world:delete_entity(self.controlled_character.parent_entity:get(), nil)

	for i=1, #all_clients do
		if all_clients[i] == self then
			table.remove(all_clients, i)
			break
		end
	end
	
	local bsOut = BitStream()
	print(network_message.ID_PLAYER_DISCONNECTED)
	bsOut:WriteByte(UnsignedChar(network_message.ID_PLAYER_DISCONNECTED))
	WriteRakNetGUID(bsOut, self.guid)
	
	-- notify all but disconnected one
	server:send(bsOut, send_priority.HIGH_PRIORITY, send_reliability.RELIABLE_ORDERED, 0, self.guid, true)
end

function client_class:handle_message(received)
	local message_type = received:byte(0)
	
	if message_type == network_message.ID_COMMAND then
		local bsIn = received:get_bitstream()
		-- bsIn:IgnoreBytes(1)
		local command_name = command_to_name[received:byte(1)]
		
		self.controlled_character:handle_command(command_name)
	else
		print ("Message with identifier " .. message_type .. " has arrived.")
	end
end