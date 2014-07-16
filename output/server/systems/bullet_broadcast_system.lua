bullet_broadcast_system = inherits_from (processing_system)


function bullet_broadcast_system:translate_shot_requests()
	local msgs = self.owner_entity_system.messages["SHOT_REQUEST"]
	
	--if #msgs > 0 then
	--	print(#msgs)
	--end
	
	for i=1, #msgs do
		--print "received shot data"
		
		table.insert(msgs[i].subject.weapon.buffered_actions, { trigger = components.weapon.triggers.SHOOT, premade_shot = {
			position = msgs[i].data.position,
			rotation = msgs[i].data.rotation
		}})
	end
end


function bullet_broadcast_system:broadcast_bullets()
	local msgs = self.owner_entity_system.messages["shot_message"]
	
	for i=1, #msgs do
	
		-- here, we should perform a proximity check for the processed bullet(s)
		local subject = msgs[i].subject
		
		local all_clients = self.owner_entity_system.all_systems["client"].targets
		
		for j=1, #all_clients do
			local remote_id = all_clients[j].synchronization.id
			print(subject.synchronization.id, remote_id)
			if subject.synchronization.id ~= remote_id then
				print ("sending shot to" .. remote_id)
				all_clients[j].client.net_channel:post_reliable("SHOT_INFO", {
					subject_id = subject.synchronization.id,
					position = msgs[i].gun_transform.pos,
					rotation = msgs[i].gun_transform.rotation
				})
			end
			
		end
	end
end