components.replication = inherits_from()

components.replication.groups = create_enum {
	"PUBLIC",
	"OWNER"
} 


function components.replication:constructor(init)
	self.module_sets = init.module_sets
	
	-- maps a client to its current replication group
	-- nil - this object was not yet transmitted to a given client
	self.remote_states = {}
	
	self.public_group_name = init.public_group_name 
	
	if self.public_group_name == nil then
		self.public_group_name = "PUBLIC"
	end 
	
	-- maps a wielding key to a sub entity
	self.sub_entities = {}
	
	if init.upload_rate then
		set_rate(self, "upload", init.upload_rate)
	end
end