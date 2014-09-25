inventory_system = inherits_from (processing_system)

function inventory_system:get_required_components()
	return { "inventory" }
end

function inventory_system:get_item_in_range(physics_system, what_entity, try_to_pick_weapon)
	local filter = create_query_filter({ "DROPPED_ITEM" })
	local items_in_range = physics_system:query_body(what_entity, filter, nil)
	
	local found_item;
	
	for candidate in items_in_range.bodies do
		if try_to_pick_weapon == nil or (try_to_pick_weapon ~= nil and body_to_entity(candidate) == try_to_pick_weapon) then 
			found_item = body_to_entity(candidate).script
			break
		end
	end
	
	return found_item
end

-- netcode
-- request translated into game events
function inventory_system:handle_request(msg, world_object)
	local replication = self.owner_entity_system.all_systems["replication"]
	
	local subject = msg.subject
	local character = subject.client.controlled_object
	
	local subject_inventory = character.wield.wielded_items[components.wield.keys.INVENTORY]
	
	local exclude_client;
	if character.client_controller then
		exclude_client = character.client_controller.owner_client
	end
		
	local currently_wielded_item = character.wield.wielded_items[components.wield.keys.PRIMARY_WEAPON]
	local to_be_processed_later = currently_wielded_item and not currently_wielded_item.item.can_be_unwielded(currently_wielded_item)
	
	if msg.name == "SELECT_ITEM_REQUEST" then
		self.owner_entity_system:post_table("select_item", {
			subject = character,
			item_id = msg.data.item_id,
			["exclude_client"] = exclude_client
		})
	elseif msg.name == "HOLSTER_ITEM" then
		self.owner_entity_system:post_table("holster_item", {
			subject = character,
			["exclude_client"] = exclude_client
		})
	elseif msg.name == "DROP_ITEM_REQUEST" and currently_wielded_item and currently_wielded_item.replication.id == msg.data.item_id then
		self.owner_entity_system:post_table("drop_item", {
			subject = character,
			["exclude_client"] = exclude_client
		})
	elseif msg.name == "PICK_ITEM_REQUEST" then
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
	elseif msg.name == "DROP_ITEM_REQUEST" then
		self.owner_entity_system:post_table("drop_item", {
			subject = character,
			item_id = msg.data.item_id,
			["exclude_client"] = exclude_client
		})
	end
end

function inventory_system:handle_drop_item(msg)
	local subject = msg.subject
	local subject_inventory = subject.wield.wielded_items[components.wield.keys.INVENTORY]
	
	if msg.item_id then
		local found_item = subject_inventory.wield.wielded_items[msg.item_id]
		
		if found_item then
			self.owner_entity_system:post_table("item_wielder_change", { 
				unwield = true,
				subject = subject_inventory,
				wielding_key = found_item.replication.id,
				
				["exclude_client"] = msg.exclude_client 
			})
		end
	else
		self.owner_entity_system:post_table("item_wielder_change", { 
			unwield = true,
			["subject"] = subject,
			wielding_key = components.wield.keys.PRIMARY_WEAPON,
				
			["exclude_client"] = msg.exclude_client 
		})
	end
end

function inventory_system:handle_holster_item(msg)
	local subject = msg.subject
	local subject_inventory = subject.wield.wielded_items[components.wield.keys.INVENTORY]
	local found_item = subject.wield.wielded_items[components.wield.keys.PRIMARY_WEAPON]
	
	if found_item then
		self:holster_item(subject_inventory, subject, found_item, nil, msg.exclude_client)
	end
end

function inventory_system:handle_select_item(msg)
	local subject = msg.subject
	local subject_inventory = subject.wield.wielded_items[components.wield.keys.INVENTORY]
	local found_item = subject_inventory.wield.wielded_items[msg.item_id]
	
	if found_item then
		print "SELECTING!"
		self:select_item(subject_inventory, subject, found_item, nil, msg.exclude_client)
	end
end

function inventory_system:handle_pick_item(msg)
	local subject = msg.subject
	local item = msg.item
	
	local subject_inventory = subject.wield.wielded_items[components.wield.keys.INVENTORY]
	
	self.owner_entity_system:post_table("item_wielder_change", {
		subject = subject_inventory,
		item = msg.item,
		wield = true,
		wielding_key = item.replication.id
	})
end