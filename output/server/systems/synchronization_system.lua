synchronization_system = inherits_from (processing_system)

function synchronization_system:constructor() 
	self.transmission_id_generator = id_generator_ushort()
	
	processing_system.constructor(self)
end

function synchronization_system:get_required_components()
	return { "synchronization" }
end

function synchronization_system:get_targets_in_proximity(subject_client)
	-- here should follow proximity checks
	return self.targets
end

function synchronization_system:write_object_state(object, output_bs)
	output_bs:name_property("object_id")
	output_bs:WriteUshort(object.synchronization.id)
	
	-- write a bitfield describing what modules have changed
	-- on the first transmission all modules will have changed, inducing their creation on the client
	
	-- now just write all modules
		
	for i=1, #protocol.module_mappings do
		output_bs:name_property("has module " .. i)
		output_bs:WriteBit(object.synchronization.modules[protocol.module_mappings[i]] ~= nil)
	end
	
	local modules = object.synchronization.modules
	
	for i=1, #modules do
		modules[i]:write_state(output_bs)
	end
end

function synchronization_system:update_state_for_client(subject_client)
	local proximity_targets = self:get_targets_in_proximity(subject_client)
	
	if #proximity_targets > 0 then
		local out_of_date = BitStream()
		local num_out_of_date = 0
		
		for i=1, #proximity_targets do
			local states = proximity_targets[i].synchronization.remote_states
			local up_to_date = states[subject_client]
			
			-- if the object was not yet sent through reliable channel or is out of date
			if up_to_date == nil or up_to_date == false then
				self:write_object_state(proximity_targets[i], out_of_date)
				num_out_of_date = num_out_of_date + 1
			
			end			
				states[subject_client] = true
		end
		
		if num_out_of_date > 0 then	
			local output_bs = BitStream()
			
			output_bs:name_property("STATE_UPDATE")
			output_bs:WriteByte(protocol.messages.STATE_UPDATE)
			output_bs:name_property("object_count")
			output_bs:WriteUshort(num_out_of_date)
			output_bs:name_property("all objects")
			output_bs:WriteBitstream(out_of_date)
			
			subject_client.client.net_channel:post_bitstream(output_bs)
		end
	end
end

-- calls module updaters for unreliable sequenced data to stream
function synchronization_system:update_streams_for_client(subject_client, output_bitstream)
	local proximity_targets = self:get_targets_in_proximity(subject_client)
	
	local num_streamed_objects = 0
	
	local streamed_bs = BitStream()
	local object_bs = BitStream()
	
	for i=1, #proximity_targets do
		local sync = proximity_targets[i].synchronization
		local modules = sync.modules
		
		for j=1, #protocol.module_mappings do
			local stream_module = modules[protocol.module_mappings[j]]
			if stream_module ~= nil then
				object_bs:Reset()
				
				stream_module:write_stream(proximity_targets[i], object_bs) 
				
				if object_bs:size() > 0 then
					streamed_bs:name_property("object_id")
					streamed_bs:WriteUshort(sync.id)
					streamed_bs:name_property("object_data")
					streamed_bs:WriteBitstream(object_bs)
					num_streamed_objects = num_streamed_objects + 1
				end
			end
		end
	end
	
	-- if anything needs streaming at all
	if num_streamed_objects > 0 then
		output_bitstream:name_property("STREAM_UPDATE")
		output_bitstream:WriteByte(protocol.messages.STREAM_UPDATE)	
		output_bitstream:name_property("streamed_count")
		output_bitstream:WriteUshort(num_streamed_objects)
		output_bitstream:name_property("streamed objects")
		output_bitstream:WriteBitstream(streamed_bs)
	end
end

function synchronization_system:delete_client_states(removed_client)
	for i=1, #self.targets do
		self.targets[i].synchronization.remote_states[removed_client] = nil
	end
end

function synchronization_system:add_entity(new_entity)
	new_entity.synchronization.id = self.transmission_id_generator:generate_id()
	
	if new_entity.client ~= nil then
		-- post a reliable message with an id of the synchronization object the client will control
		
		local output_bs = BitStream()
		output_bs:name_property("ASSIGN_SYNC_ID")
		output_bs:WriteByte(protocol.messages.ASSIGN_SYNC_ID)
		output_bs:name_property("client_id")
		output_bs:WriteUshort(new_entity.synchronization.id)
		
		new_entity.client.net_channel:post_bitstream(output_bs)
	end
	
	processing_system.add_entity(self, new_entity)
end

function synchronization_system:remove_entity(removed_entity)
	local removed_id = removed_entity.synchronization.id
	
	local output_bs = BitStream()
	output_bs:name_property("DELETE_OBJECT")
	output_bs:WriteByte(protocol.messages.DELETE_OBJECT)
	output_bs:name_property("removed_id")
	output_bs:WriteUshort(removed_id)
	
	print ("removing " .. removed_id) 
	local remote_states = removed_entity.synchronization.remote_states
	
	-- sends delete notification to all clients to whom this object state was reliably sent at least once
	for notified_client, state in pairs(remote_states) do
		print ("sending notification to " .. notified_client.synchronization.id)
		notified_client.client.net_channel:post_bitstream(output_bs)
	end
	
	self.transmission_id_generator:release_id(removed_id)
	processing_system.remove_entity(self, removed_entity)
end

