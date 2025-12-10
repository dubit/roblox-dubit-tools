--[[
	AntiCheat:
		The Roblox AntiCheat tool is designed to allow developers to implement a quick, standard anticheat into their experiences.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local SharedTableRegistry = game:GetService("SharedTableRegistry")

local Runtime = require(script.Parent.Runtime)
local Signal = require(script.Parent.Signal)

local SignalTypes = require(script.Types.Signal)
local NodeTypes = require(script.Types.Nodes)

local CharacterLifecycle = require(script.Lifecycles.CharacterLifecycle)
local PlayerLifecycle = require(script.Lifecycles.PlayerLifecycle)
local StartLifecycle = require(script.Lifecycles.StartLifecycle)

local isCheater = require(script.Functions.isCheater)
local flagAsCheater = require(script.Functions.flagAsCheater)

local anticheatRegistry = SharedTableRegistry:GetSharedTable(`DubitAntiCheat`)

local initialized = false
local threads = {}

local AntiCheat = {}

AntiCheat.interface = {
	CheaterFound = Signal.new() :: SignalTypes.Signal<Player>,
	ViolationTriggered = Signal.new() :: SignalTypes.Signal<Player, NodeTypes.Enum, string>,
}
AntiCheat.internal = {}

--[=[
	@prop ViolationTriggered Nodes
	@within AntiCheat

	Table denotating the different nodes that this version of the AntiCheat supports, you can pass these nodes directly into
		the APIs that require NodeTable

	:::info
	*Nodes represent the fundamental building blocks of the Anticheat system. Each node defines a specific feature or functionality.*
	:::
]=]
AntiCheat.interface.Nodes = table.freeze({
	ProximityPrompt = table.freeze({
		Punishment = "ProximityPromptPunishment",
		Score = "ProximityPromptScore",

		Leniency = "ProximityPromptLeniency",
	}),

	Honeypot = table.freeze({
		Punishment = "HoneypotPunishment",
		Score = "HoneypotScore",
	}),

	AntiClimb = table.freeze({
		Punishment = "AntiClimbPunishment",
		Score = "AntiClimbScore",

		QueryRange = "AntiClimbQueryRange",
		StepHeight = "AntiClimbStepHeight",
	}),

	AntiSwim = table.freeze({
		Punishment = "AntiSwimPunishment",
		Score = "AntiSwimScore",
		TerrainRadius = "AntiSwimTerrainRadius",
	}),

	AntiFly = table.freeze({
		Punishment = "AntiFlyPunishment",
		Score = "AntiFlyPunishment",

		RaycastDistance = "AntiFlyRaycastDistance",
		LeniencyMaxTime = "AntiFlyMaxTime",
		CentralTrajectoryBuffer = "AntiFlyCentralTrajectoryBuffer",
		AnchoredBuffer = "AntiFlyAnchoredBuffer",
	}),

	AntiNoclip = table.freeze({
		Punishment = "AntiNoclipPunishment",
		Score = "AntiNoclipScore",
		Tick = "AntiNoclipTick",
	}),

	AntiSpeed = table.freeze({
		Punishment = "AntiSpeedPunishment",
		Score = "AntiSpeedScore",

		TargetSpeed = "AntiSpeedTargetSpeed",
		LeniencySpeed = "AntiSpeedLeniencySpeed",
		LeniencySeated = "AntiSpeedLeniencySeated",
	}),
})

function AntiCheat.interface.Disable(self: DubitAnticheat): ()
	self:WaitUntilReady()

	assert(RunService:IsServer(), "Method can only be called on the server!")

	script.Events.DisableAllNodes:Fire()
end

function AntiCheat.interface.Enable(self: DubitAnticheat): ()
	self:WaitUntilReady()

	assert(RunService:IsServer(), "Method can only be called on the server!")

	script.Events.EnableAllNodes:Fire()
end

function AntiCheat.interface.DisableNode(self: DubitAnticheat, object: NodeTypes.Enum | FrozenNodeTable): ()
	local objectName: NodeTypes.Enum

	if type(object) == "table" then
		for nodeName, nodeObject in self.Nodes do
			if nodeObject == object then
				objectName = nodeName
			end
		end
	else
		objectName = object
	end

	self:WaitUntilReady()

	assert(RunService:IsServer(), "Method can only be called on the server!")

	script.Events.DisableNode:Fire(objectName)
end

function AntiCheat.interface.EnableNode(self: DubitAnticheat, object: NodeTypes.Enum | FrozenNodeTable): ()
	local objectName: NodeTypes.Enum

	if type(object) == "table" then
		for nodeName, nodeObject in self.Nodes do
			if nodeObject == object then
				objectName = nodeName
			end
		end
	else
		objectName = object
	end

	self:WaitUntilReady()

	assert(RunService:IsServer(), "Method can only be called on the server!")

	script.Events.EnableNode:Fire(objectName)
end

function AntiCheat.interface.SetFlag(self: DubitAnticheat, path: string, value: Generic): ()
	self:WaitUntilReady()

	assert(RunService:IsServer(), "Method can only be called on the server!")

	script.Events.SetFlag:Fire(path, value)
end

function AntiCheat.interface.ResetFlag(self: DubitAnticheat, path: string): ()
	self:WaitUntilReady()

	assert(RunService:IsServer(), "Method can only be called on the server!")

	script.Events.ResetFlag:Fire(path)
end

function AntiCheat.interface.AddToWhitelist(self: DubitAnticheat, player: Player): ()
	self:WaitUntilReady()

	assert(RunService:IsServer(), "Method can only be called on the server!")

	anticheatRegistry.whitelisted[player.UserId] = true
end

function AntiCheat.interface.RemoveFromWhitelist(self: DubitAnticheat, player: Player): ()
	self:WaitUntilReady()

	assert(RunService:IsServer(), "Method can only be called on the server!")

	anticheatRegistry.whitelisted[player.UserId] = nil
end

function AntiCheat.interface.WaitUntilReady(_: DubitAnticheat): ()
	while not anticheatRegistry.ready do
		task.wait()
	end
end

function AntiCheat.interface.FlagAsCheater(_: DubitAnticheat, player: Player): ()
	assert(RunService:IsServer(), "Method can only be called on the server!")

	flagAsCheater(player)
end

function AntiCheat.interface.IsFlaggedAsCheater(_: DubitAnticheat, player: Player): boolean
	if RunService:IsServer() then
		return (player:GetAttribute("DubitAnticheat_KnownCheater") or false) :: boolean
	else
		return isCheater(player) :: boolean
	end
end

function AntiCheat.interface.SetVerbose(self: DubitAnticheat, isVerbose: boolean): ()
	self:WaitUntilReady()

	assert(RunService:IsServer(), "Method can only be called on the server!")

	script.Events.SetVerbose:Fire(isVerbose)
end

function AntiCheat.interface.QueryViolations(self: DubitAnticheat, player: Player): { [string]: { string } }
	local query = HttpService:GenerateGUID(false)

	threads[query] = coroutine.running()

	self:WaitUntilReady()

	assert(RunService:IsServer(), "Method can only be called on the server!")

	script.Events.QueryViolations:Fire(query, player.UserId)

	return coroutine.yield()
end

function AntiCheat.interface.QueryScores(self: DubitAnticheat, player: Player): { [string]: number }
	local query = HttpService:GenerateGUID(false)

	threads[query] = coroutine.running()

	self:WaitUntilReady()

	assert(RunService:IsServer(), "Method can only be called on the server!")

	script.Events.QueryScores:Fire(query, player.UserId)

	return coroutine.yield()
end

function AntiCheat.interface.InitializeDesyncLuau(self: DubitAnticheat): ()
	assert(RunService:IsServer(), "Method can only be called on the server!")

	assert(initialized == false, `AntiCheat has already initialized!`)

	initialized = true

	anticheatRegistry.whitelisted = {}
	anticheatRegistry.ready = false

	local singletons = Runtime:RequireDescendants(script.Services)

	PlayerLifecycle(singletons)
	CharacterLifecycle(singletons)
	StartLifecycle(singletons)

	Players.PlayerRemoving:Connect(function(player)
		self:RemoveFromWhitelist(player)
	end)

	anticheatRegistry.ready = true
end

function AntiCheat.interface.InitializeSyncLuau(self: DubitAnticheat): ()
	assert(RunService:IsServer(), "Method can only be called on the server!")
	assert(initialized == false, `AntiCheat has already initialized!`)

	initialized = true

	local function forwardToThread(query, ...)
		local thread = threads[query]

		if not thread then
			return
		end

		coroutine.resume(thread, ...)
	end

	script.Events.QueryViolations.Event:Connect(function(query, violations, isResponse)
		if not isResponse then
			return
		end

		forwardToThread(query, violations)
	end)

	script.Events.QueryScores.Event:Connect(function(query, scores, isResponse)
		if not isResponse then
			return
		end

		forwardToThread(query, scores)
	end)

	script.Events.EmitCheaterFound.Event:Connect(function(userId)
		local player = Players:GetPlayerByUserId(userId)

		if not player then
			return
		end

		self:FlagAsCheater(player)
		self.CheaterFound:Fire(player)
	end)

	script.Events.EmitViolationTriggered.Event:Connect(function(userId, node, message)
		local player = Players:GetPlayerByUserId(userId)

		if not player then
			return
		end

		self.ViolationTriggered:Fire(player, node, message)
	end)

	Players.PlayerAdded:Connect(function(player: Player)
		if isCheater(player) then
			flagAsCheater(player)
		end
	end)
end

export type DubitAnticheat = typeof(AntiCheat.interface)

export type Generic = boolean | string | number | nil

export type FrozenNodeTable = typeof(table.freeze({}))

return AntiCheat.interface
