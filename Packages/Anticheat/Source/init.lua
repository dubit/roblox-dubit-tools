--[[
	AntiCheat:
		The Roblox AntiCheat tool is designed to allow developers to implement a quick, standard anticheat into their experiences.

	Documentation has been written in a Moonwave styled format, for documentation outside of moonwave - comments have been made to provide insight.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local SharedTableRegistry = game:GetService("SharedTableRegistry")
local RunService = game:GetService("RunService")

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

--[=[
	@class AntiCheat

	The Roblox AntiCheat tool allows developers to implement a quick and standardized anti-cheat system in their experiences.

	---

	The purpose of this tool is to help developers quickly integrate a system that detects common exploits, allowing them to focus on higher-priority tasks such as game features.

	This tool is designed to enable or disable different anti-cheat components without significantly affecting the player's experience.

	Additionally, it provides a way for developers to track and respond to instances of cheating.
]=]
local AntiCheat = {}

AntiCheat.interface = {}
AntiCheat.internal = {}

--[=[
	@prop CheaterFound Signal
	@within AntiCheat

	Invoked when the anti-cheat determines a player is cheating. Fires with the following argument:
		- Player: Player

	```lua
	AntiCheat.CheaterFound:Connect(function(player)
		Players:BanAsync({
			UserIds = { player.UserId },
			DisplayReason = "\"There is no right and wrong. There's only fun and boring.\" ~ Hackers"
		})
	end)
	```
]=]
AntiCheat.interface.CheaterFound = Signal.new() :: SignalTypes.Signal<Player>

--[=[
	@prop ViolationTriggered Signal
	@within AntiCheat

	:::caution
	This signal should not be used to detect cheaters. Use the 'CheaterFound' signal instead!
	:::

	Invoked when a player triggers a rule violation, increasing their anti-cheat score. Fires with the following arguments:
		- Player: Player
		- Node: string
		- Message: string

	```lua
	AntiCheat.ViolationTriggered:Connect(function(player, node, message)
		print(`Player {player.Name} has violated node '{node}': '{message}'`)
	end)
	```
]=]
AntiCheat.interface.ViolationTriggered = Signal.new() :: SignalTypes.Signal<Player, NodeTypes.Enum, string>

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

--[=[
	@method Disable
	@within AntiCheat
	@server

	Disables the anti-cheat. When this method is called, all detection nodes are stopped, meaning players
	will no longer be monitored.

	@return ()
]=]
function AntiCheat.interface.Disable(self: DubitAnticheat): ()
	self:WaitUntilReady()

	assert(RunService:IsServer(), "Method can only be called on the server!")

	script.Events.DisableAllNodes:Fire()
end

--[=[
	@method Enable
	@within AntiCheat
	@server

	Enables the anti-cheat. This should only be called if the anti-cheat has been previously disabled using the `:Disable` method.

	@return ()
]=]
function AntiCheat.interface.Enable(self: DubitAnticheat): ()
	self:WaitUntilReady()

	assert(RunService:IsServer(), "Method can only be called on the server!")

	script.Events.EnableAllNodes:Fire()
end

--[=[
	@method DisableNode
	@within AntiCheat
	@param Node string | NodeTable
	@server

	Disables a specific "node" of the AntiCheat. 

	To further explain what a Node is - the anticheat is broken up into several parts, each play their own
		role in identifying potential exploiters, and then getting them detected.

	Developers have the ability to disable/enable different nodes in the event the `Noclip` detection is currently
		acting up and we may not have the time to address the issues with it.

	```lua
	AntiCheat:DisableNode(AntiCheat.AntiFly)
	AntiCheat:DisableNode("AntiFly")
	```

	@return ()
]=]
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

--[=[
	@method EnableNode
	@within AntiCheat
	@param Node string | NodeTable
	@server

	Enables a specific "node" of the AntiCheat. 

	To further explain what a Node is - the anticheat is broken up into several parts, each play their own
		role in identifying potential exploiters, and then getting them detected.

	Developers have the ability to disable/enable different nodes in the event the `Noclip` detection is currently
		acting up and we may not have the time to address the issues with it.

	```lua
	AntiCheat:EnableNode(AntiCheat.AntiFly)
	AntiCheat:EnableNode("AntiFly")
	```

	@return ()
]=]
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

--[=[
	@method SetFlag
	@within AntiCheat
	@param path string
	@param value Generic
	@server

	Allows developers to configure specific flags the anticheat, and all nodes under it uses to identify and detect
		potential exploiters.

	Be careful when modifying these flags, we should try to optimise the default flags over having different flags
		defined per project.

	```lua
	AntiCheat:SetFlag(AntiCheat.AntiFly.RaycastDistance, 1.5)

	-- alternatively, if you know what these are called internally, you can use the name of the path you're writing
	-- to instead.
	AntiCheat:EnableNode("AntiFlyRaycastDistance")
	```


	@return ()
]=]
function AntiCheat.interface.SetFlag(self: DubitAnticheat, path: string, value: Generic): ()
	self:WaitUntilReady()

	assert(RunService:IsServer(), "Method can only be called on the server!")

	script.Events.SetFlag:Fire(path, value)
end

--[=[
	@method ResetFlag
	@within AntiCheat
	@param path string
	@server

	Will reset the flag to whatever it is by default, this allows developers to safely fallback to the defaults without
		having to create references for each flag before hand.

	```lua
	AntiCheat:ResetFlag(AntiCheat.AntiFly.RaycastDistance)
	```

	@return ()
]=]
function AntiCheat.interface.ResetFlag(self: DubitAnticheat, path: string): ()
	self:WaitUntilReady()

	assert(RunService:IsServer(), "Method can only be called on the server!")

	script.Events.ResetFlag:Fire(path)
end

--[=[
	@method AddToWhitelist
	@within AntiCheat
	@param player Player
	@server

	Adds a player to the whitelist. Whitelisted players are exempt from anti-cheat monitoring and can freely bypass restrictions.

	@return ()
]=]
function AntiCheat.interface.AddToWhitelist(self: DubitAnticheat, player: Player): ()
	self:WaitUntilReady()

	assert(RunService:IsServer(), "Method can only be called on the server!")

	anticheatRegistry.whitelisted[player.UserId] = true
end

--[=[
	@method RemoveFromWhitelist
	@within AntiCheat
	@param player Player
	@server

	Removes a player from the whitelist. See `AddToWhitelist` for details.

	@return ()
]=]
function AntiCheat.interface.RemoveFromWhitelist(self: DubitAnticheat, player: Player): ()
	self:WaitUntilReady()

	assert(RunService:IsServer(), "Method can only be called on the server!")

	anticheatRegistry.whitelisted[player.UserId] = nil
end

--[=[
	@method WaitUntilReady
	@within AntiCheat
	@server

	Will yield the current thread until the whitelist has marked itself as ready on parallel luau, because the anticheat
		works by sending messages through bindable events - we need to make sure the other side (parallel luau) is set up
		before we start emitting events.

	@return ()
]=]
function AntiCheat.interface.WaitUntilReady(_: DubitAnticheat): ()
	while not anticheatRegistry.ready do
		task.wait()
	end
end

--[=[
	@method FlagAsCheater
	@within AntiCheat
	@param player Player
	@server

	Flags a player as a cheater. This information is stored in a datastore, managed entirely by the anti-cheat system.

	:::caution
	This function is automatically called when a player is detected as a cheater. See `CheaterFound` for more details.
	:::

	@return ()
]=]
function AntiCheat.interface.FlagAsCheater(_: DubitAnticheat, player: Player): ()
	assert(RunService:IsServer(), "Method can only be called on the server!")

	flagAsCheater(player)
end

--[=[
	@method IsFlaggedAsCheater
	@within AntiCheat
	@param player Player
	@server
	@client

	Allows developers on both the client, and the server - to query if the current player is a cheater or not.

	@return ()
]=]
function AntiCheat.interface.IsFlaggedAsCheater(_: DubitAnticheat, player: Player): boolean
	if RunService:IsServer() then
		return (player:GetAttribute("DubitAnticheat_KnownCheater") or false) :: boolean
	else
		return isCheater(player) :: boolean
	end
end

--[=[
	@method SetVerbose
	@within AntiCheat
	@param isVerbose boolean
	@server

	Enables or disables debug warnings in the Output. By default, this is set to `false`.

	Warnings indicate when a player has violated a node's rules, allowing developers to diagnose unintended behavior
	(e.g., a player being teleported back after a script-triggered teleport).

	@return ()
]=]
function AntiCheat.interface.SetVerbose(self: DubitAnticheat, isVerbose: boolean): ()
	self:WaitUntilReady()

	assert(RunService:IsServer(), "Method can only be called on the server!")

	script.Events.SetVerbose:Fire(isVerbose)
end

--[=[
	@method QueryViolations
	@within AntiCheat
	@param player Player
	@server

	Allows developers to query a list of violations that the current player has broken, this list includes messages
		explaining what has gone wrong and information about the event.

	This list is broken up to allow developers to see what specific nodes a player has violated, then the messages
		are bundled under each node.

	@return { [string]: { string } }
]=]
function AntiCheat.interface.QueryViolations(self: DubitAnticheat, player: Player): { [string]: { string } }
	local query = HttpService:GenerateGUID(false)

	threads[query] = coroutine.running()

	self:WaitUntilReady()

	assert(RunService:IsServer(), "Method can only be called on the server!")

	script.Events.QueryViolations:Fire(query, player.UserId)

	return coroutine.yield()
end

--[=[
	@method QueryScores
	@within AntiCheat
	@param player Player
	@server

	Allows developers to query the current players score for all nodes. Score indicates how likely that player is
		to be a cheater, it's not a direct indication that these players are cheaters.

	@return { [string]: number }
]=]
function AntiCheat.interface.QueryScores(self: DubitAnticheat, player: Player): { [string]: number }
	local query = HttpService:GenerateGUID(false)

	threads[query] = coroutine.running()

	self:WaitUntilReady()

	assert(RunService:IsServer(), "Method can only be called on the server!")

	script.Events.QueryScores:Fire(query, player.UserId)

	return coroutine.yield()
end

--[=[
	@method InitializeDesyncLuau
	@within AntiCheat
	@server
	@private

	Responsible for initialising the library in parallel luau.

	@return ()
]=]
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

--[=[
	@method InitializeDesyncLuau
	@within AntiCheat
	@server
	@private

	Responsible for initialising the library.

	@return ()
]=]
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

--[=[
	@type NodeTable boolean | string | number | nil
	@within AntiCheat
]=]
export type Generic = boolean | string | number | nil

--[=[
	@type NodeTable {} 
	@within AntiCheat
]=]
export type FrozenNodeTable = typeof(table.freeze({}))

return AntiCheat.interface
