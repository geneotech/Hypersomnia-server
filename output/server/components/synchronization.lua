components.synchronization = inherits_from()

function components.synchronization:constructor(init)
	self.modules = init.modules
	
	-- false - out of date
	-- true - up to date
	-- nil - this object was not yet transmitted to a given client
	self.remote_states = {}
end