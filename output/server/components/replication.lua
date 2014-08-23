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
	
	self.public_group_name = init.public_group_name 
	
	if self.public_group_name == nil then
		self.public_group_name = "PUBLIC"
	end 
	
	self.sub_entities = {}
	
	self.sub_entity_groups = {
		WIELDED_ENTITIES = {}
	}
	
	if init.upload_rate then
		set_rate(self, "upload", init.upload_rate)
	end
end