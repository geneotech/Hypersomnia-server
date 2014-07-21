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

function bullet_broadcast_system:invalidate_old_bullets(weapon)
	for k, v in pairs(weapon.existing_bullets) do
		if v.lifetime:get_milliseconds() > weapon.max_lifetime_ms then
			weapon.existing_bullets[k] = nil
			print "invalidating"
		end
	end
end

function bullet_broadcast_system:handle_hit_requests()
	local msgs = self.owner_entity_system.messages["HIT_REQUEST"]
	
	local objects = self.owner_entity_system.all_systems["synchronization"].object_by_id
	
	for i=1, #msgs do
		print "received hit request"
		print (msgs[i].data.bullet_id)
		print (msgs[i].data.victim_id)
		print (msgs[i].subject.weapon.existing_bullets[msgs[i].data.bullet_id] ~= nil)
		print (objects[msgs[i].data.victim_id] ~= nil)
		
		local msg = msgs[i]
		local subject = msg.subject
		
		self:invalidate_old_bullets(subject.weapon)
		
		local bullet_id = msg.data.bullet_id
		local existing_bullets = subject.weapon.existing_bullets
		local victim = objects[msg.data.victim_id]
		
		if victim ~= nil and existing_bullets[bullet_id] ~= nil then
			print ("broadcasting")
			-- broadcast the fact of hitting
		
			-- here, we should perform a proximity check for the parties interested in the hit
			
			local all_clients = self.owner_entity_system.all_systems["client"].targets
		
			print (#all_clients)
			for j=1, #all_clients do
				-- don't tell about it to the sender himself
				print(subject.synchronization.id, all_clients[j].synchronization.id)
				if subject.synchronization.id ~= all_clients[j].synchronization.id then
					-- sending
					print "sending"
					all_clients[j].client.net_channel:post_reliable("HIT_INFO", {
						sender_id = subject.synchronization.id,
						victim_id = victim.synchronization.id,
						["bullet_id"] = bullet_id
					})
				end
			end
		
			existing_bullets[bullet_id] = nil
		end
	end
end

function bullet_broadcast_system:broadcast_bullets()
	local msgs = self.owner_entity_system.messages["shot_message"]
	
	for i=1, #msgs do
		-- here, we should perform a proximity check for the processed bullet(s)
		local subject = msgs[i].subject
		local weapon = subject.weapon
		
		-- invalidate old bullets as we go
		self:invalidate_old_bullets(weapon)
		
		-- save all new bullets for later invalidation
		-- and hit request handling
		for j=1, #msgs[i].bullets do
			weapon.existing_bullets[msgs[i].bullets[j].id] = {
				lifetime = timer()	
			}
		end
		
		local client_sys = self.owner_entity_system.all_systems["client"]
		local all_clients = client_sys.targets
		
		for j=1, #all_clients do
			local remote_id = all_clients[j].synchronization.id
			if subject.synchronization.id ~= remote_id then
				print(subject.client:update_time_remaining())
				local remaining = all_clients[j].client:update_time_remaining()
				if remaining < 0 then remaining = 0 end
				all_clients[j].client.net_channel:post_reliable("SHOT_INFO", {
					delay_time = client_sys.network:get_last_ping(subject.client.guid)/2 + remaining,
					subject_id = subject.synchronization.id,
					position = msgs[i].gun_transform.pos,
					rotation = msgs[i].gun_transform.rotation
				})
			end
			
		end
	end
end