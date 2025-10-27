local SleitnicksComponent = require(script.Parent.Parent.Component)

local componentLifecycleMethods = {
	["Construct"] = true,
	["Start"] = true,
	["Stop"] = true,
}

--[=[
	@class Component

	Component Description/summary
]=]
local Component = {}

Component.internal = {}
Component.interface = {}
Component.prototype = {}

function Component.internal:InvokeLifecycleMethods(class, lifecycleMethod, ...)
	if not class._internalLifecycleMethods then
		return
	end

	if not class._internalLifecycleMethods[lifecycleMethod] then
		return
	end

	class._internalLifecycleMethods[lifecycleMethod](...)
end

function Component.prototype:Construct(...)
	Component.internal:InvokeLifecycleMethods(self, "Construct", ...)
end

function Component.prototype:Start(...)
	Component.internal:InvokeLifecycleMethods(self, "Start", ...)
end

function Component.prototype:Stop(...)
	Component.internal:InvokeLifecycleMethods(self, "Stop", ...)
end

--[=[
	function description

	```lua
	-- function example
	```

	@function new
	@within Component

	@return Component
]=]
--
function Component.interface.new(...)
	local newComponent = SleitnicksComponent.new(...)

	newComponent._internalLifecycleMethods = {}

	for index, object in Component.prototype do
		newComponent[index] = object
	end

	return setmetatable({}, {
		__index = newComponent,
		__newindex = function(_, index, value)
			if componentLifecycleMethods[index] then
				newComponent._internalLifecycleMethods[index] = value
			else
				newComponent[index] = value
			end
		end,
	})
end

return Component.interface
