bullet_broadcast_system = inherits_from (processing_system)


function bullet_broadcast_system:translate_shot_requests()
	local msgs = self.owner_entity_system.messages["SHOT_REQUEST"]
	
	for i=1, #msgs do
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
		
		local client_sys = self.owner_entity_system.all_systems["client"]
		local all_clients = client_sys.targets
		
		for j=1, #all_clients do
			local remote_id = all_clients[j].synchronization.id
			if subject.synchronization.id ~= remote_id then
				all_clients[j].client.net_channel:post_reliable("SHOT_INFO", {
					subject_ping = client_sys.network:get_last_ping(subject.client.guid),
					subject_id = subject.synchronization.id,
					position = msgs[i].gun_transform.pos,
					rotation = msgs[i].gun_transform.rotation
				})
			end
			
		end
	end
end