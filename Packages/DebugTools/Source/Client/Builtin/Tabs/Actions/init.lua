--!strict
local DebugToolRootPath = script.Parent.Parent.Parent

local Tab = require(DebugToolRootPath.Tab)
local Networking = require(DebugToolRootPath.Networking)

local Action = require(DebugToolRootPath.Parent.Shared.Action)
local Value = require(DebugToolRootPath.Parent.Shared.Value)

local ActionsList = require(script.Interface.ActionsList)
local ActionGroupsExplorer = require(script.Interface.ActionGroupsExplorer)

local SEVER_PREFIX: string = "Server/"
local SERVER_PREFIX_LEN: number = string.len(SEVER_PREFIX)

local Actions = {}
Actions.internal = {
	ActionGroups = Value.new({}),
	Actions = Value.new({}),
	SelectedGroup = Value.new(false),

	ActionsListDestroyer = nil :: (() -> nil)?,
	ActionGroupsExplorerDestroyer = nil :: (() -> nil)?,
}

function Actions.internal.executeServerAction(actionName: string, arguments: { any }?)
	Networking:SendMessage("actions_execute", actionName, arguments)
	-- TODO: Return actual returned value from server
	return true
end

function Actions.internal.addAction(actionData)
	local isServerAction: boolean = string.sub(actionData.Name, 1, SERVER_PREFIX_LEN) == SEVER_PREFIX
	local formattedActionName: string = isServerAction
			and string.sub(actionData.Name, SERVER_PREFIX_LEN + 1, #actionData.Name)
		or actionData.Name

	local slashPosition: number? = string.find(formattedActionName, "/")
	local actionName: string = slashPosition
			and string.sub(formattedActionName, slashPosition + 1, #formattedActionName)
		or formattedActionName
	local groupName: string? = slashPosition and string.sub(formattedActionName, 1, slashPosition - 1)
		or "Uncategorized"

	local currentActionGroups = Actions.internal.ActionGroups:Get()
	if not table.find(currentActionGroups, groupName) then
		table.insert(currentActionGroups, groupName)
		Actions.internal.ActionGroups:Set(currentActionGroups, true)
	end

	local currentActions = Actions.internal.Actions:Get()
	if not currentActions[groupName] then
		currentActions[groupName] = {}
	end

	table.insert(currentActions[groupName], {
		Name = actionName,
		RawName = actionData.Name,
		Description = actionData.Description,
		Arguments = actionData.Arguments,
		ServerAction = isServerAction,
	})

	Actions.internal.Actions:Set(currentActions, true)

	local currentSelectedGroup = Actions.internal.SelectedGroup:Get()
	if not currentSelectedGroup then
		Actions.internal.SelectedGroup:Set(groupName)
	end
end

function Actions.internal.removeAction(actionName: string)
	local currentActions = Actions.internal.Actions:Get()
	local newActions = {}

	for groupName, groupActions in currentActions do
		local actionGroup = {}

		for _, actionData in groupActions do
			-- Skip adding the action we want to remove to the new table
			if actionData.RawName == actionName or actionData.RawName == `Server/{actionName}` then
				continue
			end

			actionGroup[actionData.Name] = actionData
		end

		newActions[groupName] = actionGroup
	end

	Actions.internal.Actions:Set(newActions, true)
end

function Actions.internal:Init()
	Networking:SubscribeToTopic("actions_update", function(serverActions)
		for _, actionDefinition in serverActions do
			Action.new(`Server/{actionDefinition.Name}`, actionDefinition.Description, function(...)
				return Actions.internal.executeServerAction(actionDefinition.Name, { ... })
			end, actionDefinition.Arguments)
		end
	end)

	Networking:SubscribeToTopic("actions_remove", Actions.internal.removeAction)

	for _, actionDefiniton in Action:GetAll() do
		Actions.internal.addAction(actionDefiniton)
	end

	Action.ActionAdded:Connect(function(actionName: string)
		local actionDefiniton = Action:GetDefinition(actionName)
		Actions.internal.addAction(actionDefiniton)
	end)

	Action.ActionRemoved:Connect(Actions.internal.removeAction)
end

function Actions.internal:MountInterface(parent: Frame)
	Actions.internal.ActionsListDestroyer =
		ActionsList(parent, Actions.internal.SelectedGroup, Actions.internal.Actions)

	Actions.internal.ActionGroupsExplorerDestroyer = ActionGroupsExplorer(
		parent,
		Actions.internal.ActionGroups,
		Actions.internal.SelectedGroup,
		function(groupName: string)
			Actions.internal.SelectedGroup:Set(groupName)
		end
	)

	Networking:SendMessage("actions_listening", true)
end

function Actions.internal:UnmountInterface()
	if Actions.internal.ActionsListDestroyer then
		Actions.internal.ActionsListDestroyer()
		Actions.internal.ActionsListDestroyer = nil
	end

	if Actions.internal.ActionGroupsExplorerDestroyer then
		Actions.internal.ActionGroupsExplorerDestroyer()
		Actions.internal.ActionGroupsExplorerDestroyer = nil
	end

	Networking:SendMessage("actions_listening", false)
end

Actions.internal:Init()

Tab.new("Actions", function(parent: Frame)
	Actions.internal:MountInterface(parent)

	return function()
		Actions.internal:UnmountInterface()
	end
end)

return nil
