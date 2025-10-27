--[[
	Roblox Serialisation - surface level module to manipulate encoding & decoding multiple types
]]
--

local Serialisation = {}

Serialisation.interface = {}
Serialisation.implementations = {}

--[[
	Implement support for a type to be serialise and deserialised
]]
--
function Serialisation.interface:Implement(dataType, serialise, deserialise)
	Serialisation.implementations[dataType] = {
		serialise = serialise,
		deserialise = deserialise,
	}
end

--[[
	Serialise a type, making a type into an object
]]
--
function Serialisation.interface:Serialise(object)
	local objectTypeOf = typeof(object)

	if Serialisation.implementations[objectTypeOf] then
		local serialisedObject = Serialisation.implementations[objectTypeOf].serialise(object)

		-- surface level field to indicate how to deserialise this object
		serialisedObject.objectType = objectTypeOf

		return true, serialisedObject
	else
		return false, object
	end
end

--[[
	Deserialise a type, making that object into a specific type
]]
--
function Serialisation.interface:Deserialise(object)
	local objectTypeOf = typeof(object)

	assert(objectTypeOf == "table", "Expected argument #1'object' to reflect a serialised type")

	if Serialisation.implementations[object.objectType] then
		return true, Serialisation.implementations[object.objectType].deserialise(object)
	else
		return false, object
	end
end

--[[
	quick method to validate if a type has been implemented
]]
--
function Serialisation.interface:IsSupported(object)
	return Serialisation.implementations[typeof(object)] ~= nil
end

-- child modules will invoke the :Implement method, writing in multiple methods for encoding & decoding a type.
for _, object in script.DataTypes:GetChildren() do
	require(object)(Serialisation.interface)
end

return Serialisation.interface :: typeof(Serialisation.interface)
