--[[
	AntiClimbService is responsible for validating the Climbing humanoid state, see the method 'CanClimbAhead' as to
		how we to figure out if the player is climbing or not.
]]

local Players = game:GetService("Players")

local Package = script.Parent.Parent.Parent.Parent

local FlagService = require(Package.Services.FlagService)
local SchedulerService = require(Package.Services.SchedulerService)
local ScoreService = require(Package.Services.ScoreService)
local ViolationsService = require(Package.Services.ViolationsService)
local StateService = require(Package.Services.StateService)

local trackedCharacters = {}
local overlapParams = OverlapParams.new()
local raycastParams = RaycastParams.new()

overlapParams.RespectCanCollide = true
overlapParams.FilterType = Enum.RaycastFilterType.Exclude

raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater = true
overlapParams.RespectCanCollide = true

local AntiClimbService = {}

--[[
	Algorithm responsible for detecting weather or not the player is climbing something infront of them, this algorithm
		accounts for truss parts, as well as parts that are stacked in an order which enables the humanoid to climb.
]]
function AntiClimbService.CanClimbAhead(_: AntiClimbService, character: Model)
	local maxStepHeight = FlagService:GetFlag("AntiClimbStepHeight")
	local detectionRange = FlagService:GetFlag("AntiClimbQueryRange")

	local humanoid = (character:FindFirstChild("Humanoid")) :: Humanoid
	local humanoidRootPart = character.PrimaryPart

	local forwardVector = humanoidRootPart.CFrame.LookVector

	local stepIncrement = maxStepHeight / 5

	for stepHeight = 0, humanoid.HipHeight, stepIncrement do
		local origin = humanoidRootPart.Position + Vector3.new(0, stepHeight, 0)
		local direction = forwardVector * detectionRange
		local raycastResult = workspace:Raycast(origin, direction, raycastParams)

		if raycastResult then
			local hitPart = raycastResult.Instance
			local hitPosition = raycastResult.Position

			if hitPart:IsA("TrussPart") then
				return true
			end

			if hitPart.Size.Y <= humanoid.HipHeight then
				local nextOrigin = origin + forwardVector * (hitPart.Size.Z + 0.1)
				local nextRaycastResult = workspace:Raycast(nextOrigin, direction, raycastParams)

				if nextRaycastResult then
					local nextHitPosition = nextRaycastResult.Position
					local verticalGap = math.abs(nextHitPosition.Y - hitPosition.Y)

					if verticalGap <= maxStepHeight then
						return true
					end
				else
					return true
				end
			end
		end
	end

	return false
end

--[[
	Will evaluate the state of the character, this function is called every `SchedulerTick` and is responsible
		for flagging players as potentially bad actors.
]]
function AntiClimbService.EvaluateCharacter(self: AntiClimbService, character: Model)
	if not character.PrimaryPart then
		return
	end

	local humanoid = (character:FindFirstChild("Humanoid")) :: Humanoid
	local currentCharacterCFrame = character.PrimaryPart.CFrame
	local state = humanoid:GetState()

	local punishment = FlagService:GetFlag("AntiClimbPunishment")
	local punishmentScore = FlagService:GetFlag("AntiClimbScore")

	if state ~= Enum.HumanoidStateType.Climbing then
		return
	end

	if not self:CanClimbAhead(character) then
		task.synchronize()

		local player = Players:GetPlayerFromCharacter(character)

		if not player then
			return
		end

		if ViolationsService:IsWhitelisted(player) then
			return
		end

		ScoreService:Increment(player, "AntiClimb", punishmentScore)
		ViolationsService:Create(
			player,
			"AntiClimb",
			`Player attempted to climb - player has nothing to climb on @{currentCharacterCFrame.Position}!`
		)

		if punishment == "Standard" then
			trackedCharacters[character] = nil

			player:LoadCharacter()
		end
	end
end

function AntiClimbService.OnCharacterAdded(_: AntiClimbService, character: Model)
	trackedCharacters[character] = {}

	overlapParams:AddToFilter(character)
	raycastParams:AddToFilter(character)
end

function AntiClimbService.OnCharacterRemoving(_: AntiClimbService, character: Model)
	trackedCharacters[character] = nil

	for _, params in { overlapParams, raycastParams } do
		local filter = params.FilterDescendantsInstances
		local index = table.find(filter, character)

		if index then
			table.remove(filter, index)

			overlapParams.FilterDescendantsInstances = filter
		end
	end
end

function AntiClimbService.OnStart(self: AntiClimbService)
	SchedulerService:Create(function()
		if not StateService:GetState("AntiClimb") then
			return
		end

		for character in trackedCharacters do
			self:EvaluateCharacter(character)

			task.desynchronize()
		end
	end)
end

export type AntiClimbService = typeof(AntiClimbService)

return AntiClimbService
