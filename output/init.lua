print "Initialization successful."

ENGINE_DIRECTORY = "..\\..\\Augmentations\\scripts\\"
dofile (ENGINE_DIRECTORY .. "load_libraries.lua")

server = network_interface()
server:listen(37017, 2, 4)

received = network_packet()

network_message.ID_GAME_MESSAGE_1 = network_message.ID_USER_PACKET_ENUM + 1

user_map = guid_to_object_map()

dofile "server\\client.lua"
-- we must hold hold these here so the objects don't get deleted
-- all_users_container = {}

while true do
	if server:receive(received) then
		local message_type = received:byte(0)
		if message_type == network_message.ID_NEW_INCOMING_CONNECTION then
			user_map:add(received:guid(), client_class:create())
			print "A connection is incoming."
			print (user_map:size())
		elseif message_type == network_message.ID_DISCONNECTION_NOTIFICATION then
			user_map:remove(received:guid())
			print "A client has disconnected."
			print (user_map:size())
		elseif message_type == network_message.ID_CONNECTION_LOST then
			user_map:remove(received:guid())
			print "A client lost the connection."
			print (user_map:size())
		else
			user_map:at(received:guid()):handle_message(received)
		end
	end
end
