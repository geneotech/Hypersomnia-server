components.client = inherits_from()

function components.client:constructor(init)
	self.guid = init.guid

	
	self.substep_unreliable = BitStream()
	
	set_rate(self, "update", 66)
	
	self.net_channel = reliable_channel_wrapper:create()
end

