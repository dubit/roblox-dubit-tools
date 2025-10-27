--[[
	ScoreService is responsible for incrementing, decrementing and handling the players cheat score, if this score
		exceeds the `MaxScore` flag, then we label said user as a cheater.
]]

local Players = game:GetService("Players")

local Package = script.Parent.Parent

local FlagService = require(Package.Services.FlagService)
local LogService = require(Package.Services.LogService)

local Nodes = require(Package.Types.Nodes)

local nodeThreads = {} :: {
	[Player]: {
		[Nodes.Enum]: thread,
	},
}

local nodeScores = {} :: {
	[Player]: {
		[Nodes.Enum]: number,
	},
}

local ScoreService = {}

--[[
	We only ever want to decrement the user score after the following two conditions have been met:

	1. no more violations have occurred. (if another violation occurs - reset the timer to decrement)
	2. delayed cooldown period after a violation.
]]
function ScoreService.DecrementAfterDelay(self: ScoreService, player: Player, node: Nodes.Enum)
	local delay = FlagService:GetFlag("DecrementTick")
	local amount = FlagService:GetFlag("DecrementAmount")

	if nodeThreads[player][node] then
		task.cancel(nodeThreads[player][node])

		nodeThreads[player][node] = nil
	end

	nodeThreads[player][node] = task.delay(delay, function()
		nodeThreads[player][node] = nil
		nodeScores[player][node] = math.max(nodeScores[player][node] - amount, 0)

		if nodeScores[player][node] > 0 then
			self:DecrementAfterDelay(player, node)
		end
	end)
end

--[[
	Responsible for incrementing the current cheating score of a player
]]
function ScoreService.Increment(self: ScoreService, player: Player, node: Nodes.Enum, score: number)
	if not nodeScores[player][node] then
		nodeScores[player][node] = 0
	end

	local maxScore = FlagService:GetFlag("MaxScore")

	nodeScores[player][node] += score

	LogService:Log(`Player '{player.Name}' has been flagged by '{node}' node - adding '{score}' to internal score!`)
	LogService:Log(
		`Player '{player.Name}' confidence in being a cheater: {math.round((self:Get(player) / maxScore) * 100)}%`
	)

	if self:Get(player) >= maxScore then
		LogService:Log(`Player '{player.Name}' has hit the max score, flagging as a cheater!`)

		Package.Events.EmitCheaterFound:Fire(player.UserId)
	else
		self:DecrementAfterDelay(player, node)
	end
end

--[[
	Will fetch the current users score for either a specific node, or if no node is provided - the total score.
]]
function ScoreService.Get(_: ScoreService, player: Player, node: Nodes.Enum?)
	if node then
		return nodeScores[player][node] or 0
	else
		local totalScore = 0

		for _, score in nodeScores[player] do
			totalScore += score
		end

		return totalScore
	end
end

function ScoreService.OnPlayerAdded(_: ScoreService, player: Player)
	nodeScores[player] = {}
	nodeThreads[player] = {}
end

function ScoreService.OnPlayerRemoving(_: ScoreService, player: Player)
	for _, thread in nodeThreads[player] do
		task.cancel(thread)
	end

	nodeThreads[player] = nil
	nodeScores[player] = nil
end

function ScoreService.OnStart()
	Package.Events.QueryScores.Event:ConnectParallel(function(query, userId, isResponse)
		if isResponse then
			return
		end

		local player = Players:GetPlayerByUserId(userId)

		Package.Events.QueryScores:Fire(query, nodeScores[player], true)
	end)
end

export type ScoreService = typeof(ScoreService)

return ScoreService
