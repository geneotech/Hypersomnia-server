components = {}

components.create_components = function(entry)
	local output = {}
	
	for k, v in pairs(entry) do
		output[k] = components[k]:create(v)
	end	
	
	return output
end