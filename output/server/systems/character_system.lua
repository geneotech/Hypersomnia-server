character_system = inherits_from (processing_system)

function character_system:get_required_components()
	return { "character" }
end

function character_system:remove_entity(removed_entity)
	local world_entity = removed_entity.character.world_entity
	world_entity.owner_world:delete_entity(world_entity, nil)
	
	processing_system.remove_entity(self, removed_entity)
end

function character_system:update()
	local msgs = self.owner_entity_system.messages["client_commands"]
	
	for i=1, #msgs do
		local msg = msgs[i]
		local character = msg.subject.character
		
		local input_bs = msg:get_command_bitstream()
		
		if character ~= nil then
			while input_bs:GetNumberOfUnreadBits() > 0 do
				local message_type = input_bs:ReadByte()
				
				if message_type == protocol.message.COMMAND then	
					-- handle movement
					local command_name = command_to_name[input_bs:ReadByte()]
					
					local state; 
					
					if string.sub(command_name, 1, 1) == "+" then state = 1 else state = 0 end
					
					character.world_entity.movement["moving_" .. string.sub(command_name, 2)] = state
				end
			end
		end
	end
end

