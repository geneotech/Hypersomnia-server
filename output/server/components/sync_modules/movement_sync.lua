sync_modules.movement = inherits_from ()

function sync_modules.movement:constructor(parent_entity)
	self.parent_entity = parent_entity
end

function sync_modules.movement:update(bsOut)
	local body = self.parent_entity.physics.body
	
	Writeb2Vec2(bsOut, body:GetPosition())
	Writeb2Vec2(bsOut, body:GetLinearVelocity())
end

