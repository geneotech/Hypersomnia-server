-- this should be named "client_controller_system"
client_controller_system = inherits_from (processing_system)

function client_controller_system:constructor()
	self.steps = 0
	self.action_callbacks = {}
	
	processing_system.constructor(self)
end

function client_controller_system:get_required_components()
	return { "client_controller" }
end


function client_controller_system:remove_entity(removed_entity)
	if removed_entity.client_controller.owner_client ~= nil then
		removed_entity.client_controller.owner_client.client.controlled_object = nil
	end
	
	processing_system.remove_entity(self, removed_entity)
end

function client_controller_system:populate_action_channels()
	local msgs = self.owner_entity_system.messages["CHARACTER_ACTIONS"]
	--local replication = self.owner_entity_system.all_systems["replication"]
	
	for i=1, #msgs do
		local subject = msgs[i].subject
		local character = subject.client.controlled_object
		
		if character and character.client_controller then
			table.insert(character.client_controller.buffered_actions, msgs[i])
		end
	end
end

--function client_controller_system:clean_action_channels()
--	for i=1, #self.targets do
--		local requests = self.targets[i].client.item_requests
--		
--		while requests[1] and requests[1].handled do
--			table.remove(requests, 1)
--		end
--	end
--end

function client_controller_system:invoke_action_callbacks()
	for i=1, #self.targets do
		local actions = self.targets[i].client_controller.buffered_actions
		
		while actions[1] do
			--local callback = self.action_callbacks[actions[1].name]
			if actions[1].handled then
				table.remove(actions, 1)
			elseif not actions[1].issued then
				-- assume handled
				actions[1].handled = true
				
				self.action_callbacks[actions[1].name](actions[1])
		
				actions[1].issued = true
			else -- issued and not handled, nothing to do here
				break
			end
		end
	end
end

function client_controller_system:substep()
	self.steps = self.steps + 1
	for i=1, #self.targets do
		local client_controller = self.targets[i].client_controller 
		local commands = client_controller.buffered_movement
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
			table.insert(client_controller.buffered_movement, msg.data)
		end
	end
end

