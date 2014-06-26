client_command = inherits_from ()

function client_command:create(init)
	self.name = "client_commands"
	self.subject = init.subject
	self.command_bitstream = init.command_bitstream
end

function client_command:get_command_bitstream()
	return copy_bitstream_for_reading(self.input_bs)
end