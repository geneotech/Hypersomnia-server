player_character = inherits_from (entity_class)

function player_character:constructor()

end

function player_character:handle_command(command_name)
	local state; if string.sub(command_name, 1, 1) == "+" then state = 1 else state = 0 end
	self.parent_entity:get().movement["moving_" .. string.sub(command_name, 2)] = state
end

function create_basic_player(owner_scene, position)
	local player = owner_scene.world_object:ptr_create_entity_group  {
		
		body = {
			render = {
				layer = render_layers.PLAYERS,
				model = blank_sprite
			},
		
			transform = {
				pos = position
			},
			
			physics = {
				body_type = Box2D.b2_dynamicBody,
				
				body_info = {
					filter = filter_characters,
					shape_type = physics_info.RECT,
					rect_size = vec2(37, 37),
					
					angular_damping = 5,
					--linear_damping = 18,
					max_speed = 3300,
					
					fixed_rotation = true,
					density = 0.1
				},
			},
			
			movement = {
				input_acceleration = vec2(5000, 5000),
				air_resistance = 0.1,
				braking_damping = 18
			}
		}
	}
		
	return owner_scene.world_object:create_entity_table(player.body, player_character)
end


