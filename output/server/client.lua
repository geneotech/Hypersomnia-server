client_class = inherits_from ()

function client_class:constructor()
	self.inventory = {}
	self.position_history = {}
end

function client_class:handle_message(received)
	local message_type = received:byte(0)
	
	if message_type == network_message.ID_GAME_MESSAGE_1 then
		rs = RakString();
		local bsIn = received:get_bitstream()
		bsIn:IgnoreBytes(1)
		bsIn:ReadRakString(rs);
		print (rs:C_String())

		bsOut = BitStream()
		bsOut:WriteByte(UnsignedChar(network_message.ID_GAME_MESSAGE_1));
		WriteCString(bsOut, "Hello world");
		server:send(bsOut, send_priority.HIGH_PRIORITY, send_reliability.RELIABLE_ORDERED, 0, received:guid(), false)
	else
		print ("Message with identifier " .. message_type .. " has arrived.")
	end
end