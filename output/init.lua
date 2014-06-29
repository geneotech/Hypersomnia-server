
global_logfile = io.open("server_logfile.txt", "w")

dofile "config.lua"

print "Initialization successful."

ENGINE_DIRECTORY = "..\\..\\Augmentations\\scripts\\"
dofile (ENGINE_DIRECTORY .. "load_libraries.lua")

CLIENT_CODE_DIRECTORY = "..\\..\\Hypersomnia\\output\\hypersomnia\\"
MAPS_DIRECTORY = CLIENT_CODE_DIRECTORY .. "data\\maps\\"

dofile (CLIENT_CODE_DIRECTORY .. "scripts\\game\\layers.lua")
dofile (CLIENT_CODE_DIRECTORY .. "scripts\\game\\filters.lua")

dofile "server\\view\\input.lua"
dofile "server\\view\\camera.lua"

dofile "server\\server_class.lua"

server = server_class:create()
server:start(37017, 30, 60)
server:set_current_map(MAPS_DIRECTORY .. "sample_map.lua", "server\\loaders\\basic_map_loader.lua")

SHOULD_QUIT_FLAG = false

while not SHOULD_QUIT_FLAG do
	server:loop()
end
global_logfile:close()
