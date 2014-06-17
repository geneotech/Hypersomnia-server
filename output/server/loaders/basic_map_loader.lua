-- gets map filename and scene object to save global entities like players/cameras

return function(map_filename, scene_object)
	-- setup shortcut
	local world = scene_object.world_object
	
	-- load map data
	scene_object.resource_storage = {}
	local objects_by_type, type_table_by_object = tiled_map_loader.get_all_objects_by_type(map_filename)

	-- helper function for getting all objects of given type
	local function get_all_objects(entries)
		local sum_of_all = {}
		for i = 1, #entries do
			sum_of_all = table.concatenate( { sum_of_all, objects_by_type[entries[i]] } )
		end
		
		return sum_of_all
	end
	
	-- initialize environmental physical objects
	local environmental_objects = get_all_objects { "wall_wood", "crate" }
	
	for i = 1, #environmental_objects do
		local object = environmental_objects[i]
		world:create_entity (tiled_map_loader.basic_entity_table(object, type_table_by_object[object], scene_object.resource_storage, scene_object.world_camera, scene_object.texture_by_filename))
	end
	
	world.physics_system.enable_interpolation = 0
	world.physics_system:configure_stepping(config_table.tickrate, 5)
	
	-- initialize input
	world.input_system:clear_contexts()
	world.input_system:add_context(main_input_context)
	
	-- initialize camera
	scene_object.world_camera = create_world_camera_entity(world)
	get_self(scene_object.world_camera).owner_scene = scene_object
	
	scene_object.main_input_entity = world:create_entity_table(world:ptr_create_entity {
		input = {	
			custom_intents.QUIT
		}
	})
	
	scene_object.teleport_position = objects_by_type["teleport_position"][1]
	
	scene_object.main_input_entity.intent_message = function(self, message)
		if message.intent == custom_intents.QUIT then
			SHOULD_QUIT_FLAG = true
		end		
	end
	
	-- bind the atlas once
	GL.glActiveTexture(GL.GL_TEXTURE0)
	scene_object.all_atlas:bind()
end