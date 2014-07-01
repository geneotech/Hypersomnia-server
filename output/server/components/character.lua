components.character = inherits_from()

function components.character:constructor(init)
	self.commands = BitStream()
end