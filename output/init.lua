print "Initialization successful."

ENGINE_DIRECTORY = "..\\..\\Augmentations\\scripts\\"
dofile (ENGINE_DIRECTORY .. "load_libraries.lua")

local server = network_interface()
server:listen(37017, 2, 4)

local received = network_packet()

network_message.ID_GAME_MESSAGE_1 = network_message.ID_USER_PACKET_ENUM + 1

while true do
	if server:receive(received) then
		local message_type = received:byte(0)
		if message_type == network_message.ID_NEW_INCOMING_CONNECTION then
			print "A connection is incoming."
		elseif message_type == network_message.ID_DISCONNECTION_NOTIFICATION then
			print "A client has disconnected."
		elseif message_type == network_message.ID_CONNECTION_LOST then
			print "A client lost the connection."
		elseif message_type == network_message.ID_GAME_MESSAGE_1 then
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
end
