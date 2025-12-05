--!strict
type ActionArgumentType = "string" | "number" | "boolean" | "Player"

type ActionArgument = {
	Type: ActionArgumentType,
	Name: string?,
	Default: any?,
	Options: { any }?,
}

type ActionArguments = { ActionArgument }

type ActionFunction = (...any) -> any

type Action = {
	Name: string,
	Description: string?,
	Action: ActionFunction,
	Arguments: ActionArguments?,
}

local Signal = require(script.Parent.Signal)

local Action = {}
Action.internal = {
	Registry = {},
}
Action.interface = {
	ActionAdded = Signal.new(),
	ActionRemoved = Signal.new(),
}

function Action.interface.new(name: string, description: string?, action: ActionFunction, arguments: ActionArguments)
	assert(type(name) == "string", `Expected parameter #1 'name' to be a string, got {type(name)}`)
	if description ~= nil then
		assert(
			type(description) == "string",
			`Expected parameter #2 'description' to be a string, got {type(description)}`
		)
	end
	assert(type(action) == "function", `Expected parameter #3 'action' to be a string, got {type(action)}`)

	if Action.internal.Registry[name] then
		Action.interface:UnregisterAction(name)
	end

	local newAction: Action = {
		Name = name,
		Description = description,
		Action = action,
		Arguments = arguments,
	}

	Action.internal.Registry[name] = newAction

	Action.interface.ActionAdded:Fire(name)
end

function Action.interface:GetDefinition(actionName: string): {
	Name: string,
	Description: string?,
	Arguments: ActionArguments?,
}
	local actionRegistry: Action = Action.internal.Registry[actionName]
	assert(actionRegistry, `Action '{actionName}' doesn't exist in the registry!`)

	return {
		Name = actionName,
		Description = actionRegistry.Description,
		Arguments = actionRegistry.Arguments,
	}
end

function Action.interface:GetAll(): {
	{
		Name: string,
		Description: string?,
		Arguments: ActionArguments?,
	}
}
	local actionDefinitions: {
		{
			Name: string,
			Description: string?,
			Arguments: ActionArguments?,
		}
	} = {}

	for _, action: Action in Action.internal.Registry do
		table.insert(actionDefinitions, {
			Name = action.Name,
			Description = action.Description,
			Arguments = action.Arguments,
		})
	end

	return actionDefinitions
end

function Action.interface:Execute(actionName: string, arguments: { any }?): unknown
	arguments = arguments or {}

	local actionDefinition: Action? = Action.internal.Registry[actionName]
	assert(actionDefinition, `Action definition doesn't exist for action '{actionName}'`)

	if actionDefinition.Arguments then
		for argumentIndex: number, argumentDefinition: ActionArgument in actionDefinition.Arguments do
			local argumentValue: any = arguments[argumentIndex]

			local argumentType: string = typeof(argumentValue)

			if argumentType == "Instance" then
				argumentType = (argumentValue :: Instance).ClassName
			end

			assert(
				argumentDefinition.Type == argumentType,
				`Action argument #{argumentIndex} doesn't match the definition, got '{argumentType}' expected '{argumentDefinition.Type}'`
			)
		end
	end

	return actionDefinition.Action(table.unpack(arguments))
end

function Action.interface:UnregisterAction(actionName: string)
	Action.internal.Registry[actionName] = nil
	Action.interface.ActionRemoved:Fire(actionName)
end

return Action.interface
