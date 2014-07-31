orientation_system = inherits_from (processing_system)

function orientation_system:update()
	local msgs = self.owner_entity_system.messages["CROSSHAIR_SNAPSHOT"]
	
	for i=1, #msgs do
		local msg = msgs[i]
		local character = msg.subject.client.controlled_object
		
		character.orientation.crosshair_position = msgs[i].data.position
	end
end


