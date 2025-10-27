--[[
	AntiSwimService is responsible for validating the Swimming humanoid state, see the method 'IsWaterNearby' as to
		how we to figure out if the player is swimming or not.

	Swimming is actually an alternative way to fly -> hackers will set their humanoid state to swimming, and then
		will be able to swim up and around, which could be bad if we're blocking areas off.
]]

local Players = game:GetService("Players")

local Package = script.Parent.Parent.Parent.Parent

local FlagService = require(Package.Services.FlagService)
local SchedulerService = require(Package.Services.SchedulerService)
local ScoreService = require(Package.Services.ScoreService)
local ViolationsService = require(Package.Services.ViolationsService)
local StateService = require(Package.Services.StateService)

local trackedCharacters = {}

local terrain = game.Workspace.Terrain

local AntiSwimService = {}

--[[
	Validate the voxels close to a players avatar, if they're actually swimming then they should be near water which
		enables us to validate the swimming behaviour on the server.
]]
function AntiSwimService.IsWaterNearby(_: AntiSwimService, cframe: CFrame)
	local terrainRadius = FlagService:GetFlag("AntiSwimTerrainRadius")

	local materials = terrain:ReadVoxels(
		Region3.new(
			cframe.Position - Vector3.new(terrainRadius, terrainRadius, terrainRadius),
			cframe.Position + Vector3.new(terrainRadius, terrainRadius, terrainRadius)
		),
		4
	)

	for x = 1, materials.Size.X do
		for y = 1, materials.Size.Y do
			for z = 1, materials.Size.Z do
				if materials[x][y][z] == Enum.Material.Water then
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
function AntiSwimService.EvaluateCharacter(self: AntiSwimService, character: Model)
	if not character.PrimaryPart then
		return
	end

	local humanoid = (character:FindFirstChild("Humanoid")) :: Humanoid
	local currentCharacterCFrame = character.PrimaryPart.CFrame
	local state = humanoid:GetState()

	local punishment = FlagService:GetFlag("AntiSwimPunishment")
	local punishmentScore = FlagService:GetFlag("AntiSwimScore")

	if state ~= Enum.HumanoidStateType.Swimming then
		return
	end

	if not self:IsWaterNearby(currentCharacterCFrame) then
		task.synchronize()

		local player = Players:GetPlayerFromCharacter(character)

		if not player then
			return
		end

		if ViolationsService:IsWhitelisted(player) then
			return
		end

		ScoreService:Increment(player, "AntiSwim", punishmentScore)
		ViolationsService:Create(player, "AntiSwim", `Player attempted to swim - no water around player region!`)

		if punishment == "Standard" then
			trackedCharacters[character] = nil

			player:LoadCharacter()
		end
	end
end

function AntiSwimService.OnCharacterAdded(_: AntiSwimService, character: Model)
	trackedCharacters[character] = {}
end

function AntiSwimService.OnCharacterRemoving(_: AntiSwimService, character: Model)
	trackedCharacters[character] = nil
end

function AntiSwimService.OnStart(self: AntiSwimService)
	SchedulerService:Create(function()
		if not StateService:GetState("AntiSwim") then
			return
		end

		for character in trackedCharacters do
			self:EvaluateCharacter(character)

			task.desynchronize()
		end
	end)
end

export type AntiSwimService = typeof(AntiSwimService)

return AntiSwimService
