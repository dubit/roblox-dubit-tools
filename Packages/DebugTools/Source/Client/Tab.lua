--!strict
local DebugToolRootPath = script.Parent
local SharedRootPath = DebugToolRootPath.Parent.Shared

local Signal = require(SharedRootPath.Signal)

local Tab = {}
Tab.internal = {
	Tabs = {},
}
Tab.interface = {
	TabAdded = Signal.new(),
}

function Tab.interface.new(name: string, constructorFunction: (parent: Frame) -> () -> ())
	assert(type(name) == "string", `Expected parameter #1 'name' to be a string, got {type(name)}`)
	assert(
		type(constructorFunction) == "function",
		`Expected parameter #2 'constructorFunction' to be a function, got {type(constructorFunction)}`
	)

	table.insert(Tab.internal.Tabs, {
		Name = name,

		CreateFunction = constructorFunction,
	})

	Tab.interface.TabAdded:Fire(name)
end

function Tab.interface.getTabConstructor(name: string): ((Frame) -> () -> nil)?
	for _, tab in Tab.internal.Tabs do
		if tab.Name == name then
			return tab.CreateFunction
		end
	end

	return nil
end

function Tab.interface.getAllTabs(): { string }
	local tabNames: { string } = {}
	for _, tab in Tab.internal.Tabs do
		table.insert(tabNames, tab.Name)
	end

	return tabNames
end

return Tab.interface
