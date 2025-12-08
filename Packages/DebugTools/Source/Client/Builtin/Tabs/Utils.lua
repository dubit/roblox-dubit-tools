local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DebugToolRootPath = script.Parent.Parent.Parent

local Tab = require(DebugToolRootPath.Tab)
local IMGui = require(DebugToolRootPath.IMGui)
local Networking = require(DebugToolRootPath.Networking)

local serverLocked = false

local targetFPS = math.huge

task.defer(function()
	while true do
		local tick0 = os.clock()

		RunService.Heartbeat:Wait()

		-- selene:allow(empty_loop)
		repeat
		until (tick0 + 1 / targetFPS) < os.clock()
	end
end)

local noclipConnection

local invisiblePartsShown = false
local visualPartClones: { [Instance]: HandleAdornment } = {}
local potentialInvisiblePartConnections = {}

local function createInvisibleVisual(part: BasePart)
	if visualPartClones[part] then
		return
	end

	local adornment: any
	if part:IsA("Part") then
		if part.Shape == Enum.PartType.Block then
			adornment = Instance.new("BoxHandleAdornment")
			adornment.Size = part.Size + Vector3.new(0.1, 0.1, 0.1)
		elseif part.Shape == Enum.PartType.Ball then
			adornment = Instance.new("SphereHandleAdornment")
			adornment.Radius = math.min(part.Size.X, part.Size.Y, part.Size.Z) * 0.50
		elseif part.Shape == Enum.PartType.Cylinder then
			adornment = Instance.new("CylinderHandleAdornment")
			adornment.CFrame = CFrame.Angles(0, math.pi * 0.50, 0)
			adornment.Radius = math.min(part.Size.Y, part.Size.Z) * 0.50
			adornment.Height = part.Size.X
		else
			adornment = Instance.new("BoxHandleAdornment")
			adornment.Size = part.Size + Vector3.new(0.1, 0.1, 0.1)
		end
	else
		adornment = Instance.new("BoxHandleAdornment")
		adornment.Size = part.Size + Vector3.new(0.1, 0.1, 0.1)
	end
	adornment.Adornee = part
	adornment.Transparency = 0.50
	adornment.AlwaysOnTop = true
	adornment.Parent = workspace.Terrain

	visualPartClones[part] = adornment
end

local function processPontentialInvisibleInstance(instance: Instance)
	if not instance:IsA("BasePart") then
		return
	end

	table.insert(
		potentialInvisiblePartConnections,
		instance:GetPropertyChangedSignal("Transparency"):Connect(function()
			if instance.Transparency < 1 then
				if visualPartClones[instance] then
					visualPartClones[instance]:Destroy()
					visualPartClones[instance] = nil
				end
				return
			end

			createInvisibleVisual(instance)
		end)
	)

	if instance.Transparency == 1 then
		createInvisibleVisual(instance)
	end
end

local invisiblePartsWarnEnabled = false
local invisiblePartsWarnConnections = {}

Tab.new("Utils", function(parent: Frame)
	return IMGui:Connect(parent, function()
		IMGui:ScrollingFrameY(UDim2.fromScale(1, 1))

		IMGui:Label("<b>World</b>")
		local newInvisiblePartsValue = IMGui:PropertyInspector("Invisible Parts", invisiblePartsShown).changed()
		if newInvisiblePartsValue ~= nil then
			invisiblePartsShown = newInvisiblePartsValue

			if invisiblePartsShown then
				table.insert(
					potentialInvisiblePartConnections,
					workspace.DescendantAdded:Connect(processPontentialInvisibleInstance)
				)
				for _, instance in workspace:GetDescendants() do
					processPontentialInvisibleInstance(instance)
				end
			else
				for _, partClone in visualPartClones do
					partClone:Destroy()
				end
				visualPartClones = {}

				for _, connection in potentialInvisiblePartConnections do
					connection:Disconnect()
				end
				potentialInvisiblePartConnections = {}
			end
		end
		IMGui:Label("")

		local localCharacter = Players.LocalPlayer.Character

		if localCharacter then
			IMGui:Label(`<b>Local Character</b> ({localCharacter:GetFullName()})`)

			local humanoid = localCharacter:FindFirstChildWhichIsA("Humanoid", true)
			if humanoid then
				local newValue = IMGui:PropertyInspector("Walkspeed", humanoid.WalkSpeed).changed()
				if newValue then
					humanoid.WalkSpeed = newValue
				end
			end

			local newInvisiblePartsWarnValue = IMGui:PropertyInspector("Invisible part warn", invisiblePartsWarnEnabled)
				.changed()
			if newInvisiblePartsWarnValue ~= nil then
				invisiblePartsWarnEnabled = newInvisiblePartsWarnValue

				if invisiblePartsWarnEnabled then
					for _, part in localCharacter:GetChildren() do
						if not part:IsA("BasePart") then
							continue
						end

						table.insert(
							invisiblePartsWarnConnections,
							part.Touched:Connect(function(part)
								if part.Transparency < 1 then
									return
								end

								warn(part:GetFullName())
							end)
						)
					end
				else
					local connections = invisiblePartsWarnConnections
					invisiblePartsWarnConnections = {}

					for _, connection in connections do
						connection:Disconnect()
					end
				end
			end

			local newNoclipValue = IMGui:PropertyInspector("Noclip", noclipConnection ~= nil).changed()
			if newNoclipValue ~= nil then
				if not newNoclipValue then
					noclipConnection:Disconnect()
					noclipConnection = nil

					local character = Players.LocalPlayer.Character

					if not character then
						return
					end

					for _, object in character:GetChildren() do
						if object:IsA("BasePart") then
							object.CanCollide = true
						end
					end
				else
					noclipConnection = RunService.PreSimulation:Connect(function()
						local character = Players.LocalPlayer.Character

						if not character then
							return
						end

						for _, object in character:GetChildren() do
							if object:IsA("BasePart") then
								object.CanCollide = false
							end
						end
					end)
				end
			end
		end

		IMGui:Label("")

		IMGui:Label("<b>Performance</b>")
		local newFPSValue = IMGui:PropertyInspector("FPS Limiter", 60).changed()
		if newFPSValue then
			targetFPS = math.max(10, newFPSValue)
		end
		IMGui:Label("")

		IMGui:Label("<b>Server</b>")
		local newServerLockedValue = IMGui:PropertyInspector("Locked", serverLocked).changed()
		if newServerLockedValue ~= nil then
			serverLocked = newServerLockedValue

			Networking:SendMessage("server_lock", newServerLockedValue)
		end

		local newServerFPSValue = IMGui:PropertyInspector("FPS Limiter", 60).changed()
		if newServerFPSValue then
			Networking:SendMessage("fps_limiter", newServerFPSValue)
		end

		IMGui:End()
	end)
end)

return nil
