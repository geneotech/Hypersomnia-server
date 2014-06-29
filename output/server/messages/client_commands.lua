client_commands = inherits_from ()

function client_commands:constructor(init)
	self.name = "client_commands"
	self.subject = init.subject
	self.bitstream = init.bitstream
end

function client_commands:get_bitstream()
	return copy_bitstream_for_reading(self.bitstream)
end