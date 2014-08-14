inventory_system = inherits_from (processing_system)

function inventory_system:get_required_components()
	return { "inventory" }
end

function inventory_system:handle_item_requests()
	--local msgs = self.owner_entity_system.messages["PICK_ITEM_REQUEST"]
	--
	--for i=1, #msgs do
	--	local msg = msgs[i]
	--	local subject = msg.subject
	--	local item = msg.item
	--	
	--	local inventory = subject.inventory
	--	
	--	inventory.available_items[item.replication.id] = item
	--end
end


function inventory_system:translate_item_events()
	local msgs = self.owner_entity_system.messages["pick_item"]
	
	for i=1, #msgs do
		local msg = msgs[i]
		local subject = msg.subject
		local item = msg.item
		
		local inventory = subject.inventory
		
		-- don't longer replicate it in the public space
		item.item:pick()
		item.item.owner_inventory = subject
		inventory.available_items[item.replication.id] = item
		
		-- not need for any kind of notification - unreplicated object will simply be deleted remotely
	end
	
	msgs = self.owner_entity_system.messages["drop_item"]
	
	for i=1, #msgs do
		local msg = msgs[i]
		local item = msg.item
		
		local wielder = item.item.wielder
		
		if wielder then
			self.owner_entity_system:post_table("wield_item", {
				subject = wielder,
				item = nil
			})
		end
		
		if msg.owner_inventory then
			msg.owner_inventory.inventory[item.replication.id] = nil
		end
		
		item.item:drop()
	end
end


function inventory_system:handle_drop_requests()
	local msgs = self.owner_entity_system.messages["drop_item"]
	
	for i=1, #msgs do
		local msg = msgs[i]
		local item = msg.item
		
		item.item:drop()
	end
end


function inventory_system:broadcast_item_events()
	msgs = self.owner_entity_system.messages["drop_item"]
	
	for i=1, #msgs do
		local msg = msgs[i]
		local item = msg.item
		
		local wielder = item.item.wielder
		
		if wielder ~= nil then
			wielder.replication.sub_entities["ITEM_ENTITY"] = nil
							
			if wielder.client_controller ~= nil then
				item.replication:clear_group_for_client(wielder.client_controller.owner_client)
			end
		end
		
		item.replication:switch_public_group("DROPPED_PUBLIC")
		
		-- the item will be replicated on the next update as DROPPED_PUBLIC.
		-- so we don't need to tell the clients about the DROP itself,
		-- as they don't have to know where does the item come from.
	end
end