network_message = inherits_from ()

function network_message:create(init)
	self.name = "network_message"
	self.subject = init.subject
	self.data = init.data
end