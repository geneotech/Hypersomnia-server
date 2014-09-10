function clients(script_str)
	local client_sys = server.systems.client
	
	for j=1, #client_sys.targets do
		local client = client_sys.targets[j]
		
		local out_msg = {
			script = script_str
		}
	
		client_sys.network:send(protocol.make_reliable_bs(protocol.write_msg("REMOTE_COMMANDS", out_msg)), 
			send_priority.IMMEDIATE_PRIORITY, send_reliability.RELIABLE_ORDERED, 0, client.client.guid, false)
	end
end

function nick(nick_str)
	local client_sys = server.systems.client
	 
	for j=1, #client_sys.targets do
		if wstr_eq(towchar_vec(nick_str), client_sys.targets[j].client.nickname) then
			return client_sys.targets[j].client.controlled_object
		end
	end
end

function ApplyLinearImpulseCenter(body, vec)
	body:ApplyLinearImpulse(vec, body:GetWorldCenter(), true)
end

function broadcast_chat_messages(owner_entity_system)
	local msgs = owner_entity_system.messages["CHAT_MESSAGE"]
	local client_sys = owner_entity_system.all_systems.client
	
	for i=1, #msgs do
		local msg = msgs[i]
		
		if wstr_eq_n(towchar_vec("!call"), msg.data.message, string.len("!call")) then
			print "COMMAND CALLED!"
		
			local outstr = string.sub (wchar_vec_to_str(msg.data.message), 6)
			print (outstr)
			local compiled_script = loadstring (outstr)
			if compiled_script then 
				local status, err = pcall(function() compiled_script () end) 
				print(err) 
			end
		else
			for j=1, #client_sys.targets do
				local client = client_sys.targets[j]
				
				local out_msg = {
					nickname = msg.subject.client.nickname,
					message = msg.data.message 
				}
				
				if client.client.controlled_object then
					out_msg.optional_object_id = client.client.controlled_object.replication.id
				end
			
				client_sys.network:send(protocol.make_reliable_bs(protocol.write_msg("REMOTE_CHAT_MESSAGE", out_msg)), 
					send_priority.IMMEDIATE_PRIORITY, send_reliability.RELIABLE_ORDERED, 0, client.client.guid, false)
			end
		end
	end
end