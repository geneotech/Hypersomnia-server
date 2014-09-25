components.client_controller = inherits_from()

function components.client_controller:constructor(init)
	self.buffered_actions = {}
	
	self.buffered_movement = {}
	self.at_step = 0
	self.owner_client = init.owner_client
end