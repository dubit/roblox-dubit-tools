--[[
	Behaviour:
]]
--

local Sift = require(script.Parent.Parent.Sift)

--[[
	@class Behaviour

	The Weaver 'Behaviour' represents a component object, the goal for these objects are to provide a way for developers to manipulate objects in-game through Tags. These objects do not contain a lot of logic, instead rely on Systems to deliver logic.
]]
--
local Behaviour = {}

Behaviour.type = "Behaviour"

Behaviour.instances = {}

Behaviour.interface = {}
Behaviour.prototype = {}

--[[
	Private method used to invoke lifecycle methods

	@method _InvokeLifecycleMethod
	@within Behaviour

	@param methodName string
	@param varargs ...any

	@private
	@return ...any
]]
--
function Behaviour.prototype:_InvokeLifecycleMethod(methodName, ...)
	if not self[methodName] then
		return
	end

	return self[methodName](self, ...)
end

--[[
	Returns a string representing the behaviour & behaviour name

	```lua
	local Behaviour = Weaver.Behaviour.new({ Tag = "Hello" })

	print(Behaviour:ToString()) --> System<Hello>
	```

	@method ToString
	@within Behaviour

	@return string
]]
--
function Behaviour.prototype:ToString()
	return `{Behaviour.type}<{self.Tag}>`
end

--[[
	This function compares the first parameter to the class 'Behaviour'

	@function is
	@within Behaviour

	@param object? Behaviour?
	@return boolean
]]
--
function Behaviour.interface.is(object)
	if typeof(object) ~= "table" then
		return false
	end

	local objectMetatable = getmetatable(object)

	return objectMetatable and objectMetatable.__type == Behaviour.type
end

--[[
	This function constructs a new 'Behaviour' class

	@function new
	@within Behaviour

	@param source { Tag: string, Properties: { [string]: any }?, Dependencies: { [string]: System }? }

	@return Behaviour
]]
--
function Behaviour.interface.new(source)
	assert(source ~= nil, `Expected 'source' for parameter #1, got nil`)
	assert(type(source) == "table", `Expected 'source' to be a table, got {type(source)}`)
	assert(type(source.Tag) == "string", `Expected 'source.Tag' to be a string`)

	local self = setmetatable(source, {
		__type = Behaviour.type,
		__index = Behaviour.prototype,
		__tostring = function(object)
			return object:ToString()
		end,
	})

	if not self.Properties then
		self.Properties = {}
	end

	if not self.Dependencies then
		self.Dependencies = {}
	end

	if not Behaviour.instances[self.Tag] then
		Behaviour.instances[self.Tag] = {}
	end

	table.insert(Behaviour.instances[self.Tag], self)

	return self
end

--[[
	This function will return a collection of tags which we're activly using
]]
--
function Behaviour.interface.fetchTags()
	return Sift.Dictionary.keys(Behaviour.instances)
end

--[[
	This function will fetch all components in corralation to a tag
]]
--
function Behaviour.interface.fetch(tag)
	if not tag then
		return Behaviour.instances
	end

	return Behaviour.instances[tag]
end

return Behaviour.interface
