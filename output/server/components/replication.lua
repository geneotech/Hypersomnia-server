components.replication = inherits_from()

components.replication.groups = create_enum {
	"PUBLIC",
	"OWNER"
} 


function components.replication:constructor(init)
	self.module_sets = init.module_sets
	
	-- false - out of date
	-- true - up to date
	-- nil - this object was not yet transmitted to a given client
	self.remote_states = {}
end