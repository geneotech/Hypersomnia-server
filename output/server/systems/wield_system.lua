function wield_system:get_item_in_range(physics_system, what_entity, try_to_pick_weapon)
	local items_in_range = physics_system:query_body(what_entity, filters.ITEM_PICK, nil)
	
	local found_item;
	
	for candidate in items_in_range.bodies do
		if try_to_pick_weapon == nil or (try_to_pick_weapon ~= nil and body_to_entity(candidate) == try_to_pick_weapon) then 
			found_item = body_to_entity(candidate).script
			break
		end
	end
	
	return found_item
end

function wield_system:handle_pick_requests(world_object)
	local msgs = self.owner_entity_system.messages["PICK_REQUEST"]
	
	for i=1, #msgs do
		local msg = msgs[i]
		local subject = msg.subject
		local character = subject.client.controlled_object
		
		if character ~= nil then
			local wield = character.wield
			if wield ~= nil then
				local found_item = self:get_item_in_range(world_object.physics_system, character.cpp_entity)
				
				-- subject validity ensured here
				if wield.wielded_item ~= nil then
					self.owner_entity_system:post_table("item_ownership", {
						subject = character,
						drop = true
					})
				end
			
				if found_item then
					self.owner_entity_system:post_table("item_ownership", {
						subject = character,
						item = found_item,
						pick = true
					})
				end
			end
		end
	end
end


function wield_system:broadcast_item_ownership()
	local msgs = self.owner_entity_system.messages["item_ownership"]
	local replication = self.owner_entity_system.all_systems["replication"]
	
	for i=1, #msgs do
		local msg = msgs[i]
		if msg.succeeded == true then
			local subject = msg.subject
			local wield = subject.wield
		
			local subject_states = subject.replication.remote_states
			
			if msg.pick == true then
				local item = msg.item
				local item_states = item.replication.remote_states
				
				-- get all clients who see either the item or the subject
				local clients = {}
				
				for client_entity, v in pairs(item_states) do
					clients[#clients+1] = client_entity
				end
				
				for client_entity, v in pairs(subject_states) do
					clients[#clients+1] = client_entity
				end
				
				-- if either the item or the subject is invisible to the client,
				-- post a creation message immediately
				
				-- remember that the initial state is replicated on the go
				for j=1, #clients do
					if item_states[clients[j]] == nil then
						replication:update_state_for_client(clients[j], false, { item } )
					elseif subject_states[clients[j]] == nil then
						replication:update_state_for_client(clients[j], false, { subject } )
					end
					
					-- once we're ensured, post the pick message
					clients[j].client.net_channel:post_reliable("ITEM_PICKED", {
						subject_id = subject.replication.id,
						item_id = item.replication.id
					})
				end
			elseif msg.drop == true then
				for client_entity, v in pairs(subject_states) do
					client_entity.client.net_channel:post_reliable("ITEM_DROPPED", {
						subject_id = subject.replication.id
					})
				end
			end
		end
	end
end
