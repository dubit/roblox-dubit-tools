--[[
	ProximityPromptService is responsible for validating the range at which players interact with proximity prompts
		this helps to ensure that the player is where they say they are upon an interaction. 

	Most cheats have a method for invoking proximity prompts w/o being close to said proximity prompt.
]]

local RobloxProximityPromptService = game:GetService("ProximityPromptService")

local Package = script.Parent.Parent.Parent

local FlagService = require(Package.Services.FlagService)
local ScoreService = require(Package.Services.ScoreService)
local ViolationsService = require(Package.Services.ViolationsService)
local StateService = require(Package.Services.StateService)

local ProximityPromptService = {}

--[[
	Returns the Vector3 position in the world where the proximity prompt is, there's a few edge cases that we need to
		account for when it comes to figuring out where in the world a proximity prompt is.
]]
function ProximityPromptService.GetPosition(_: ProximityPromptService, proximityPrompt: ProximityPrompt): Vector3?
	local rootCFrame: CFrame?

	if not proximityPrompt.Parent then
		return
	end

	if proximityPrompt.Parent:IsA("Model") then
		if proximityPrompt.Parent.PrimaryPart then
			rootCFrame = proximityPrompt.Parent.PrimaryPart.CFrame
		end
	elseif proximityPrompt.Parent:IsA("BasePart") then
		rootCFrame = proximityPrompt.Parent.CFrame
	elseif proximityPrompt.Parent:IsA("Attachment") then
		rootCFrame = proximityPrompt.Parent.WorldCFrame
	end

	if not rootCFrame then
		return
	end

	return rootCFrame.Position
end

function ProximityPromptService.OnStart(self: ProximityPromptService)
	RobloxProximityPromptService.PromptTriggered:ConnectParallel(
		function(proximityPrompt: ProximityPrompt, player: Player)
			if not StateService:GetState("ProximityPrompt") then
				return
			end

			local proximityPromptPosition = self:GetPosition(proximityPrompt)
			local characterPosition = player.Character
				and player.Character.PrimaryPart
				and player.Character.PrimaryPart.Position

			local promptLeiency = FlagService:GetFlag("ProximityPromptLeniency")
			local punishment = FlagService:GetFlag("ProximityPromptPunishment")
			local punishmentScore = FlagService:GetFlag("ProximityPromptScore")

			if not proximityPromptPosition then
				return
			end

			local magnitude = (characterPosition - proximityPromptPosition).Magnitude

			if magnitude > proximityPrompt.MaxActivationDistance + promptLeiency then
				task.synchronize()

				if ViolationsService:IsWhitelisted(player) then
					return
				end

				ScoreService:Increment(player, "ProximityPrompt", punishmentScore)
				ViolationsService:Create(
					player,
					"ProximityPrompt",
					`Attempted to invoke '{proximityPrompt:GetFullName()}' when the user is '{magnitude}' studs away.`
				)

				if punishment == "Standard" then
					player:LoadCharacter()
				end
			end
		end
	)
end

export type ProximityPromptService = typeof(ProximityPromptService)

return ProximityPromptService
