--[[
	ViolationsService is responsible for keeping track of what violations the user has triggered, as an additional
		chore, this singleton is also responsible for detecting if a user is whitelisted or not.
]]

local Players = game:GetService("Players")
local SharedTableRegistry = game:GetService("SharedTableRegistry")

local Package = script.Parent.Parent

local LogService = require(Package.Services.LogService)

local Nodes = require(Package.Types.Nodes)

local anticheatRegistry = SharedTableRegistry:GetSharedTable(`DubitAntiCheat`)
local nodeViolations = {} :: {
	[Player]: {
		[Nodes.Enum]: { string }?,
	},
}

local ViolationsService = {}

--[[
	Returns a boolean dependent on if the user passed is whitelisted or not.
]]
function ViolationsService.IsWhitelisted(_: ViolationsService, player: Player)
	return anticheatRegistry.whitelisted[player.UserId]
end

--[[
	Returns the current list of violations (violations are represented as strings) for a node.
]]
function ViolationsService.Get(_: ViolationsService, player: Player, node: Nodes.Enum)
	return nodeViolations[player][node]
end

--[[
	Responsible for flagging a violation of a node.
]]
function ViolationsService.Create(_: ViolationsService, player: Player, node: Nodes.Enum, message: string)
	if not nodeViolations[player][node] then
		nodeViolations[player][node] = {}
	end

	table.insert(nodeViolations[player][node], 1, message)

	LogService:Log(`Player '{player.Name}' has been flagged by '{node}' node - '{message}'`)

	Package.Events.EmitViolationTriggered:Fire(player.UserId, node, message)
end

function ViolationsService.OnPlayerAdded(_: ViolationsService, player: Player)
	nodeViolations[player] = {}
end

function ViolationsService.OnPlayerRemoving(_: ViolationsService, player: Player)
	nodeViolations[player] = nil
end

function ViolationsService.OnStart(_: ViolationsService)
	Package.Events.QueryViolations.Event:ConnectParallel(function(query, userId, isResponse)
		if isResponse then
			return
		end

		local player = Players:GetPlayerByUserId(userId)

		Package.Events.QueryViolations:Fire(query, nodeViolations[player], true)
	end)
end

export type ViolationsService = typeof(ViolationsService)

return ViolationsService
