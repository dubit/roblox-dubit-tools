--!strict

--[=[
	@class ClothingDisplay.Mannequin
]=]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Utils = require(script.Parent.Utils)
local ProductInfo = require(script.Parent.ProductInfo)

type HumanoidDescriptionAccessory = {
	AccessoryType: Enum.AccessoryType,
	AssetId: number,
	IsLayered: boolean,
	Order: number?,
}

local Mannequin = {}
Mannequin.prototype = {}
Mannequin.interface = {}
Mannequin.private = {}
Mannequin.descriptionUpdateQueue = {}
Mannequin.outfitAutoUpdateList = {}

function Mannequin.private:CancelAutoRefresh(mannequinInstance: any)
	Mannequin.outfitAutoUpdateList[mannequinInstance] = nil
end

function Mannequin.private:QueueDescriptionUpdate(humanoid: Humanoid, humanoidDescription: HumanoidDescription)
	for _, queuedUpdate in Mannequin.descriptionUpdateQueue do
		if queuedUpdate.Humanoid == humanoid and not queuedUpdate.Processing then
			queuedUpdate.HumanoidDescription = humanoidDescription
			return
		end
	end

	table.insert(Mannequin.descriptionUpdateQueue, {
		Humanoid = humanoid,
		HumanoidDescription = humanoidDescription,
		Processing = false,
	})
end

function Mannequin.private:ProcessOutfitUpdates()
	while true do
		task.wait(1.00)
		local currentTime: number = os.time()

		for mannequinInstance, data in Mannequin.outfitAutoUpdateList do
			if currentTime - data.LastUpdate < data.RefreshTime or mannequinInstance.Destroyed then
				continue
			end

			data.LastUpdate = currentTime

			local outfitHumanoidDescription = Players:GetHumanoidDescriptionFromOutfitId(data.OutfitID)

			if
				Utils.AreHumanoidDescriptionsDifferent(mannequinInstance.HumanoidDescription, outfitHumanoidDescription)
			then
				mannequinInstance.HumanoidDescription = outfitHumanoidDescription

				Mannequin.private:QueueDescriptionUpdate(
					mannequinInstance.Humanoid,
					mannequinInstance.HumanoidDescription
				)
			end

			task.wait(0.10)
		end
	end
end

function Mannequin.private:DispatchDescriptionUpdates()
	local firstUpdate = Mannequin.descriptionUpdateQueue[1]
	if not firstUpdate or firstUpdate.Processing then
		return
	end

	local humanoidModel: Model? = firstUpdate.Humanoid.Parent :: Model?
	local humanoid: Humanoid = firstUpdate.Humanoid
	local humanoidDescription: HumanoidDescription = firstUpdate.HumanoidDescription

	firstUpdate.Processing = true

	if humanoidModel then
		-- when applying HumanoidDescription Roblox doesn't remove these, instead adds more of these Instances
		for _, childInstance in humanoidModel:GetChildren() do
			if childInstance:IsA("Shirt") or childInstance:IsA("Pants") or childInstance:IsA("ShirtGraphic") then
				childInstance:Destroy()
			end
		end

		-- Roblox is weird when it comes to applying description and the character
		-- 	mesh downscales to match scale of 1 so we reset the scale and bring it back
		--	after the description is updated
		local previousScale: number = humanoidModel:GetScale()
		humanoidModel:ScaleTo(1.00)
		humanoid:ApplyDescription(humanoidDescription)
		humanoidModel:ScaleTo(previousScale)
	end

	table.remove(Mannequin.descriptionUpdateQueue, 1)
end

--[=[
	@method IsHumanoidDescriptionDifferent
	@within ClothingDisplay.Mannequin

	@param humanoidDescription HumanoidDescription

	@return boolean

	Compares the mannequins humanoid description with the given description and returns true if they contain same description, false if they are different.
]=]
function Mannequin.prototype:IsHumanoidDescriptionDifferent(humanoidDescription: HumanoidDescription): boolean
	return Utils.AreHumanoidDescriptionsDifferent(self.HumanoidDescription, humanoidDescription)
end

