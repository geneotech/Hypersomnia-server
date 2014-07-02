character_system = inherits_from (processing_system)

function character_system:constructor()
	self.steps = 0
	
	processing_system.constructor(self)
end

function character_system:get_required_components()
	return { "character" }
end

function character_system:substep()
	global_logfile:write(("Step number.." .. self.steps .. "\n"))
	
	self.steps = self.steps + 1
	for i=1, #self.targets do
		local commands = self.targets[i].character.buffered_commands
		
		if #commands > 0 then
			local command = commands[1]
			table.remove(commands, 1)
		
			local movement = self.targets[i].cpp_entity.movement
			
			movement.moving_left = command.moving_left
			movement.moving_right = command.moving_right
			movement.moving_forward = command.moving_forward
			movement.moving_backward = command.moving_backward
			
			global_logfile:write(("Applying inputs.."))
			global_logfile:write(("\nLeft:" .. movement.moving_left))
			global_logfile:write(("\nRight:" .. movement.moving_right))
			global_logfile:write(("\nForward:" .. movement.moving_forward))
			global_logfile:write(("\nBackward:" .. movement.moving_backward))
			global_logfile:write("\n")
			
		else
			-- zero out the outputs
			
			--local movement = self.targets[i].cpp_entity.movement
			
			--movement.moving_left = 0
			--movement.moving_right = 0
			--movement.moving_forward = 0
			--movement.moving_backward = 0
		end
	end
end

function character_system:update()
	local msgs = self.owner_entity_system.messages["client_commands"]
	
	for i=1, #msgs do
		local msg = msgs[i]
		
		local input_bs = msg:get_bitstream()
		
		local character = msg.subject.character
		if character ~= nil then
			while input_bs:GetNumberOfUnreadBits() >= 8 do
				input_bs:name_property("message_type")
				local message_type = input_bs:ReadByte()
				
				if message_type == protocol.messages.COMMAND then	
					-- handle movement
					input_bs:name_property("command_id")
					local command_name = protocol.command_to_name[input_bs:ReadByte()]
					
					local state; 
					
					if string.sub(command_name, 1, 1) == "+" then state = 1 else state = 0 end
					
					--msg.subject.cpp_entity.movement["moving_" .. string.sub(command_name, 2)] = state
				elseif message_type == protocol.messages.INPUT_SNAPSHOT then
					local new_command = {}
					
					if input_bs:ReadBit() then
						new_command.moving_left = 1
						else new_command.moving_left = 0
					end
					if input_bs:ReadBit() then
						new_command.moving_right = 1
						else new_command.moving_right = 0
					end
					if input_bs:ReadBit() then
						new_command.moving_forward = 1
						else new_command.moving_forward = 0
					end
					if input_bs:ReadBit() then
						new_command.moving_backward = 1
						else new_command.moving_backward = 0
					end
					
					table.insert(character.buffered_commands, new_command)
					
				elseif message_type == protocol.messages.CLIENT_PREDICTION then
					input_bs:name_property("input_sequence")
					local input_sequence = input_bs:ReadUint()
					
					if character.last_input_sequence == nil or character.last_input_sequence ~= input_sequence then
						character.last_input_sequence = input_sequence
						local accepted_divergence = 15
						
						-- if the difference predicted position and actual player position is above certain threshold,
						-- inform him about it
						local actual_pos = msg.subject.cpp_entity.transform.current.pos
						--if (predicted_pos - actual_pos):length_sq() > accepted_divergence*accepted_divergence then
							character.commands:Reset()
							character.commands:name_property("CLIENT_PREDICTION")
							character.commands:WriteByte(protocol.messages.CLIENT_PREDICTION)
							character.commands:name_property("input_sequence")
							character.commands:WriteUint(input_sequence)
							character.commands:name_property("actual_position")
							character.commands:Writeb2Vec2(msg.subject.cpp_entity.physics.body:GetPosition())
							character.commands:name_property("actual_velocity")
							character.commands:Writeb2Vec2(msg.subject.cpp_entity.physics.body:GetLinearVelocity())
							
							local left = msg.subject.cpp_entity.movement.moving_left > 0
							local right = msg.subject.cpp_entity.movement.moving_left > 0
							local forward = msg.subject.cpp_entity.movement.moving_left > 0
							local back = msg.subject.cpp_entity.movement.moving_left > 0
							
							character.commands:WriteBit(left)
							character.commands:WriteBit(right)
							character.commands:WriteBit(forward)
							character.commands:WriteBit(back)
							
						--end	
					end
				end
			end
		end
	end
end

