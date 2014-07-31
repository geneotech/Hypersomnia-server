components.character = inherits_from()

function components.character:constructor(init)
	self.buffered_commands = {}
	self.at_step = 0
  self.owner_client = init.owner_client
end