client_class = inherits_from ()

network_message.ID_INITIAL_STATE = network_message.ID_USER_PACKET_ENUM + 1
network_message.ID_MOVEMENT = network_message.ID_USER_PACKET_ENUM + 2
network_message.ID_NEW_PLAYER = network_message.ID_USER_PACKET_ENUM + 3

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

function client_class:handle_message(received)
	local message_type = received:byte(0)
	
	if message_type == network_message.ID_MOVEMENT then
		
	else
		print ("Message with identifier " .. message_type .. " has arrived.")
	end
end