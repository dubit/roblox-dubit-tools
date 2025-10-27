--!strict
local DebugToolRootPath = script.Parent.Parent
local SharedRootPath = DebugToolRootPath.Shared

local Signal = require(SharedRootPath.Signal)

local Module = {}
Module.internal = {
	Modules = {},
}
Module.prototype = {}
Module.interface = {
	ModuleAdded = Signal.new(),
}

function Module.prototype:Init() end

function Module.interface.new(name: string)
	assert(type(name) == "string", `Expected parameter #1 'name' to be a string, got {type(name)}`)

	local self = setmetatable({
		Name = name,
	}, {
		__index = Module.prototype,
	})

	task.defer(function()
		table.insert(Module.internal.Modules, name)

		self:Init()

		Module.interface.ModuleAdded:Fire(self)
	end)

	return self
end

function Module.interface.getAllModules()
	return table.clone(Module.internal.Modules)
end

return Module.interface
