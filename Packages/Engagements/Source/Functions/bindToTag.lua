local CollectionService = game:GetService("CollectionService")

--[[
	Allows you to bind a callback to a tag, this callback will be called with all existing tags, as well as all future
		tags.

	Returns a connection that can be disconnected
]]
return function(tagName: string, callback: (model: Model) -> ())
	for _, object in CollectionService:GetTagged(tagName) do
		callback(object)
	end

	return CollectionService:GetInstanceAddedSignal(tagName):Connect(function(object)
		callback(object)
	end)
end
