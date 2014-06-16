client_class = inherits_from ()

network_message.ID_MOVEMENT = network_message.ID_USER_PACKET_ENUM + 1
network_message.ID_NEW_PLAYER = network_message.ID_USER_PACKET_ENUM + 2

function client_class:constructor(owner_scene, guid)
	self.position_history = {}
	self.guid = guid
	
	self.controlled_character = create_basic_player(owner_scene, teleport_position)
	print "A connection is incoming."
	-- create new entity here
end

function client_class:handle_message(received)
	local message_type = received:byte(0)
	
	if message_type == network_message.ID_MOVEMENT then
		
	else
		print ("Message with identifier " .. message_type .. " has arrived.")
	end
end