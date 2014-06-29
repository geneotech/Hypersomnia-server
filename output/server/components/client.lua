components.client = inherits_from()

function components.client:constructor(init)
	self.guid = init.guid

	self:set_rate("update", 30)
	
	self.update_timer = timer()
	
	self.net_channel = reliable_channel_wrapper:create()
end

function components.client:set_rate(what_rate, updates_per_second)
	self[what_rate .. "_rate"] = updates_per_second
	self[what_rate .. "_interval_ms"] = 1000/updates_per_second
end
