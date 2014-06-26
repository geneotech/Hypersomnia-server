components.client = inherits_from()

function components.client:constructor(init)
	self.guid = init.guid

	self:set_rate("update", 30)
	
	-- succesfully read a reliable set of commands;
	-- send an acknowledgement on the next update even if there is no data to send.
	self.ack_requested = false
	
	self.update_timer = timer()
	
	self.reliable_sender = reliable_sender_class:create()
	self.reliable_receiver = reliable_receiver()
end

function components.client:set_rate(what_rate, updates_per_second)
	self[what_rate .. "_rate"] = updates_per_second
	self[what_rate .. "_interval_ms"] = 1000/updates_per_second
end
