-- this should be named "client_controller_system"
client_controller_system = inherits_from (processing_system)

function client_controller_system:constructor()
	self.steps = 0
	
	processing_system.constructor(self)
end

function client_controller_system:get_required_components()
	return { "client_controller" }
end


function client_controller_system:remove_entity(removed_entity)
	if removed_entity.client_controller.owner_client ~= nil then
		removed_entity.client_controller.owner_client.client.controlled_object = nil
	end
end

function client_controller_system:substep()
	self.steps = self.steps + 1
	for i=1, #self.targets do
		local client_controller = self.targets[i].client_controller 
		local commands = client_controller.buffered_commands
		local movement = self.targets[i].cpp_entity.movement
		
		--local predicted = " "
		
		if #commands > 0 then
			local command = commands[1]
			
			table.remove(commands, 1)
		
			
			
			movement.moving_left = command.moving_left
			movement.moving_right = command.moving_right
			movement.moving_forward = command.moving_forward
			movement.moving_backward = command.moving_backward
			
			client_controller.at_step = command.at_step
			
			self.targets[i].client_controller.owner_client.client.substep_unreliable:WriteBitstream(protocol.write_msg("CURRENT_STEP", {
				at_step = client_controller.at_step
			}))
		else
			--predicted = " (predicted)"
			--character.at_step = character.at_step + 1
		end
		
		--global_logfile:write("\nStep: " .. character.at_step .. predicted)
		--global_logfile:write("\nleft: " .. movement.moving_left)
		--global_logfile:write("\nright: " .. movement.moving_right)
		--global_logfile:write("\nforward: " .. movement.moving_forward)
		--global_logfile:write("\nbackward: " .. movement.moving_backward)
		

	end
end

function client_controller_system:update()
	local msgs = self.owner_entity_system.messages["INPUT_SNAPSHOT"]
	
	for i=1, #msgs do
		local msg = msgs[i]
		
		local client_controller = msg.subject.client.controlled_object.client_controller
		
		if client_controller ~= nil then
			table.insert(client_controller.buffered_commands, msg.data)
		end
	end
end

