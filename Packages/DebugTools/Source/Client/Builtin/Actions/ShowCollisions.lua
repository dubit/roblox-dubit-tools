--!strict

--[[
	Responsible for creating a default debug action called "Toggle Invisible Parts" which finds all invisible parts in
	the workspace, and creates visible clones that are either red (for collidable parts) or green (for non-collidable
	parts).

	This action also has two additional useful parameters for QA:
	- Update automatically - whether the system should re-render all invisible parts every 0.5 seconds (this will cause
	a performance hit, which is why it is opt-in)
	- Warn part names when touched - whether a warning should be created in the output whenever the local character
	touches one of the invisible parts (invisible parts inside the local players own character will be ignored)

	All default actions should be created under the "Default" category
]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DebugToolRootPath = script.Parent.Parent.Parent

local Action = require(DebugToolRootPath.Parent.Shared.Action)

local AUTOMATIC_UPDATE_TIME = 0.5

local player = Players.LocalPlayer

local automaticUpdateConnection = nil
local visualPartClones = {}

local function toggleInvisibleParts(invisiblePartsAreVisible: boolean, doDisplayPartNamesWhenTouched: boolean)
	--Destroy any existing part clones
	for partClone, _ in visualPartClones do
		partClone:Destroy()
	end
	visualPartClones = {}

	if not invisiblePartsAreVisible then
		return
	end

	for _, instance: Instance in workspace:GetDescendants() do
		if not (instance:IsA("BasePart") and instance.Transparency == 1) then
			continue
		end

		local partClone = instance:Clone()
		for _, child in partClone:GetChildren() do
			if child:IsA("Light") then
				child:Destroy()
			end
		end

		partClone.Anchored = true
		partClone.CanCollide = false
		partClone.Material = Enum.Material.Neon
		partClone.Color = if instance.CanCollide then Color3.fromRGB(255, 0, 0) else Color3.fromRGB(0, 255, 0)
		partClone.Size += Vector3.new(0.01, 0.01, 0.01)
		partClone.Transparency = 0.666

		partClone.Parent = instance

		--Allow QA to debug invisible parts by printing the instance full name
		if doDisplayPartNamesWhenTouched then
			partClone.Touched:Connect(function(hit: BasePart)
				if
					hit
					and player.Character
					and hit:IsDescendantOf(player.Character)
					and not partClone:IsDescendantOf(player.Character)
				then
					warn(instance:GetFullName())
				end
			end)
		end

		visualPartClones[partClone] = true
	end
end

Action.new(
	"Default/Toggle Invisible Parts",
	"Toggles whether invisible parts are visible",
	function(status: boolean, doUpdateAutomatically: boolean, doDisplayPartNamesWhenTouched: boolean)
		toggleInvisibleParts(status, doDisplayPartNamesWhenTouched)

		if automaticUpdateConnection then
			automaticUpdateConnection:Disconnect()
			automaticUpdateConnection = nil
		end

		if doUpdateAutomatically then
			local lastUpdateTime = 0
			automaticUpdateConnection = RunService.Stepped:Connect(function()
				if tick() - lastUpdateTime > AUTOMATIC_UPDATE_TIME then
					lastUpdateTime = tick()
					toggleInvisibleParts(status, doDisplayPartNamesWhenTouched)
				end
			end)
		end
	end,
	{
		{
			Type = "boolean",
			Name = "Visible",
			Default = true,
		},
		{
			Type = "boolean",
			Name = "Update automatically (every 0.5 seconds)",
			Default = false,
		},
		{
			Type = "boolean",
			Name = "Warn part names when touched",
			Default = false,
		},
	}
)

return nil
