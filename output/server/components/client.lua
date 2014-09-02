components.client = inherits_from()

function components.client:constructor(init)
	self.guid = init.guid
	
	self.substep_unreliable = BitStream()
	
	-- defaults to "PUBLIC"
	self.group_by_id = {}
	
	self.one_time_AoI = {}
	
	self.local_bullet_id_to_global = {}
	self.next_bullet_local_id = 1
	
	set_rate(self, "update", 60)
	
	self.net_channel = reliable_channel_wrapper:create()
	
	self.previous_targets_of_interest = {}
	
	self.nickname = init.nickname
end

