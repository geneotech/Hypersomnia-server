

function wield_system:broadcast_item_selections()
	local replication = self.owner_entity_system.all_systems["replication"]
	
	local msgs = self.owner_entity_system.messages["item_wielder_change"]
	
	for i=1, #msgs do
		local msg = msgs[i]
		if msg.succeeded == true then
			local subject = msg.subject
			local item = msg.item
			local subject_states = subject.replication.remote_states
				
			if msg.unwield then
				subject.replication.sub_entity_groups.WIELDED_ENTITIES[msg.wielding_key] = nil
				item.replication:switch_public_group("DROPPED_PUBLIC")
				
				if subject.client_controller ~= nil then
					item.replication:clear_group_for_client(subject.client_controller.owner_client)
				end
				
				-- if we UNSELECTED an item, only the clients seeing the subject are interested
				for client_entity, v in pairs(subject_states) do
					client_entity.client.net_channel:post_reliable("ITEM_UNWIELDED", {
						subject_id = subject.replication.id,
						wielding_key = msg.wielding_key
					})
				end
			elseif msg.wield then
				subject.replication.sub_entity_groups.WIELDED_ENTITIES[msg.wielding_key] = item
				
				local wield = subject.wield
				local item_states = item.replication.remote_states
				
				-- inventory system uses the same group, so if we have an inventory component,
				-- OWNER group will already be set upon the item being picked and this call will have no effect
				
				-- alternatively, should we want to have different groups for a wielded object
				-- and an object residing in the inventory, the inventory system will loop through successful
				-- wielder changes and set its own group there
				
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
				
				-- remember that the initial state is always replicated on the go
				for j=1, #clients do
					if item_states[clients[j]] == nil then
						replication:update_state_for_client(clients[j], false, { item } )
					elseif subject_states[clients[j]] == nil then
						replication:update_state_for_client(clients[j], false, { subject } )
					end
					
					-- once we're ensured, post the selection message
					clients[j].client.net_channel:post_reliable("ITEM_WIELDED", {
						subject_id = subject.replication.id,
						item_id = item.replication.id,
						wielding_key = msg.wielding_key
					})
				end
			end
		end
	end
end