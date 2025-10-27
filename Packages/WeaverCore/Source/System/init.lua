--[[
	System:
]]
--

--[[
	@class System

	The Weaver 'System' represents a singleton object, the goal for these objects are to handle logic in the background, working behind the Behaviour instances.
]]
--
local System = {}

System.type = "System"

System.instances = {}

System.interface = {}
System.prototype = {}

--[[
	Private method used to invoke lifecycle methods

	@method _InvokeLifecycleMethod
	@within System

	@param methodName string
	@param varargs ...any

	@private
	@return ...any
]]
--
function System.prototype:_InvokeLifecycleMethod(methodName, ...)
	if not self[methodName] then
		return
	end

	return self[methodName](self, ...)
end

--[[
	Returns a string representing the system & system name

	```lua
	local System = Weaver.System.new({ Name = "Hello" })

	print(System:ToString()) --> System<Hello>
	```

	@method ToString
	@within System

	@return string
]]
--
function System.prototype:ToString()
	return `{System.type}<{self.Name}>`
end

--[[
	This function compares the first parameter to the class 'System'

	@function is
	@within System

	@param object? System?
	@return boolean
]]
--
function System.interface.is(object)
	if typeof(object) ~= "table" then
		return false
	end

	local objectMetatable = getmetatable(object)

	return objectMetatable and objectMetatable.__type == System.type
end

--[[
	This function constructs a new 'System' class

	@function new
	@within System

	@param source { Priority: number?, Name: string?, Dependencies: { [string]: System }? }

	@return System
]]
--
function System.interface.new(source)
	local self = setmetatable(source or {}, {
		__type = System.type,
		__index = System.prototype,
		__tostring = function(object)
			return object:ToString()
		end,
	})

	if not self.Name then
		local callingScriptFullPath = string.split(debug.info(2, "s"), ".")
		local callingScriptName = callingScriptFullPath[#callingScriptFullPath]

		self.Name = callingScriptName
	end

	if not self.Priority then
		self.Priority = 0
	end

	if not self.Dependencies then
		self.Dependencies = {}
	end

	assert(type(self.Name) == "string", `Expected Name to be of type string, got {type(self.Name)}`)
	assert(System.instances[self.Name] == nil, `{self.Name} System already exists within the same context.`)

	System.instances[self.Name] = self

	return System.instances[self.Name]
end

--[[
	This function collects all system instances generated
]]
--
function System.interface.fetchAllInstances()
	return System.instances
end

return System.interface
