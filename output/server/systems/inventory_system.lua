inventory_system = inherits_from (processing_system)

function inventory_system:get_required_components()
	return { "inventory" }
end

function inventory_system:get_item_in_range(physics_system, what_entity, try_to_pick_weapon)
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

function inventory_system:handle_item_requests(world_object)
	local msgs = self.owner_entity_system.messages["INVENTORY_REQUESTS"]
	local replication = self.owner_entity_system.all_systems["replication"]
	
	for i=1, #msgs do
		local msg = msgs[i]
		local subject = msg.subject
		local character = subject.client.controlled_object
		local subject_inventory = character.wield.wielded_items[components.wield.keys.INVENTORY]
		
		local exclude_client;
		if character.client_controller then
			exclude_client = character.client_controller.owner_client
		end
		
		if msg.name == "PICK_ITEM_REQUEST" then
			if character ~= nil then
				local wield = character.wield
				if wield ~= nil then
					-- subject validity ensured here
					local found_item = self:get_item_in_range(world_object.physics_system, character.cpp_entity)
					
					--
					--if wield.wielded_item ~= nil then
					--	self.owner_entity_system:post_table("wield_item", {
					--		subject = character,
					--		drop = true
					--	})
					--end
					--
					if found_item then
						self.owner_entity_system:post_table("pick_item", {
							subject = character,
							item = found_item
						})
					end
				end
			end
		elseif msg.name == "SELECT_ITEM_REQUEST" then
			local found_item = subject_inventory.wield.wielded_items[msg.data.item_id]
			
			if found_item then
				self:select_item(subject_inventory, character, found_item, nil, exclude_client)
			end
		elseif msg.name == "HOLSTER_ITEM" then
			local found_item = character.wield.wielded_items[components.wield.keys.PRIMARY_WEAPON]
			
			if found_item then
				self:holster_item(subject_inventory, character, found_item, nil, exclude_client)
			end
		end
	end
end

function inventory_system:translate_item_events()
	local msgs = self.owner_entity_system.messages["pick_item"]
	
	for i=1, #msgs do
		local msg = msgs[i]
		local subject = msg.subject
		local item = msg.item
		
		local inventory_subject = subject.wield.wielded_items[components.wield.keys.INVENTORY]
		local inventory = inventory_subject.inventory
	
		self.owner_entity_system:post_table("item_wielder_change", {
			subject = inventory_subject,
			item = msg.item,
			wield = true,
			wielding_key = item.replication.id
		})
	end
	
	--msgs = self.owner_entity_system.messages["drop_item"]
	--
	--for i=1, #msgs do
	--	local msg = msgs[i]
	--	local item = msg.item
	--	
	--	local wielder = item.item.wielder
	--	
	--	if wielder then
	--		self.owner_entity_system:post_table("wield_item", {
	--			subject = wielder,
	--			item = nil
	--		})
	--	end
	--	
	--	if msg.owner_inventory then
	--		msg.owner_inventory.inventory[item.replication.id] = nil
	--	end
	--	
	--	item.item:drop()
	--end
end


--function inventory_system:handle_drop_requests()
--	local msgs = self.owner_entity_system.messages["drop_item"]
--	
--	for i=1, #msgs do
--		local msg = msgs[i]
--		local item = msg.item
--		
--		item.item:drop()
--	end
--end