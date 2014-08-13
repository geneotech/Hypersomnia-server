inventory_system = inherits_from (processing_system)

--function wield_system:constructor(world_object)
--	self.world_object = world_object
--	processing_system.constructor(self)
--end

--function wield_system:add_entity(new_entity)
--	if new_entity.replication ~= nil then
--		new_entity.replication.
--	end
--end

--function wield_system:remove_entity(removed_entity)
--	-- if we wield an item, we may need to drop it
--	
--	-- THIS IS THE GAME LOGIC THAT SHOULD DECIDE IF THE OBJECT IS TO BE DROPPED,
--	-- AND IF SO, IT SHOULD POST A DROP MESSAGE BEFORE POSTING DELETION OF THE OBJECT
--	
--	-- IF THE ITEM ISN'T DROPPED, IT IS SIMPLY DELETED
--	if removed_entity.wield.wielded_item ~= nil then
--		self.owner_entity_system:remove_entity(removed_entity.wield.wielded_item)
--	end
--	
--	--processing_system.remove_entity(self, removed_entity)
--end
--
function inventory_system:get_required_components()
	return { "inventory" }
end

function inventory_system:translate_drop_requests()
	local msgs = self.owner_entity_system.messages["drop_item"]
	
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