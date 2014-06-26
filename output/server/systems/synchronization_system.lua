synchronization_system = inherits_from (processing_system)

function synchronization_system:constructor() 
	self.transmission_id_generator = id_generator_uint()
	
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
	WriteUint(output_bs, object.synchronization.id)
	
	-- write a bitfield describing what modules the entity has
	for i=1, #protocol.module_mappings do
		WriteBit(output_bs, bool2int(object.synchronization.modules[protocol.module_mappings[i]] ~= nil))
	end
	
	local modules = object.synchronization.modules
	
	for i=1, #modules do
		modules[i]:update_state(output_bs)
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
			
			-- outcome is always true
			states[subject_client] = true
		end
		
		if num_out_of_date > 0 then	
			local output_bs = BitStream()
			
			WriteByte(output_bs, protocol.messages.STATE_UPDATE)
			WriteUshort(output_bs, num_out_of_date)
			WriteBitstream(output_bs, out_of_date)
			
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
		
		for j=1, #modules do
			object_bs:Reset()
			
			modules[j]:update_stream(subject_client, object_bs) 
			
			if object_bs:size() > 0 then
				WriteUint(streamed_bs, sync.id)
				WriteBitstream(streamed_bs, object_bs)
				num_streamed_objects = num_streamed_objects + 1
			end
		end
	end
	
	-- if anything needs streaming at all
	if num_streamed_objects > 0 then
		WriteUshort(output_bitstream, num_streamed_objects)
		WriteBitstream(output_bitstream, streamed_bs)
	end
end

function synchronization_system:delete_client_states(removed_client)
	for i=1, #self.targets do
		self.targets[i].synchronization.remote_states[removed_client] = nil
	end
end

function synchronization_system:add_entity(new_entity)
	new_entity.synchronization.id = self.transmission_id_generator:generate_id()
	processing_system.add_entity(self, removed_entity)
end

function synchronization_system:remove_entity(removed_entity)
	local removed_id = removed_entity.synchronization.id

	local output_bs = BitStream()
	WriteByte(output_bs, protocol.message.DELETE_OBJECT)
	WriteUint(output_bs, removed_id)
	
	local remote_states = removed_entity.synchronization.remote_states
	
	-- sends delete notification to all clients to whom this object state was reliably sent at least once
	for notified_client, state in pairs(remote_states) do
		notified_client.client.net_channel:post_bitstream(output_bs)
	end
	
	self.transmission_id_generator:release_id(removed_id)
	processing_system.remove_entity(self, removed_entity)
end

