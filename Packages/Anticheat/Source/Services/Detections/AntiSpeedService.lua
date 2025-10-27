--[[
	AntiSpeedService is responsible for validating the players average speed, this module will do distance checks every
		`SchedulerTick` to ensure that the player is going at the correct speed, and not above.

	WARNING: This module does not account for physics influence, as an example - a player standing on a moving platform
		could trigger this detection.
]]

local Players = game:GetService("Players")

local Package = script.Parent.Parent.Parent

local FlagService = require(Package.Services.FlagService)
local SchedulerService = require(Package.Services.SchedulerService)
local ScoreService = require(Package.Services.ScoreService)
local ViolationsService = require(Package.Services.ViolationsService)
local StateService = require(Package.Services.StateService)

local CLAMP_VECTOR = Vector3.new(1, 0, 1)

local trackedCharacters = {}
local deltaTimeTracked = 0

local AntiSpeedService = {}

--[[
	Will evaluate the state of the character, this function is called every `SchedulerTick` and is responsible
		for flagging players as potentially bad actors.
]]
function AntiSpeedService.EvaluateCharacter(_: AntiSpeedService, character: Model)
	if not character.PrimaryPart then
		return
	end

	local schedulerTick = FlagService:GetFlag("SchedulerTick")

	local targetWalkspeed = FlagService:GetFlag("AntiSpeedTargetSpeed")
	local punishmentScore = FlagService:GetFlag("AntiSpeedScore")
	local speedLeniency = FlagService:GetFlag("AntiSpeedLeniencySpeed")
	local seatedLeniency = FlagService:GetFlag("AntiSpeedLeniencySeated")
	local punishment = FlagService:GetFlag("AntiSpeedPunishment")

	local humanoid = (character:FindFirstChild("Humanoid")) :: Humanoid
	local lastCharacterCFrame = trackedCharacters[character][1]
	local currentCharacterCFrame = character.PrimaryPart.CFrame

	if
		not lastCharacterCFrame
		or humanoid:GetState() == Enum.HumanoidStateType.Swimming
		or character.PrimaryPart:GetNetworkOwner() == nil
	then
		trackedCharacters[character][1] = currentCharacterCFrame

		return
	end

	local magnitude = ((currentCharacterCFrame.Position * CLAMP_VECTOR) - (lastCharacterCFrame.Position * CLAMP_VECTOR)).Magnitude
	local estimatedWalkspeed = magnitude / schedulerTick + deltaTimeTracked

	if estimatedWalkspeed > targetWalkspeed + speedLeniency then
		--[[
			In the case the player is next to a seat, common roblox seat behaviour is to teleport and weld the players character
				to that seat. This singleton should account for this and make sure users don't trigger the anticheat upon sitting on
				a seat.
		]]

		if humanoid.SeatPart then
			if estimatedWalkspeed > targetWalkspeed + seatedLeniency then
				local weld = humanoid.SeatPart:FindFirstChild("SeatWeld")

				if weld then
					weld:Destroy()
				end
			else
				return
			end
		end

		task.synchronize()

		local player = Players:GetPlayerFromCharacter(character)

		if not player then
			return
		end

		if ViolationsService:IsWhitelisted(player) then
			return
		end

		ScoreService:Increment(player, "AntiSpeed", punishmentScore)
		ViolationsService:Create(player, "AntiSpeed", `Flagged humanoid speed at '{math.round(estimatedWalkspeed)}'`)

		if punishment == "Standard" then
			character.PrimaryPart.CFrame = lastCharacterCFrame
			character.PrimaryPart:SetNetworkOwner(nil)

			task.delay(3, function()
				if not player:IsDescendantOf(Players) then
					return
				end

				if character and character.PrimaryPart and character:IsDescendantOf(workspace) then
					character.PrimaryPart:SetNetworkOwner(player)
				end
			end)
		end
	else
		trackedCharacters[character][1] = currentCharacterCFrame
	end
end

function AntiSpeedService.OnCharacterAdded(_: AntiSpeedService, character: Model)
	trackedCharacters[character] = {}
end

function AntiSpeedService.OnCharacterRemoving(_: AntiSpeedService, character: Model)
	trackedCharacters[character] = nil
end

function AntiSpeedService.OnStart(self: AntiSpeedService)
	SchedulerService:Create(function(deltaTime)
		deltaTimeTracked = deltaTime

		if not StateService:GetState("AntiSpeed") then
			return
		end

		for character in trackedCharacters do
			self:EvaluateCharacter(character)

			task.desynchronize()
		end
	end)
end

export type AntiSpeedService = typeof(AntiSpeedService)

return AntiSpeedService
