--[[
	HoneypotService is responsible for deploying a range of fake remote events and functions in a ploy to try and bait
		exploiters into calling them & then immediately being flagged as a bad actor.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Package = script.Parent.Parent.Parent

local FlagService = require(Package.Services.FlagService)
local ScoreService = require(Package.Services.ScoreService)
local ViolationsService = require(Package.Services.ViolationsService)
local StateService = require(Package.Services.StateService)

local FAKE_REMOTES = table.freeze({
	["PlayerManager.Health.Regenerate"] = "RemoteFunction",
	["PlayerManager.Health.SetMax"] = "RemoteEvent",
	["PlayerManager.Health.InvincibilityToggle"] = "RemoteFunction",
	["PlayerManager.Stamina.InfiniteToggle"] = "RemoteEvent",
	["PlayerManager.Respawn.Force"] = "RemoteFunction",
	["PlayerManager.Respawn.SetCooldown"] = "RemoteEvent",

	["Inventory.Debug.UnlockAll"] = "RemoteEvent",
	["Inventory.AddItem"] = "RemoteFunction",
	["Inventory.RemoveItem"] = "RemoteEvent",
	["Inventory.SetCapacity"] = "RemoteFunction",
	["Inventory.OverrideRarity"] = "RemoteEvent",
	["Inventory.ForceEquip"] = "RemoteFunction",

	["Movement.Speed.Override"] = "RemoteFunction",
	["Movement.Jump.Force"] = "RemoteEvent",
	["Movement.Gravity.Override"] = "RemoteFunction",
	["Movement.Teleport.ToWaypoint"] = "RemoteEvent",
	["Movement.Teleport.ToPlayer"] = "RemoteFunction",
	["Movement.Collision.Toggle"] = "RemoteEvent",

	["Progression.XP.ForceAdd"] = "RemoteEvent",
	["Progression.Level.Set"] = "RemoteFunction",
	["Progression.Skills.UnlockAll"] = "RemoteEvent",
	["Progression.Achievements.GrantAll"] = "RemoteFunction",
	["Progression.Quests.CompleteAll"] = "RemoteEvent",
	["Progression.Reputation.Set"] = "RemoteFunction",

	["UI.CheatMenu.Show"] = "RemoteFunction",
	["UI.Debug.ShowAll"] = "RemoteEvent",
	["UI.Notifications.Spoof"] = "RemoteFunction",
	["UI.HUD.Toggle"] = "RemoteEvent",
	["UI.Menus.UnlockAll"] = "RemoteFunction",
	["UI.Cursor.Override"] = "RemoteEvent",

	["System.Security.ReportPlayer"] = "RemoteEvent",
	["System.Security.BanPlayer"] = "RemoteFunction",
	["System.Security.KickPlayer"] = "RemoteEvent",
	["System.Security.MutePlayer"] = "RemoteFunction",
	["System.Security.OverridePermissions"] = "RemoteEvent",
	["System.Security.LogEvent"] = "RemoteFunction",

	["PlayerEffects.Visibility.Toggle"] = "RemoteFunction",
	["PlayerEffects.Size.Override"] = "RemoteEvent",
	["PlayerEffects.Color.Override"] = "RemoteFunction",
	["PlayerEffects.Transparency.Set"] = "RemoteEvent",
	["PlayerEffects.Particles.Spawn"] = "RemoteFunction",
	["PlayerEffects.LightEmission.Set"] = "RemoteEvent",

	["Admin.Access.Elevate"] = "RemoteEvent",
	["Admin.Permissions.GrantAll"] = "RemoteFunction",
	["Admin.Commands.Execute"] = "RemoteEvent",
	["Admin.Logging.Toggle"] = "RemoteFunction",
	["Admin.Players.TeleportToMe"] = "RemoteEvent",
	["Admin.World.Modify"] = "RemoteFunction",

	["Currency.Debug.AddCredits"] = "RemoteFunction",
	["Currency.SetBalance"] = "RemoteEvent",
	["Currency.Transactions.Override"] = "RemoteFunction",
	["Currency.Purchases.Free"] = "RemoteEvent",
	["Currency.ExchangeRate.Set"] = "RemoteFunction",
	["Currency.Rewards.Multiply"] = "RemoteEvent",

	["DebugWipeSaveData"] = "RemoteFunction",
	["TeleportAllPlayers"] = "RemoteEvent",
	["UnlockAllSkins"] = "RemoteFunction",
	["DisableAllCollision"] = "RemoteEvent",
	["BypassPurchaseConfirmation"] = "RemoteFunction",
	["ForceGameEnd"] = "RemoteEvent",
})

local HoneypotService = {}

--[[
	Called when an exploiter calls one of our fake remote events/functions
]]
function HoneypotService.OnPlayerTriggered(_: HoneypotService, player: Player, remote: RemoteFunction | RemoteEvent)
	if not StateService:GetState("Honeypot") then
		return
	end

	if ViolationsService:IsWhitelisted(player) then
		return
	end

	local punishment = FlagService:GetFlag("HoneypotPunishment")
	local punishmentScore = FlagService:GetFlag("HoneypotScore")

	ScoreService:Increment(player, "Honeypot", punishmentScore)
	ViolationsService:Create(player, "Honeypot", `Player invoked honeypot: '{remote:GetFullName()}'`)

	if punishment == "Standard" then
		player:LoadCharacter()
	end
end

--[[
	Will create a remote event, set it's name and parent, and then bind the invoking of this event to the
		`OnPlayerTriggered` method.
]]
function HoneypotService.CreateRemoteEvent(self: HoneypotService, name: string, parent: Instance)
	local remoteEvent = Instance.new("RemoteEvent")

	remoteEvent.Name = name
	remoteEvent.Parent = parent

	remoteEvent.OnServerEvent:Connect(function(player)
		self:OnPlayerTriggered(player, remoteEvent)
	end)
end

--[[
	Will create a remote function, set it's name and parent, and then bind the invoking of this event to the
		`OnPlayerTriggered` method.
]]
function HoneypotService.CreateRemoteFunction(self: HoneypotService, name: string, parent: Instance)
	local remoteFunction = Instance.new("RemoteFunction")

	remoteFunction.Name = name
	remoteFunction.Parent = parent

	remoteFunction.OnServerInvoke = function(player)
		self:OnPlayerTriggered(player, remoteFunction)
	end
end

function HoneypotService.OnStart(self: HoneypotService)
	local fakeRemotes = {}

	for index, value in FAKE_REMOTES do
		if math.random() > 0.65 then
			fakeRemotes[index] = value
		end
	end

	for key, remoteType in fakeRemotes do
		local pathSegments = string.split(key, ".")
		local currentParent = ReplicatedStorage

		for i = 1, #pathSegments - 1 do
			local folderName = pathSegments[i]
			local existingFolder = currentParent:FindFirstChild(folderName)

			if not existingFolder then
				local newFolder = Instance.new("Folder")
				newFolder.Name = folderName
				newFolder.Parent = currentParent
				currentParent = newFolder
			else
				currentParent = existingFolder
			end
		end

		local remoteName = pathSegments[#pathSegments]

		if not currentParent:FindFirstChild(remoteName) then
			if remoteType == "RemoteEvent" then
				self:CreateRemoteEvent(remoteName, currentParent)
			elseif remoteType == "RemoteFunction" then
				self:CreateRemoteFunction(remoteName, currentParent)
			end
		end
	end
end

export type HoneypotService = typeof(HoneypotService)

return HoneypotService
