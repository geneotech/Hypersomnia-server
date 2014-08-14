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
	--local msgs = self.owner_entity_system.messages["PICK_REQUEST"]
	
	--for i=1, #msgs do
	--	local msg = msgs[i]
	--	local subject = msg.subject
	--	local character = subject.client.controlled_object
	--	
	--	if character ~= nil then
	--		local wield = character.wield
	--		if wield ~= nil then
	--			--local found_item = self:get_item_in_range(world_object.physics_system, character.cpp_entity)
	--			--
	--			---- subject validity ensured here
	--			--if wield.wielded_item ~= nil then
	--			--	self.owner_entity_system:post_table("wield_item", {
	--			--		subject = character,
	--			--		drop = true
	--			--	})
	--			--end
	--		    --
	--			--if found_item then
	--			--	self.owner_entity_system:post_table("wield_item", {
	--			--		subject = character,
	--			--		item = found_item,
	--			--		pick = true
	--			--	})
	--			--end
	--		end
	--	end
	--end
end

function wield_system:broadcast_item_selections()
	local msgs = self.owner_entity_system.messages["wield_item"]
	local replication = self.owner_entity_system.all_systems["replication"]
	
	for i=1, #msgs do
		local msg = msgs[i]
		if msg.succeeded == true then
			local subject = msg.subject
		
			local item = msg.item
			
			subject.replication.sub_entity_groups.WIELDED_ENTITIES[msg.wielding_key] = item
			
			local subject_states = subject.replication.remote_states
			
			local wield = subject.wield
			local item_states = item.replication.remote_states
			
			item.replication:switch_public_group("OWNED_PUBLIC")
			
			-- inventory system uses the same group, so if we have an inventory component,
			-- OWNER group will already be set upon the item being picked and this call will have no effect
			
			-- alternatively, should we want to have different groups for a wielded object
			-- and an object residing in the inventory, the inventory system will loop through successful
			-- wielder changes and set its own group there
			if subject.client_controller then	
				item.replication:switch_group_for_client("OWNER", subject.client_controller.owner_client)
			end	
			
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
			
			-- subject's subentity "ITEM_ENTITY" is already overwritten with nil or the newly selected item
			-- the previously wielded item won't longer be replicated and if it will be in the future,
			-- it is only by posting drop_item/wield_item message and thus
			-- it will be assigned a meaningful replication group on the go
			
			-- or it may be replicated in the inventory - in such a case, it is the inventory_system's responsibility
			-- to set a meaningful group upon putting an item to the inventory
		end
	end
	
	local msgs = self.owner_entity_system.messages["unwield_item"]
	
	for i=1, #msgs do
		local msg = msgs[i]
		if msg.succeeded == true then
			local subject = msg.subject
			local item = msg.item
		
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
		end
	end
end