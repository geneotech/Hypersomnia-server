dofile "config.lua"

print "Initialization successful."

ENGINE_DIRECTORY = "..\\..\\Augmentations\\scripts\\"
dofile (ENGINE_DIRECTORY .. "load_libraries.lua")

server = network_interface()
server:listen(37017, 30, 40)

received = network_packet()

user_map = guid_to_object_map()


CLIENT_CODE_DIRECTORY = "..\\..\\Hypersomnia\\output\\hypersomnia\\"
MAPS_DIRECTORY = CLIENT_CODE_DIRECTORY .. "data\\maps\\"

dofile (CLIENT_CODE_DIRECTORY .. "scripts\\game\\layers.lua")
dofile (CLIENT_CODE_DIRECTORY .. "scripts\\game\\filters.lua")

dofile "server\\client.lua"

dofile "server\\view\\input.lua"
dofile "server\\view\\camera.lua"


sample_scene = scene_class:create()
sample_scene:load_map(MAPS_DIRECTORY .. "sample_map.lua", "server\\loaders\\basic_map_loader.lua")

blank_sprite = create_sprite {
	image = sample_scene.sprite_library["blank"],
	color = rgba(0, 255, 0, 255),
	size = vec2(37, 37)
}

all_clients = {}

dofile "server\\game\\player.lua"

SHOULD_QUIT_FLAG = false

server:enable_lag(0.2, 100, 50)

while not SHOULD_QUIT_FLAG do
	if server:receive(received) then
		local message_type = received:byte(0)
		if message_type == network_message.ID_NEW_INCOMING_CONNECTION then
			local new_client = client_class:create(sample_scene, received:guid())
			user_map:add(received:guid(), new_client)
			
		elseif message_type == network_message.ID_DISCONNECTION_NOTIFICATION then
			user_map:at(received:guid()):close_connection()
			user_map:remove(received:guid())
			print "A client has disconnected."
		elseif message_type == network_message.ID_CONNECTION_LOST then
			user_map:at(received:guid()):close_connection()
			user_map:remove(received:guid())
			print "A client lost the connection."
		else
			user_map:at(received:guid()):handle_message(received)
		end
	end
	
	for j=1, #all_clients do
		all_clients[j]:loop()
	end
	
	-- tick the game world
	sample_scene:loop()
end
