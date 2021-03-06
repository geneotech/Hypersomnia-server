function wield_system:broadcast_changes(msg)
	if msg.succeeded == true then
	
		local replication = self.owner_entity_system.all_systems["replication"]
		local subject = msg.subject
		local item = msg.item
		local owner_client;
		
		if subject.client_controller then
			owner_client = subject.client_controller.owner_client
		end
			
		if msg.unwield and subject.replication then
			subject.replication.sub_entities[msg.wielding_key] = nil
			--item.replication:switch_public_group("DROPPED_PUBLIC")
			
			if owner_client then
				item.replication:clear_group_for_client(owner_client)
			end
			
			-- if we UNSELECTED an item, only the clients seeing the subject are interested
			for client_entity, v in pairs(subject.replication.remote_states) do
				if not msg.exclude_client or client_entity ~= msg.exclude_client then
					client_entity.client.net_channel:post_reliable("ITEM_UNWIELDED", {
						subject_id = subject.replication.id,
						wielding_key = msg.wielding_key
					})
				end
			end
		elseif msg.wield and item.replication and subject.replication then
			local subject_states = subject.replication.remote_states
			subject.replication.sub_entities[msg.wielding_key] = item
			
			local wield = subject.wield
			local item_states = item.replication.remote_states
			
			-- get all clients who see either the item or the subject
			local clients = {}
			
			for client_entity, v in pairs(item_states) do
				if not msg.exclude_client or client_entity ~= msg.exclude_client then
					clients[client_entity] = true
				end
			end
			
			for client_entity, v in pairs(subject_states) do
				if not msg.exclude_client or client_entity ~= msg.exclude_client then
					clients[client_entity] = true
				end
			end
			
			-- if either the item or the subject is invisible to the client,
			-- post a creation message immediately
			
			-- remember that the initial state is always replicated on the go
			for client in pairs(clients) do
				-- either way we have to create the whole subject with all of its subentities,
				-- the item included
				if item_states[client] == nil or subject_states[client] == nil then
					replication:update_state_for_client(client, false, { subject } )
				end
				
				-- it may happen that we couldn't replicate some of them, because
				-- the client has no access to some either of the objects
				
				-- this happens for example for a client seeing somebody switching/holstering a weapon,
				-- where he can't see the inventory that the item is wielded by
				
				-- once we're ensured, post the selection message
				if item_states[client] and subject_states[client] then
					client.client.net_channel:post_reliable("ITEM_WIELDED", {
						subject_id = subject.replication.id,
						item_id = item.replication.id,
						wielding_key = msg.wielding_key
					})
				end
			end
		end
	end
end