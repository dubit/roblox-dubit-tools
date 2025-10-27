--[[
	AntiFlyService is responsible for validating if the player is flying or not, see the method 'AnalyzeTrajectory' as to
		how we to figure out if the player is flying or not.

	Flying is a very common exploit that hackers use, and it's actually quite hard to reliably detect on the server, because
		of it's unpredictability - this detection is very cautious and will try to actively avoid false flagging.

	This singleton also houses it's own internal score, and only after `AntiFlyMaxTime` seconds, will this module flag a player
]]

local Players = game:GetService("Players")

local Package = script.Parent.Parent.Parent

local FlagService = require(Package.Services.FlagService)
local SchedulerService = require(Package.Services.SchedulerService)
local ScoreService = require(Package.Services.ScoreService)
local ViolationsService = require(Package.Services.ViolationsService)
local StateService = require(Package.Services.StateService)

local trackedCharacters = {}
local flaggedCharacters = {}
local raycastParams = RaycastParams.new()

raycastParams.RespectCanCollide = true
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

local AntiFlyService = {}

local ignoredStates = {
	[Enum.HumanoidStateType.Climbing] = true,
	[Enum.HumanoidStateType.Swimming] = true,
}

--[[
	Algorithm responsible for extracting the following information from an array of CFrames:

	1. Average trajectory - Upwards, Downwards or Central
	2. Average distance travelled
	3. If the humanoid root part looks to be anchored in the air
]]
function AntiFlyService.AnalyzeTrajectory(_: AntiFlyService, cframes: { CFrame })
	local totalDistance = 0
	local totalChangeY = 0
	local maxChangeMagnitude = 0

	local centralBuffer = FlagService:GetFlag("AntiFlyCentralTrajectoryBuffer")
	local anchoredBuffer = FlagService:GetFlag("AntiFlyAnchoredBuffer")

	for i = 2, #cframes do
		local previousPosition = cframes[i - 1].Position
		local currentPosition = cframes[i].Position

		local previousRotX, previousRotY, previousRotZ = cframes[i - 1]:ToEulerAnglesYXZ()
		local currentRotX, currentRotY, currentRotZ = cframes[i]:ToEulerAnglesYXZ()

		local distance = (currentPosition - previousPosition).Magnitude
		local deltaY = currentPosition.Y - previousPosition.Y
		local rotationChange = math.abs(currentRotX - previousRotX)
			+ math.abs(currentRotY - previousRotY)
			+ math.abs(currentRotZ - previousRotZ)
		local changeMagnitude = distance + rotationChange

		totalDistance = totalDistance + distance
		totalChangeY = totalChangeY + deltaY
		maxChangeMagnitude = math.max(maxChangeMagnitude, changeMagnitude)
	end

	local averageDistance = totalDistance / (#cframes - 1)
	local averageChangeY = totalChangeY / (#cframes - 1)

	local trajectory
	if averageChangeY > centralBuffer / 2 then
		trajectory = "Upwards"
	elseif averageChangeY < -centralBuffer / 2 then
		trajectory = "Downwards"
	else
		trajectory = "Central"
	end

	return {
		averageDistance = averageDistance,
		trajectory = trajectory,
		looksLikeAnchored = maxChangeMagnitude <= anchoredBuffer,
	}
end

--[[
	Will evaluate the state of the character, this function is called every `SchedulerTick` and is responsible
		for flagging players as potentially bad actors.
]]
function AntiFlyService.EvaluateCharacter(self: AntiFlyService, character: Model)
	if not character.PrimaryPart then
		return
	end

	local schedulerTick = FlagService:GetFlag("SchedulerTick")
	local maxTimeFloating = FlagService:GetFlag("AntiFlyMaxTime")
	local punishment = FlagService:GetFlag("AntiFlyPunishment")
	local punishmentScore = FlagService:GetFlag("AntiFlyScore")
	local raycastDistance = FlagService:GetFlag("AntiFlyRaycastDistance")

	local humanoid = (character:FindFirstChild("Humanoid")) :: Humanoid
	local currentCharacterCFrame = character.PrimaryPart.CFrame

	if character.PrimaryPart:GetNetworkOwner() == nil then
		trackedCharacters[character] = {}

		return
	end

	-- exploiters are able to spoof this -> we depend on child singletons to detect when these are invalid states!
	if ignoredStates[humanoid:GetState()] then
		trackedCharacters[character] = {}

		return
	end

	local raycast =
		workspace:Raycast(currentCharacterCFrame.Position, Vector3.new(0, -raycastDistance, 0), raycastParams)

	if raycast then
		trackedCharacters[character] = {}
	else
		table.insert(trackedCharacters[character], currentCharacterCFrame)

		-- we aren't sure if the player is cheating, or if they're just falling or flinging..
		if #trackedCharacters[character] < 5 then
			flaggedCharacters[character] = 0

			return
		else
			table.remove(trackedCharacters[character], 1)
		end

		local trajectoryInformation = self:AnalyzeTrajectory(trackedCharacters[character])
		local flyingTime = flaggedCharacters[character] + schedulerTick

		if trajectoryInformation.trajectory == "Downwards" then
			flaggedCharacters[character] = 0
		elseif trajectoryInformation.looksLikeAnchored then
			flaggedCharacters[character] = math.max(flaggedCharacters[character] - (schedulerTick / 2), 0)
		else
			if flyingTime >= maxTimeFloating then
				task.synchronize()

				local player = Players:GetPlayerFromCharacter(character)

				if not player then
					return
				end

				if ViolationsService:IsWhitelisted(player) then
					return
				end

				ScoreService:Increment(player, "AntiFly", punishmentScore)
				ViolationsService:Create(
					player,
					"AntiFly",
					`Player attempted to fly! trajectory: {trajectoryInformation.trajectory}`
				)

				if punishment == "Standard" then
					trackedCharacters[character] = nil

					player:LoadCharacter()
				end
			else
				flaggedCharacters[character] += schedulerTick
			end
		end
	end
end

function AntiFlyService.OnCharacterAdded(_: AntiFlyService, character: Model)
	trackedCharacters[character] = {}
	flaggedCharacters[character] = 0

	raycastParams:AddToFilter(character)
end

function AntiFlyService.OnCharacterRemoving(_: AntiFlyService, character: Model)
	trackedCharacters[character] = nil
	flaggedCharacters[character] = nil

	local filter = table.clone(raycastParams.FilterDescendantsInstances)
	local index = table.find(filter, character)

	if index then
		table.remove(filter, index)

		raycastParams.FilterDescendantsInstances = filter
	end
end

function AntiFlyService.OnStart(self: AntiFlyService)
	SchedulerService:Create(function()
		if not StateService:GetState("AntiFly") then
			return
		end

		for character in trackedCharacters do
			self:EvaluateCharacter(character)

			task.desynchronize()
		end
	end)
end

export type AntiFlyService = typeof(AntiFlyService)

return AntiFlyService
