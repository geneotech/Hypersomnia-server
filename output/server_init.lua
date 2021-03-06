
global_logfile = io.open("server_logfile.txt", "w")
transmission_log = io.open("server_transmission.txt", "w")

dofile "server_config.lua"

print "Initialization successful."

ENGINE_DIRECTORY = "..\\..\\Augmentations\\scripts\\"
dofile (ENGINE_DIRECTORY .. "load_libraries.lua")

CLIENT_CODE_DIRECTORY = "..\\..\\Hypersomnia\\output\\hypersomnia\\"
MAPS_DIRECTORY = CLIENT_CODE_DIRECTORY .. "data\\maps\\"

dofile (CLIENT_CODE_DIRECTORY .. "scripts\\game\\layers.lua")
dofile (CLIENT_CODE_DIRECTORY .. "scripts\\game\\filters.lua")

dofile "server\\view\\server_input.lua"
dofile "server\\view\\server_camera.lua"

dofile "server\\server_class.lua"

--setup_debugger()

server = server_class:create()
server:start(config_table.server_port, 30, 60)
server:set_current_map(MAPS_DIRECTORY .. "cathedral2.lua", "server\\loaders\\server_map_loader.lua")

SHOULD_QUIT_FLAG = false

while not SHOULD_QUIT_FLAG do
	server:loop()
end

transmission_log:close()
global_logfile:close()
