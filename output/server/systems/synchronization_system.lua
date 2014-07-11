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

function synchronization_system:write_object_state(id, module_set, output_bs)
	output_bs:name_property("object_id")
	output_bs:WriteUshort(id)
	
	-- write a bitfield describing what modules have changed
	-- on the first transmission all modules will have changed, inducing their creation on the client
	
	-- now just write all modules
		
	for i=1, #protocol.module_mappings do
		output_bs:name_property("has module " .. i)
		
		local module_object = module_set[protocol.module_mappings[i]]
		
		output_bs:WriteBit(module_object ~= nil)
		
		if module_object ~= nil then
			module_object:write_state(output_bs)
		end
	end
end

function synchronization_system:update_state_for_client(subject_client)
	local proximity_targets = self:get_targets_in_proximity(subject_client)
	
	if #proximity_targets > 0 then
		local out_of_date = BitStream()
		local num_out_of_date = 0
		
		for i=1, #proximity_targets do
			local target = proximity_targets[i]
			local sync = target.synchronization
			local id = sync.id
			local states = sync.remote_states
			local up_to_date = states[subject_client]
			
			-- if the object was not yet sent through reliable channel or is out of date
			if up_to_date == nil or up_to_date == false then
				-- switch to an alternative module set if the client component provides one
				local alternative_modules = subject_client.client.alternative_modules[id]
				
				if alternative_modules ~= nil then
					self:write_object_state(id, alternative_modules, out_of_date)
				else
					self:write_object_state(id, sync.modules, out_of_date)
				end
			
				num_out_of_date = num_out_of_date + 1
			
			end			
				states[subject_client] = true
		end
		
		if num_out_of_date > 0 then	
			local output_bs = protocol.write_msg("STATE_UPDATE", {
				object_count = num_out_of_date
			})
			
			output_bs:name_property("all objects")
			output_bs:WriteBitstream(out_of_date)
			
			subject_client.client.net_channel:post_reliable_bs(output_bs)
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
		local modules = sync.modules;
		local alternative_modules = subject_client.client.alternative_modules[sync.id]
		
		if alternative_modules ~= nil then
			modules = alternative_modules
		end
		
		object_bs:Reset()
		
		for j=1, #protocol.module_mappings do
			local stream_module = modules[protocol.module_mappings[j]]
			if stream_module ~= nil then		
				stream_module:write_stream(proximity_targets[i], object_bs)
			end
		end
		
		if object_bs:size() > 0 then
			streamed_bs:name_property("object_id")
			streamed_bs:WriteUshort(sync.id)
			streamed_bs:name_property("object_data")
			streamed_bs:WriteBitstream(object_bs)
			num_streamed_objects = num_streamed_objects + 1
		end
	end
	
	-- if anything needs streaming at all
	if num_streamed_objects > 0 then
		local output_bs = protocol.write_msg("STREAM_UPDATE", {
			object_count = num_streamed_objects
		})
		
		output_bs:name_property("streamed objects")
		output_bs:WriteBitstream(streamed_bs)
		output_bitstream:WriteBitstream(output_bs)
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
		new_entity.client.net_channel:post_reliable("ASSIGN_SYNC_ID", { sync_id = new_entity.synchronization.id })
	end
	
	processing_system.add_entity(self, new_entity)
end

function synchronization_system:remove_entity(removed_entity)
	local removed_id = removed_entity.synchronization.id
	
	print ("removing " .. removed_id) 
	local remote_states = removed_entity.synchronization.remote_states
	
	local out_bs = protocol.write_msg("DELETE_OBJECT", { ["removed_id"] = removed_id } )
	-- sends delete notification to all clients to whom this object state was reliably sent at least once
	
	local new_remote_states = clone_table(remote_states)
	
	for notified_client, state in pairs(remote_states) do
		print ("sending notification to " .. notified_client.synchronization.id)
		notified_client.client.net_channel:post_reliable_bs(out_bs)
		new_remote_states[notified_client] = nil
	end
	
	removed_entity.synchronization.remote_states = new_remote_states
	
	-- just in case, remove all occurences of alternative modulesets in connected clients
	-- this is necessary in case an object without alternative moduleset was created
	-- and still the old alternative module set could be accessed
	
	local targets = self.owner_entity_system.all_systems["client"].targets
	
	for i=1, #targets do
		targets[i].client.alternative_modules[removed_id] = nil
	end
	
	self.transmission_id_generator:release_id(removed_id)
	processing_system.remove_entity(self, removed_entity)
end

