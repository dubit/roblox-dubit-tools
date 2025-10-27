--[[
	State\Service is responsible for handling the anticheats state, if it's enabled/disabled, and more importantly
		what nodes are enabled/disabled.
]]

local Package = script.Parent.Parent

local Signal = require(Package.Parent.Signal)

local SchedulerService = require(Package.Services.SchedulerService)

local Nodes = require(Package.Types.Nodes)

local nodeState = true
local disabledNodes = {}

local StateService = {}

StateService.NodeStateChanged = Signal.new()

--[[
	Returns a boolean indicating if the node is enabled or not.
]]
function StateService.GetState(_: StateService, node: Nodes.Enum?): boolean
	if not nodeState then
		return false
	end

	return not disabledNodes[node]
end

function StateService.OnStart(self: StateService)
	Package.Events.DisableAllNodes.Event:ConnectParallel(function()
		nodeState = false

		SchedulerService:Pause()
		self.NodeStateChanged:Fire()
	end)

	Package.Events.EnableAllNodes.Event:ConnectParallel(function()
		nodeState = true

		SchedulerService:Resume()
		self.NodeStateChanged:Fire()
	end)

	Package.Events.EnableNode.Event:ConnectParallel(function(nodeName: string)
		disabledNodes[nodeName] = nil

		self.NodeStateChanged:Fire()
	end)

	Package.Events.DisableNode.Event:ConnectParallel(function(nodeName: string)
		disabledNodes[nodeName] = true

		self.NodeStateChanged:Fire()
	end)
end

export type StateService = typeof(StateService)

return StateService
