--!strict
local Players = game:GetService("Players")
local DebugToolRootPath = script.Parent.Parent.Parent

local Tab = require(DebugToolRootPath.Tab)
local IMGui = require(DebugToolRootPath.IMGui)
local Networking = require(DebugToolRootPath.Networking)

local Action = require(DebugToolRootPath.Parent.Shared.Action)

Networking:SubscribeToTopic("actions_update", function(serverActions)
	for _, actionDefinition in serverActions do
		Action.new(`Server/{actionDefinition.Name}`, actionDefinition.Description, function(...)
			return Networking:SendMessage("actions_execute", actionDefinition.Name, { ... })
		end, actionDefinition.Arguments)
	end
end)

Tab.new("Actions", function(parent: Frame)
	Networking:SendMessage("actions_listening", true)

	local expandedPaths = {}
	local selectedAction
	local argumentValues = {}

	local actionsTree = {}

	local function refreshActions()
		actionsTree = {}

		for _, actionDefiniton in Action:GetAll() do
			local splitName = string.split(actionDefiniton.Name, "/")
			local actionName = splitName[#splitName]

			local leafNode = actionsTree
			for i = 1, #splitName - 1 do
				local pathPart = table.concat(splitName, "/", 1, i)
				if not leafNode[pathPart] then
					leafNode[pathPart] = {}
				end

				leafNode = leafNode[pathPart]
			end

			leafNode[actionName] = actionDefiniton.Name
		end
	end

	Action.ActionAdded:Connect(refreshActions)
	Action.ActionRemoved:Connect(refreshActions)
	refreshActions()

	return IMGui:Connect(parent, function()
		IMGui:BeginHorizontal()

		IMGui:ScrollingFrameY(UDim2.fromScale(1, 1))
		IMGui:Label(`<b>Actions</b>`)

		local function processNode(node, depth: number)
			for name, data in node do
				local actualName = string.split(name, "/")
				actualName = actualName[#actualName]

				if typeof(data) == "table" then
					if IMGui:TreeNode(false).activated() then
						expandedPaths[name] = not expandedPaths[name]
					end

					IMGui:BeginGroup(UDim2.fromOffset(20 * depth, 0))
					IMGui:End()

					local arrowIcon = next(data) == nil and ""
						or expandedPaths[name] and "rbxassetid://17115119309"
						or "rbxassetid://17115120806"

					if IMGui:ImageButton(UDim2.fromOffset(16, 16), arrowIcon).activated() then
						expandedPaths[name] = not expandedPaths[name]
					end

					IMGui:Label(actualName)

					IMGui:End()

					if expandedPaths[name] then
						processNode(data, depth + 1)
					end
				else
					if IMGui:TreeNode(selectedAction == data).activated() then
						selectedAction = data

						local definition = Action:GetDefinition(data)
						argumentValues = {}

						if definition.Arguments then
							for _, argument in definition.Arguments do
								if argument.Type == "Player" then
									table.insert(argumentValues, Players.LocalPlayer)
								else
									table.insert(argumentValues, argument.Default)
								end
							end
						end
					end

					IMGui:BeginGroup(UDim2.fromOffset(20 * depth, 0))
					IMGui:End()

					IMGui:BeginGroup(UDim2.fromOffset(5, 0))
					IMGui:End()

					IMGui:Label(actualName)

					IMGui:End()
				end
			end
		end

		processNode(actionsTree, 0)

		IMGui:End()

		IMGui:ScrollingFrameY(UDim2.fromScale(3, 1))

		if selectedAction then
			local definition = Action:GetDefinition(selectedAction)
			IMGui:Label(`<b>{definition.Name}</b>`)
			IMGui:Label(definition.Description or "")
			IMGui:Label(``)

			if definition.Arguments then
				IMGui:Label(`<b>Arguments</b>`)

				for i, argument in definition.Arguments do
					if argument.Options then
						local options = table.clone(argument.Options)
						local currentValueIndex = table.find(options, argumentValues[i]) :: number
						options[1], options[currentValueIndex] = options[currentValueIndex], options[1]

						local newValue = IMGui:PropertyInspector(argument.Name, options).changed()
						if newValue then
							argumentValues[i] = newValue
						end
					elseif argument.Type == "Player" then
						local options = Players:GetPlayers()
						local currentValueIndex = table.find(options, argumentValues[i]) :: number
						options[1], options[currentValueIndex] = options[currentValueIndex], options[1]

						local newValue = IMGui:PropertyInspector(argument.Name, options).changed()
						if newValue then
							argumentValues[i] = newValue
						end
					else
						local newValue = IMGui:PropertyInspector(argument.Name, argumentValues[i]).changed()

						if newValue ~= nil then
							argumentValues[i] = newValue
						end
					end
				end

				IMGui:Label(``)
			end

			if IMGui:Button("Execute").activated() then
				Action:Execute(definition.Name, argumentValues)
			end
		end

		IMGui:End()
	end)
end)

return nil