--[=[
	@method SetBodyVisibility
	@within ClothingDisplay.Mannequin

	@param visible boolean

	Sets transparency of all of the BaseParts to 0.00 if visible is true or 1.00 if false
]=]
function Mannequin.prototype:SetBodyVisibility(visible: boolean)
	local transparency: number = visible and 0.00 or 1.00

	for _, instance: Instance in self.Instance:GetChildren() do
		if not instance:IsA("BasePart") then
			continue
		end

		-- Luau complaining about converting Instance to BasePart if we use continue
		local basePart: BasePart = instance :: BasePart

		if instance.Name == "Head" then
			for _, decalInstance: Instance in instance:GetChildren() do
				if decalInstance:IsA("Decal") then
					decalInstance.Transparency = transparency
				end
			end
		end

		basePart.Transparency = transparency
	end
end

--[=[
	@method HideBody
	@within ClothingDisplay.Mannequin

	Sets transparency of all of the BaseParts to 1.00
]=]
function Mannequin.prototype:HideBody()
	self:SetBodyVisibility(false)
end

--[=[
	@method ShowBody
	@within ClothingDisplay.Mannequin

	Sets transparency of all of the BaseParts to 0.00
]=]
function Mannequin.prototype:ShowBody()
	self:SetBodyVisibility(true)
end

--[=[
	@method SetBodyColor
	@within ClothingDisplay.Mannequin

	@param color3 Color3

	@return Mannequin

	Changes the body color on all of the body parts to a given color
]=]
function Mannequin.prototype:SetBodyColor(color3: Color3)
	Mannequin.private:CancelAutoRefresh(self)

	for _, bodyPart in Utils.GetColorBodyPartsList() do
		self.HumanoidDescription[bodyPart] = color3
	end

	Mannequin.private:QueueDescriptionUpdate(self.Humanoid, self.HumanoidDescription)
end

--[=[
	@method SetBodyColor
	@within ClothingDisplay.Mannequin

	@param faceID number

	@return Mannequin

	Changes the mannequins face to the given id
]=]
function Mannequin.prototype:SetFace(faceID: number)
	Mannequin.private:CancelAutoRefresh(self)

	-- TODO: check if the asset id is a face?
	self.HumanoidDescription["Face"] = faceID

	Mannequin.private:QueueDescriptionUpdate(self.Humanoid, self.HumanoidDescription)
end

--[=[
	@method OverwriteHumanoidDescription
	@within ClothingDisplay.Mannequin

	@param newHumanoidDescription HumanoidDescription

	@return Mannequin

	Overwrites everything within the HumanoidDescription with new HumanoidDescription
]=]
function Mannequin.prototype:OverwriteHumanoidDescription(newHumanoidDescription: HumanoidDescription)
	Mannequin.private:CancelAutoRefresh(self)

	self.HumanoidDescription = newHumanoidDescription

	Mannequin.private:QueueDescriptionUpdate(self.Humanoid, self.HumanoidDescription)
end

--[=[
	@method ApplyOutfit
	@within ClothingDisplay.Mannequin

	@param outfitID number
	@param refreshTime number?

	@return Mannequin

	Applies outfit from outfitID, if overwrite is active it will overwrite everything within Mannequin apart from BodyColors
]=]
function Mannequin.prototype:ApplyOutfit(outfitID: number, refreshTime: number?)
	local outfitHumanoidDescription = Players:GetHumanoidDescriptionFromOutfitId(outfitID)

	self.HumanoidDescription = outfitHumanoidDescription

	Mannequin.private:QueueDescriptionUpdate(self.Humanoid, self.HumanoidDescription)

	if refreshTime and refreshTime > 0 then
		Mannequin.outfitAutoUpdateList[self] = {
			OutfitID = outfitID,
			LastUpdate = os.time(),
			RefreshTime = refreshTime,
		}
	end
end

