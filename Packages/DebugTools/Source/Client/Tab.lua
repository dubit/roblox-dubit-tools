local DebugToolRootPath = script.Parent
local SharedRootPath = DebugToolRootPath.Parent.Shared

local Signal = require(SharedRootPath.Signal)

local registeredTabs = {}

local Tab = {
	TabAdded = Signal.new(),
}

function Tab.new(name: string, constructorFunction: (parent: Frame) -> () -> ())
	assert(type(name) == "string", `Expected parameter #1 'name' to be a string, got {type(name)}`)
	assert(
		type(constructorFunction) == "function",
		`Expected parameter #2 'constructorFunction' to be a function, got {type(constructorFunction)}`
	)

	table.insert(registeredTabs, {
		Name = name,

		CreateFunction = constructorFunction,
	})

	Tab.TabAdded:Fire(name)
end

function Tab.getTabConstructor(name: string): ((Frame) -> () -> nil)?
	for _, tab in registeredTabs do
		if tab.Name == name then
			return tab.CreateFunction
		end
	end

	return nil
end

function Tab.getAllTabs(): { string }
	local tabNames: { string } = {}
	for _, tab in registeredTabs do
		table.insert(tabNames, tab.Name)
	end

	table.sort(tabNames, function(a: string, b: string): boolean
		return a < b
	end)

	return tabNames
end

return Tab
