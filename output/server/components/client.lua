components.client = inherits_from()

function components.client:constructor(init)
	self.guid = init.guid
	
	self.substep_unreliable = BitStream()
	
	self.alternative_modules = {}
	
	set_rate(self, "update", 2)
	
	self.net_channel = reliable_channel_wrapper:create()
end