--[=[
	@method ApplyOutfitClothing
	@within ClothingDisplay.Mannequin

	@param outfitID number
	@param overwrite boolean?

	@return Mannequin

	Applies only outfit clothing from outfitID, if overwrite is active it will overwrite every clothing within Mannequin
]=]
function Mannequin.prototype:ApplyOutfitClothing(outfitID: number, overwrite: boolean?)
	Mannequin.private:CancelAutoRefresh(self)

	local outfitHumanoidDescription = Players:GetHumanoidDescriptionFromOutfitId(outfitID)

	if overwrite then
		self.HumanoidDescription:SetAccessories(outfitHumanoidDescription:GetAccessories(true), true)
		Mannequin.private:QueueDescriptionUpdate(self.Humanoid, self.HumanoidDescription)
		return
	end

	for _, accessory: HumanoidDescriptionAccessory in outfitHumanoidDescription:GetAccessories(true) do
		self:AddAccessory(accessory.AssetId)
	end
end

--[=[
	@method AddAccessory
	@within ClothingDisplay.Mannequin

	@param accessoryID number
	@param force boolean?

	@return Mannequin

	Adds an accessory to a Mannequin, if accessory is a body part it will change the body part. Force can be used if we don't want to unequip other conflicting accessories.
]=]
function Mannequin.prototype:AddAccessory(accessoryID: number, force: boolean?)
	Mannequin.private:CancelAutoRefresh(self)

	if Utils.HumanoidDescriptionContainsAccessory(self.HumanoidDescription, accessoryID) then
		warn(
			`Couldn't add accessory '{accessoryID}' to a Mannequin, it already has one. Instance path: {self.Instance:GetFullName()}`
		)
		return
	end

	local accessoryInfo = ProductInfo:Get(accessoryID)
	local accessoryType = Utils.AssetTypeIDToAccessoryType(accessoryInfo.AssetTypeId)

	if accessoryType == Enum.AccessoryType.Unknown then
		if Utils.AssetTypeIDToBodyPart(accessoryInfo.AssetTypeId) then
			self:ChangeBodyPart(accessoryID)
			return
		end

		warn(
			`Couldn't add accessory '{accessoryID}' to a Mannequin, AccessoryType == Unknown. Instance path: {self.Instance:GetFullName()}`
		)
		return
	end

	local currentAccessories: { HumanoidDescriptionAccessory } = self.HumanoidDescription:GetAccessories(true)

	-- remove conflicting accessories
	if not force then
		for i = #currentAccessories, 1, -1 do
			local accessory = currentAccessories[i]

			if accessory.AccessoryType == Enum.AccessoryType.Hat then
				if Utils.GetAccessoryTypeCount(currentAccessories, Enum.AccessoryType.Hat) >= 3 then
					table.remove(currentAccessories, i)
				end
			elseif Utils.DoAccessoriesConflict(accessory.AccessoryType, accessoryType) then
				table.remove(currentAccessories, i)
			end
		end
	end

	table.insert(currentAccessories, {
		AccessoryType = accessoryType,
		AssetId = accessoryID,
		IsLayered = true,
		Order = Utils.GetAccessoryOrder(accessoryType),
	})

	self.HumanoidDescription:SetAccessories(currentAccessories, true)
	Mannequin.private:QueueDescriptionUpdate(self.Humanoid, self.HumanoidDescription)
end

--[=[
	@method RemoveAccessory
	@within ClothingDisplay.Mannequin

	@param accessoryID number

	@return Mannequin

	Removes an Accessory from a Mannequin if it contains that accessory
]=]
function Mannequin.prototype:RemoveAccessory(accessoryID: number)
	Mannequin.private:CancelAutoRefresh(self)

	local currentAccessories: { HumanoidDescriptionAccessory } = self.HumanoidDescription:GetAccessories(true)

	local removed = false
	for accessoryIndex, accessory in currentAccessories do
		if accessory.AssetId == accessoryID then
			table.remove(currentAccessories, accessoryIndex)
			removed = true
			break
		end
	end

	if not removed then
		warn(
			`Tried to remove an accessory '{accessoryID}' from a Mannequin because it's not applied. Instance path: {self.Instance:GetFullName()}`
		)
		return
	end

	self.HumanoidDescription:SetAccessories(currentAccessories, true)
	Mannequin.private:QueueDescriptionUpdate(self.Humanoid, self.HumanoidDescription)
end

