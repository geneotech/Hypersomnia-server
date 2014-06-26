client_system = inherits_from (processing_system)

function client_system:constructor(network) 
	self.network = network
	
	processing_system.constructor(self)
end

function client_system:get_required_components()
	return { "client" }
end

function client_system:remove_entity(removed_entity)
	self.owner_entity_system.all_systems["synchronization"]:delete_client_states(removed_entity)
	processing_system.remove_entity(self, removed_entity)
end

function client_system:update()
	local synchronization = self.owner_entity_system.all_systems["synchronization"]

	-- first handle the messages
	local msgs = self.owner_entity_system.messages["network_message"]
	
	for i=1, #msgs do
		local client = msgs[i].subject.client
		local data = msgs[i].data
		
		local input_bs = data:get_bitstream()
		
		-- for now, all incoming network messages will redundantly contain an ack sequence
		-- receive acknowledgement for server->client reliable channel
		client.reliable_sender.channel:read_ack(input_bs)
		
		-- read sequence for client->server reliable channel
		local recv_result = client.reliable_receiver:read_sequence(input_bs)
		
		-- if there are some commands to be read from the client
		if recv_result == receive_result.RELIABLE_RECEIVED then
			-- now that the acknowledgement is read from the bitstream,
			-- the other systems will process a bitstream containing only messages from client->server reliable channel
			self.entity_system_instance:post( client_commands:create { 
				subject = msgs[i].subject,
				command_bitstream = input_bs
			})	
			
			-- we must send an acknowledgement on the next tick
			client.ack_requested = true
			-- now read unreliable messages if any
		elseif recv_result == receive_result.ONLY_UNRELIABLE_RECEIVED then
			-- read unreliable messages
		end	
		
	end

	for i=1, #self.targets do
		local client = self.targets[i].client
		
		if client.update_timer:get_milliseconds() > client.update_interval_ms then
			client.update_timer:reset()
			
			-- right away handles sending initial state for newly-connected clients
			-- updates states of changing (or new) objects in proximity
			-- may post some reliable messages to the client component
			synchronization:update_state_for_client(self.targets[i])
			
			-- streams may post a reliable event: "sleep" event for example
			client.reliable_sender.unreliable_buf:Reset()
			synchronization:update_streams_for_client(self.targets[i], client.reliable_sender.unreliable_buf)
			
			local output_bs = BitStream()
			
			-- if there is anything new going on or we have just got a reliable command from the client, 
			-- send updates over UDP/IP
			if client.ack_requested or client.reliable_sender.channel:write_data(output_bs) then
				-- redundantly send acknowledgement for the client->server reliable channel
				local final_bs = BitStream()
				client.reliable_receiver:write_ack(final_bs)
				client.ack_requested = false
				
				WriteBitstream(final_bs, output_bs)
				
				self.network:send(final_bs, send_priority.IMMEDIATE_PRIORITY, send_reliability.UNRELIABLE, 0, client.guid, false)
			end
			
		end
	end
end

