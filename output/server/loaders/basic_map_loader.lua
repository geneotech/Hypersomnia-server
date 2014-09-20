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
	local environmental_objects = get_all_objects { "static_snow" }
	
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
	scene_object.world_camera = create_world_camera_entity(world, scene_object.sprite_library["blank"])
	scene_object.world_camera.script.owner_scene = scene_object
	scene_object.world_camera.script.max_zoom = 5000
	
	scene_object.main_input = world:create_entity {
		input = {	
			custom_intents.QUIT
		},
		
		script = {
			intent_message = function(self, message)
				if message.intent == custom_intents.QUIT then
					SHOULD_QUIT_FLAG = true
				end		
			end
		}
	}
	
	scene_object.teleport_shuffler = array_shuffler:create(objects_by_type["teleport_position"])
	
	-- bind the atlas once
	GL.glActiveTexture(GL.GL_TEXTURE0)
	scene_object.all_atlas:bind()
	
	local visibility_system = world.visibility_system
	local pathfinding_system = world.pathfinding_system
	local render_system = world.render_system
	
	
	visibility_system.draw_cast_rays = 0
	visibility_system.draw_triangle_edges = 1
	visibility_system.draw_discontinuities = 1
	visibility_system.draw_visible_walls = 1
	
	visibility_system.epsilon_ray_distance_variation = 0.007
	visibility_system.epsilon_threshold_obstacle_hit = 10
	visibility_system.epsilon_distance_vertex_hit = 5
	
	pathfinding_system.draw_memorised_walls = 1
	pathfinding_system.draw_undiscovered = 1
	pathfinding_system.epsilon_max_segment_difference = 4
	pathfinding_system.epsilon_distance_visible_point = 2
	pathfinding_system.epsilon_distance_the_same_vertex = 10
	
	render_system.debug_drawing = 1
	
	render_system.draw_steering_forces = 1
	render_system.draw_substeering_forces = 1
	render_system.draw_velocities = 1
	
	render_system.draw_avoidance_info = 1
	render_system.draw_wandering_info = 1
	
	render_system.visibility_expansion = 1.0
	render_system.max_visibility_expansion_distance = 1
	render_system.draw_visibility = 1
end