components.character = inherits_from()

function components.character:constructor(init)
	self.commands = BitStream()
	
	self.buffered_commands = {}
	self.at_step = 0
end