dofile (CLIENT_CODE_DIRECTORY .. "scripts\\reliable_channel.lua")

client_system = inherits_from (processing_system)

function client_system:constructor(network)
	self.network = network
	self.global_timer = timer()
	
	processing_system.constructor(self)
end

function client_system:get_required_components()
	return { "client" }
end

function client_system:remove_entity(removed_entity)
	processing_system.remove_entity(self, removed_entity)
	
	self.owner_entity_system.all_systems["replication"]:delete_client_states(removed_entity)
	
	if removed_entity.client.controlled_object ~= nil then
		self.owner_entity_system:remove_entity(removed_entity.client.controlled_object)
	end
end

function client_system:substep()
	for i=1, #self.targets do
		self.targets[i].client.substep_unreliable:Reset()
	end
end


function client_system:update_replicas_and_states()
	local replication = self.owner_entity_system.all_systems["replication"]
	
	replication:update_replicas()
	
	for i=1, #self.targets do
		-- right away handles sending initial state for newly-connected clients
		-- updates states of changing (or new) objects in proximity
		-- may post some reliable messages to the client component
		replication:update_state_for_client(self.targets[i])
	end
end


function client_system:send_all_pending_data()
	for i=1, #self.targets do	
		local client = self.targets[i].client
		
		-- write all unreliable data that substeps requested
		client.net_channel:post_unreliable_bs(client.substep_unreliable)
		
		if client.net_channel:has_something_to_send() 
		and client.net_channel.last_reliable_msg_type ~= "LOOP_SEPARATOR" then
			client.net_channel:post_reliable("LOOP_SEPARATOR", {})
		end
		
		local output_bs = client.net_channel:send()
		
		if output_bs:size() > 0 then
			--if client.net_channel.sender.reliable_buf:size() > 0 then
			--print "Sending data..."
			local outstr = ("\nSending time: " .. self.global_timer:get_milliseconds() .. " (size: " .. output_bs:size() .. " bits) \n\n" .. auto_string_indent(output_bs.content) .. "\n\n")
			transmission_log:write(outstr)
			--print(outstr)
			--end
			
			self.network:send(output_bs, send_priority.IMMEDIATE_PRIORITY, send_reliability.UNRELIABLE, 0, client.guid, false)
		end
	end
end