--[=[
	@method ChangeBodyPart
	@within ClothingDisplay.Mannequin

	@param bodyPartID number

	@return Mannequin

	Changes body part on a Mannequin to a given one if it's valid
]=]
function Mannequin.prototype:ChangeBodyPart(bodyPartID: number)
	Mannequin.private:CancelAutoRefresh(self)

	local bodyPartInfo = ProductInfo:Get(bodyPartID)
	local bodyPartType = Utils.AssetTypeIDToBodyPart(bodyPartInfo.AssetTypeId)

	if not bodyPartType then
		warn(
			`Couldn't change body part '{bodyPartID}' to a Mannequin, BodyPart == nil. Instance path: {self.Instance:GetFullName()}`
		)
		return
	end

	self.HumanoidDescription[bodyPartType.Name] = bodyPartID
	Mannequin.private:QueueDescriptionUpdate(self.Humanoid, self.HumanoidDescription)
end

--[=[
	@method Destroy
	@within ClothingDisplay.Mannequin

	Destroys the Mannequin references and destroys the mannequin Instance
]=]
function Mannequin.prototype:Destroy()
	Mannequin.private:CancelAutoRefresh(self)

	self.Instance:Destroy()
	self.Instance = nil
	self.Humanoid = nil
	self.HumanoidDescription = nil
	self.Destroyed = true

	self.HipHeightChangedConnection:Disconnect()
	self.HipHeightChangedConnection = nil
end

--[=[
	@method PivotTo
	@within ClothingDisplay.Mannequin

	A wrapper for Mannequin.Instance:PivotTo()
]=]
function Mannequin.prototype:PivotTo(cframe: CFrame)
	self.Instance:PivotTo(cframe)
end

--[=[
	@method GetPivot
	@within ClothingDisplay.Mannequin

	@return CFrame

	A wrapper for Mannequin.Instance:GetPivot()
]=]
function Mannequin.prototype:GetPivot(): CFrame
	return self.Instance:GetPivot()
end

--[=[
	@method GetAnimator
	@within ClothingDisplay.Mannequin

	@return Animator?

	A wrapper for getting Humanoid Animator
]=]
function Mannequin.prototype:GetAnimator(): Animator?
	return self.Humanoid:FindFirstChildOfClass("Animator")
end

--[=[
	@method GetAnimator
	@within ClothingDisplay.Mannequin

	@param scale number

	A wrapper for Model:ScaleTo
]=]
function Mannequin.prototype:ScaleTo(scale: number)
	self.Instance:ScaleTo(scale)
end

--[=[
	@method GetAnimator
	@within ClothingDisplay.Mannequin

	@param scale number

	@return number

	A wrapper for Model:GetScale
]=]
function Mannequin.prototype:GetScale(): number
	return self.Instance:GetScale()
end

--[=[
	@method PlayAnimation
	@within ClothingDisplay.Mannequin

	@param animationID string

	Plays animation on the Mannequin, it's basically a wrapper for playing Animation by getting Animator and creating new AnimationTrack.
]=]
function Mannequin.prototype:PlayAnimation(animationID: string)
	local animator: Animator? = self:GetAnimator()
	if not animator then
		return
	end

	local animation: Animation = Instance.new("Animation")
	animation.AnimationId = animationID

	local animationTrack: AnimationTrack = animator:LoadAnimation(animation)
	animationTrack.Looped = true
	animationTrack:Play()

	animation:Destroy()
end

--[=[
	@method PlayAnimation
	@within ClothingDisplay.Mannequin

	@param animationID string
	@param poseTime number

	Does exactly the same thing as Mannequin:PlayAnimation() but with an option to "freeze" the animation at the choosen timestamp
]=]
function Mannequin.prototype:PoseFromAnimation(animationID: string, poseTime: number)
	local animator: Animator? = self:GetAnimator()
	if not animator then
		return
	end

	local animation: Animation = Instance.new("Animation")
	animation.AnimationId = animationID

	local animationTrack: AnimationTrack = animator:LoadAnimation(animation)
	animationTrack.Looped = true
	animationTrack:Play()

	animation:Destroy()

	animationTrack.TimePosition = poseTime
	animationTrack:AdjustSpeed(0.00)
