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
			
			character.at_step = command.at_step
		else
			-- zero out the outputs
			
			local movement = self.targets[i].cpp_entity.movement
			
			movement.moving_left = 0
			movement.moving_right = 0
			movement.moving_forward = 0
			movement.moving_backward = 0
		end
		
		self.targets[i].client.substep_unreliable:WriteBitstream(protocol.write_msg("CLIENT_PREDICTION", {
				at_step = self.targets[i].character.at_step,
				position = self.targets[i].cpp_entity.physics.body:GetPosition(),
				velocity = self.targets[i].cpp_entity.physics.body:GetLinearVelocity()
			}))
	end
end

function character_system:update()
	local msgs = self.owner_entity_system.messages["INPUT_SNAPSHOT"]
	
	for i=1, #msgs do
		local msg = msgs[i]
		
		local character = msg.subject.character
		
		if character ~= nil then
			table.insert(character.buffered_commands, msg.data)
		end
	end
end

