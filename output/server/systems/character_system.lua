character_system = inherits_from (processing_system)

function character_system:constructor()
	self.steps = 0
	
	processing_system.constructor(self)
end

function character_system:get_required_components()
	return { "character" }
end

function character_system:substep()
	self.steps = self.steps + 1
	for i=1, #self.targets do
		local character = self.targets[i].character 
		local commands = character.buffered_commands
		
		if #commands > 0 then
			local command = commands[1]
			table.remove(commands, 1)
		
			local movement = self.targets[i].cpp_entity.movement
			
			movement.moving_left = command.moving_left
			movement.moving_right = command.moving_right
			movement.moving_forward = command.moving_forward
			movement.moving_backward = command.moving_backward
			
			character.at_step = command.step_number
		else
			-- zero out the outputs
			
			local movement = self.targets[i].cpp_entity.movement
			
			movement.moving_left = 0
			movement.moving_right = 0
			movement.moving_forward = 0
			movement.moving_backward = 0
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
				
				if message_type == protocol.messages.INPUT_SNAPSHOT then
					local new_command = {}
					
					new_command.step_number = input_bs:ReadUint()
					
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
				end
			end
		end
	end
end

