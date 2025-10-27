--[[
	This specific module implements the following lifecycles:
		- OnStart
			When the singletons are ready to be started
]]

local Package = script.Parent.Parent

local Runtime = require(Package.Parent.Runtime)

local ON_START_LIFECYCLE_NAME = "OnStart"

return function(moduleArray: { ModuleScript })
	Runtime:CallMethodOn(moduleArray, ON_START_LIFECYCLE_NAME)
end
