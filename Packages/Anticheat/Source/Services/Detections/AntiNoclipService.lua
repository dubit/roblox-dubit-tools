--[[
	AntiNoclipService is responsible for validating if the player is noclipping or not, it does so by raycasting every
		few moments and checking to see what objects the player has hit.
]]

local Players = game:GetService("Players")

local Package = script.Parent.Parent.Parent

local FlagService = require(Package.Services.FlagService)
local SchedulerService = require(Package.Services.SchedulerService)
local ScoreService = require(Package.Services.ScoreService)
local ViolationsService = require(Package.Services.ViolationsService)
local StateService = require(Package.Services.StateService)

local trackedCharacters = {}
local raycastParams = RaycastParams.new()

raycastParams.RespectCanCollide = true
raycastParams.IgnoreWater = true
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

local AntiSpeedService = {}

--[[
	Will evaluate the state of the character, this function is called every `SchedulerTick` and is responsible
		for flagging players as potentially bad actors.
]]
function AntiSpeedService.EvaluateCharacter(_: AntiSpeedService, character: Model)
	if not character.PrimaryPart then
		return
	end

	local punishment = FlagService:GetFlag("AntiNoclipPunishment")
	local punishmentScore = FlagService:GetFlag("AntiNoclipScore")

	local lastCharacterCFrame = trackedCharacters[character][1]
	local currentCharacterCFrame = character.PrimaryPart.CFrame

	if character.PrimaryPart:GetNetworkOwner() == nil then
		trackedCharacters[character][1] = character.PrimaryPart.CFrame

		return
	end

	if not lastCharacterCFrame then
		trackedCharacters[character][1] = currentCharacterCFrame

		return
	end

	local origin = lastCharacterCFrame.Position
	local direction = (currentCharacterCFrame.Position - origin).Unit
	local distance = (currentCharacterCFrame.Position - origin).Magnitude

	local raycast = workspace:Raycast(origin, direction * distance, raycastParams)

	if raycast then
		task.synchronize()

		local player = Players:GetPlayerFromCharacter(character)

		if not player then
			return
		end

		if ViolationsService:IsWhitelisted(player) then
			return
		end

		ScoreService:Increment(player, "AntiNoclip", punishmentScore)
		ViolationsService:Create(
			player,
			"AntiNoclip",
			`Noclip attempt at '{raycast.Instance:GetFullName()}@{raycast.Position}'`
		)

		if punishment == "Standard" then
			character.PrimaryPart.CFrame = lastCharacterCFrame
			character.PrimaryPart:SetNetworkOwner(nil)

			task.delay(3, function()
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

	raycastParams:AddToFilter(character)
end

function AntiSpeedService.OnCharacterRemoving(_: AntiSpeedService, character: Model)
	trackedCharacters[character] = nil

	local filter = table.clone(raycastParams.FilterDescendantsInstances)
	local index = table.find(filter, character)

	if index then
		table.remove(filter, index)

		raycastParams.FilterDescendantsInstances = filter
	end
end

function AntiSpeedService.OnStart(self: AntiSpeedService)
	local tick = FlagService:GetFlag("AntiNoclipTick")

	SchedulerService:Create(function()
		if not StateService:GetState("AntiNoclip") then
			return
		end

		for character in trackedCharacters do
			self:EvaluateCharacter(character)

			task.desynchronize()
		end
	end, tick)
end

export type AntiSpeedService = typeof(AntiSpeedService)

return AntiSpeedService
