function broadcast_chat_messages(owner_entity_system)
	local msgs = owner_entity_system.messages["CHAT_MESSAGE"]
	local client_sys = owner_entity_system.all_systems.client
	
	for i=1, #msgs do
		local msg = msgs[i]
		
		for j=1, #client_sys.targets do
			client_sys.network:send(protocol.make_reliable_bs(protocol.write_msg("REMOTE_CHAT_MESSAGE", {
					nickname = msg.subject.client.nickname,
					message = msg.data.message
				})), send_priority.IMMEDIATE_PRIORITY, send_reliability.RELIABLE_ORDERED, 0, client_sys.targets[j].client.guid, false)
		end
	end
end