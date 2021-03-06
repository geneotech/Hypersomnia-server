world_archetypes.create_player = function(owner_scene, position)
	return owner_scene.world_object:create_entity  {
		render = {
			layer = render_layers.PLAYERS,
			model = owner_scene.blank_sprite
		},
		
		transform = {
			pos = position
		},
		
		physics = {
			body_type = Box2D.b2_dynamicBody,
			
			body_info = {
				filter = filters.CHARACTER,
				shape_type = physics_info.RECT,
				rect_size = vec2(37, 37),
				
				angular_damping = 5,
				--linear_damping = 18,
				--max_speed = 3300,
				
				fixed_rotation = true,
				density = 0.1,
				angled_damping = true
			},
		},
		
		movement = {
			input_acceleration = vec2(5000, 5000),
			max_accel_len = 5000,
			air_resistance = 0.6,
			braking_damping = 18
		}
	}
end


