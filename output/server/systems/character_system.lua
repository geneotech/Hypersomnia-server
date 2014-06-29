character_system = inherits_from (processing_system)

function character_system:get_required_components()
	return { "character" }
end

function character_system:update()
	local msgs = self.owner_entity_system.messages["client_commands"]
	
	for i=1, #msgs do
		local msg = msgs[i]
		
		local input_bs = msg:get_bitstream()
		
		if msg.subject.character ~= nil then
			while input_bs:GetNumberOfUnreadBits() >= 8 do
				local message_type = input_bs:ReadByte()
				
				if message_type == protocol.messages.COMMAND then	
					-- handle movement
					local command_name = protocol.command_to_name[input_bs:ReadByte()]
					
					local state; 
					
					if string.sub(command_name, 1, 1) == "+" then state = 1 else state = 0 end
					
					msg.subject.cpp_entity.movement["moving_" .. string.sub(command_name, 2)] = state
				end
			end
		end
	end
end

