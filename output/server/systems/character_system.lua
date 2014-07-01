character_system = inherits_from (processing_system)

function character_system:get_required_components()
	return { "character" }
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
					
					msg.subject.cpp_entity.movement["moving_" .. string.sub(command_name, 2)] = state
				elseif message_type == protocol.messages.CLIENT_PREDICTION then
					input_bs:name_property("input_sequence")
					local input_sequence = input_bs:ReadUshort()
					input_bs:name_property("predicted_pos")
					local predicted_pos = to_pixels(input_bs:Readb2Vec2())
					local accepted_divergence = 10
					
					-- if the difference predicted position and actual player position is above certain threshold,
					-- inform him about it
					local actual_pos = msg.subject.cpp_entity.transform.current.pos
					if (predicted_pos - actual_pos):length_sq() > accepted_divergence*accepted_divergence then
						character.commands:Reset()
						character.commands:name_property("CLIENT_PREDICTION")
						character.commands:WriteByte(protocol.messages.CLIENT_PREDICTION)
						character.commands:name_property("input_sequence")
						character.commands:WriteUshort(input_sequence)
						character.commands:name_property("actual_position")
						character.commands:Writeb2Vec2(msg.subject.cpp_entity.physics.body:GetPosition())
						character.commands:name_property("actual_velocity")
						character.commands:Writeb2Vec2(msg.subject.cpp_entity.physics.body:GetLinearVelocity())
					end					
					
					print(input_bs.read_report)
				end
			end
		end
	end
end

