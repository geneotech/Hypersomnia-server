function handle_damage_message(msg)
	local amount = msg.amount
	local victim = msg.victim

	if victim.health ~= nil then
		if victim.health.hp - amount < 0 then
			amount = victim.health.hp
		end
		
		if amount > 0 then
			victim.health.hp = victim.health.hp - amount
			
			victim.replication:broadcast_reliable(protocol.write_msg("DAMAGE_MESSAGE", {
				victim_id = victim.replication.id,
				amount = amount
			}))
				
			if victim.health.hp <= 0 then
				victim.health.hp = 0
				
				victim.health.on_death(victim)	
			end
		end
	end	
end