end

--[=[
	@method new
	@within ClothingDisplay.Mannequin

	@param rigType Enum.HumanoidRigType
	@param humanoidDescription HumanoidDescription?

	@return Mannequin

	Creates new empty Mannequin from Rig Type with optional Humanoid Description, the default one is a blocky character with a black skin color.
]=]
function Mannequin.interface.new(rigType: Enum.HumanoidRigType, humanoidDescription: HumanoidDescription?)
	return Mannequin.interface.fromModel(
		Players:CreateHumanoidModelFromDescription(humanoidDescription or Instance.new("HumanoidDescription"), rigType)
	)
end

--[=[
	@method fromModel
	@within ClothingDisplay.Mannequin

	@param model Model

	@return Mannequin

	Creates new Mannequin object from a Model, useful if further modifications to the outfit are needed based on a Mannequin that is already within the workspace.
]=]
function Mannequin.interface.fromModel(model: Model)
	assert(
		typeof(model) == "Instance" and model:IsA("Model"),
		"Tried to create a Mannequin but Model wasn't provided or given instance is not a Model!"
	)

	local humanoid: Humanoid? = model:FindFirstChildOfClass("Humanoid")
	assert(
		typeof(humanoid) == "Instance" and humanoid:IsA("Humanoid"),
		"Tried to create a Mannequin from a Model but it isn't a Humanoid!"
	)

	assert(model.PrimaryPart, "Tried to create a Mannequin from a Model but its PrimaryPart is not set.")

	model.PrimaryPart.Anchored = true

	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

	local self = setmetatable({
		Instance = model,
		Humanoid = humanoid,
		HumanoidDescription = humanoid:GetAppliedDescription(),
		HipHeight = humanoid.HipHeight,
		PrimaryPartHeight = model.PrimaryPart.Size.Y,
		Destroyed = false,
	}, {
		__index = Mannequin.prototype,
	})

	self.HipHeightChangedConnection = humanoid:GetPropertyChangedSignal("HipHeight"):Connect(function()
		local primaryPartHeightDelta = 0
		if self.Instance.PrimaryPart then
			primaryPartHeightDelta = self.PrimaryPartHeight - self.Instance.PrimaryPart.Size.Y
			self.PrimaryPartHeight = self.Instance.PrimaryPart.Size.Y
		end

		local hipHeightDelta = self.HipHeight - self.Humanoid.HipHeight
		self.HipHeight = self.Humanoid.HipHeight

		-- https://create.roblox.com/docs/reference/engine/classes/Humanoid#HipHeight
		-- Height = (0.50 * RootPart.Size.Y) + HipHeight
		local totalDifference = (primaryPartHeightDelta * 0.50) + hipHeightDelta

		task.defer(function()
			local mannequinCFrame = self.Instance:GetPivot()
			self.Instance:PivotTo(mannequinCFrame - (mannequinCFrame.UpVector * totalDifference))
		end)
	end)

	-- Disable all humanoid states as Mannequins should be static Models
	for _, stateType in Enum.HumanoidStateType:GetEnumItems() do
		if stateType == Enum.HumanoidStateType.None then
			continue
		end

		humanoid:SetStateEnabled(stateType, false)
	end

	return self
end

--[=[
	@method fromOutfitID
	@within ClothingDisplay.Mannequin

	@param outfitID number
	@param humanoidRigType Enum.HumanoidRigType?

	@return Mannequin

	Creates new Mannequin from an Outfit ID, it's very niche use case but it's useful for "dynamically" updating outfits on mannequins within games.
]=]
function Mannequin.interface.fromOutfitID(outfitID: number, humanoidRigType: Enum.HumanoidRigType?)
	return Mannequin.interface.new(
		humanoidRigType or Enum.HumanoidRigType.R15,
		Players:GetHumanoidDescriptionFromOutfitId(outfitID)
	)
end

RunService.Heartbeat:Connect(function()
	Mannequin.private:DispatchDescriptionUpdates()
end)

task.spawn(Mannequin.private.ProcessOutfitUpdates, Mannequin.private)

return Mannequin.interface
