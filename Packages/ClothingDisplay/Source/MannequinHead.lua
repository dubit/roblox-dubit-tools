--!strict

--[=[
	@class ClothingDisplay.MannequinHead
]=]

local Players = game:GetService("Players")

local Utils = require(script.Parent.Utils)
local ProductInfo = require(script.Parent.ProductInfo)

local Types = require(script.Parent.Types)

type MannequinHeadData = {
	Accessories: { number },
	HeadPartID: number,
	BodyColor: Color3,
}

local MannequinHead = {}
MannequinHead.interface = {}
MannequinHead.prototype = {}
MannequinHead.private = {}
MannequinHead.data = {} :: { [Types.MannequinHead]: MannequinHeadData }

function MannequinHead.private.createMannequinHead(headID: number, headColor3: Color3, accessories: { number }?): Model?
	local headAccessories: { number } = accessories or {}

	local humanoidDescription: HumanoidDescription = Instance.new("HumanoidDescription")
	humanoidDescription.Head = headID
	humanoidDescription.HeadColor = headColor3

	local humanoidDescriptionAccessories = {}
	for _, accessory: number in headAccessories do
		local accessoryInfo = ProductInfo:Get(accessory)
		local accessoryType = Utils.AssetTypeIDToAccessoryType(accessoryInfo.AssetTypeId)

		table.insert(humanoidDescriptionAccessories, {
			AccessoryType = accessoryType,
			AssetId = accessory,
			IsLayered = false,
		})
	end
	humanoidDescription:SetAccessories(humanoidDescriptionAccessories, true)

	local humanoidModel: Model =
		Players:CreateHumanoidModelFromDescription(humanoidDescription, Enum.HumanoidRigType.R15)

	local headPart: Instance? = humanoidModel:FindFirstChild("Head")
	if not headPart or not headPart:IsA("BasePart") then
		humanoidModel:Destroy()
		return nil
	end

	local mannequinHeadModel: Model = Instance.new("Model")
	mannequinHeadModel.Name = "MannequinHead"

	headPart.CFrame = CFrame.new()
	headPart.PivotOffset = headPart.PivotOffset - headPart.PivotOffset.Position
	headPart.Anchored = true
	headPart.Parent = mannequinHeadModel

	mannequinHeadModel.PrimaryPart = headPart

	for _, childInstance: Instance in humanoidModel:GetChildren() do
		if childInstance:IsA("Accessory") then
			childInstance.Parent = mannequinHeadModel

			-- TouchTransmitters get added after a frame
			task.defer(function()
				local touchInterest = childInstance:FindFirstChildWhichIsA("TouchTransmitter", true)
				if touchInterest then
					touchInterest:Destroy()
				end
			end)
		end
	end

	humanoidModel:Destroy()

	return mannequinHeadModel
end

function MannequinHead.private.regenerateMannequinHead(mannequinHead: Types.MannequinHead)
	local mannequinHeadData = MannequinHead.data[mannequinHead]

	local newMannequinHead = MannequinHead.private.createMannequinHead(
		mannequinHeadData.HeadPartID,
		mannequinHeadData.BodyColor,
		mannequinHeadData.Accessories
	)

	if newMannequinHead then
		newMannequinHead:ScaleTo(mannequinHead.Instance:GetScale())

		local oldInstance: Model = mannequinHead.Instance

		newMannequinHead:PivotTo(mannequinHead.Instance:GetPivot())
		newMannequinHead.Parent = mannequinHead.Instance.Parent

		mannequinHead.Instance = newMannequinHead

		oldInstance:Destroy()
	end
end

--[=[
	@method PivotTo
	@within ClothingDisplay.MannequinHead

	A wrapper for MannequinHead.Instance:PivotTo()
]=]
function MannequinHead.prototype.PivotTo(self: Types.MannequinHead, cframe: CFrame)
	self.Instance:PivotTo(cframe)
end

--[=[
	@method GetPivot
	@within ClothingDisplay.MannequinHead

	@return CFrame

	A wrapper for MannequinHead.Instance:GetPivot()
]=]
function MannequinHead.prototype.GetPivot(self: Types.MannequinHead): CFrame
	return self.Instance:GetPivot()
end

--[=[
	@method ScaleTo
	@within ClothingDisplay.MannequinHead

	A wrapper for MannequinHead.Instance:ScaleTo()
]=]
function MannequinHead.prototype.ScaleTo(self: Types.MannequinHead, scale: number)
	return self.Instance:ScaleTo(scale)
end

--[=[
	@method ScaleTo
	@within ClothingDisplay.MannequinHead

	@return number

	A wrapper for MannequinHead.Instance:GetScale()
]=]
function MannequinHead.prototype.GetScale(self: Types.MannequinHead): number
	return self.Instance:GetScale()
end

--[=[
	@method Destroy
	@within ClothingDisplay.MannequinHead

	Destroys the instance
]=]
function MannequinHead.prototype.Destroy(self: Types.MannequinHead)
	self.Instance:Destroy()

	MannequinHead.data[self] = nil
end

--[=[
	@method SetBodyColor
	@within ClothingDisplay.MannequinHead

	@param color3 Color3

	@return MannequinHead

	Changes the head color to a given color
]=]
function MannequinHead.prototype.SetBodyColor(self: Types.MannequinHead, color3: Color3)
	local mannequinHeadData = MannequinHead.data[self]
	mannequinHeadData.BodyColor = color3

	if self.Instance.PrimaryPart then
		self.Instance.PrimaryPart.Color = mannequinHeadData.BodyColor
	end
end

--[=[
	@method AddAccessory
	@within ClothingDisplay.MannequinHead

	@param accessoryID number

	Adds given accessory to the Mannequin Head if it wasn't added before
]=]
function MannequinHead.prototype.AddAccessory(self: Types.MannequinHead, accessoryID: number)
	local mannequinHeadData = MannequinHead.data[self]

	if table.find(mannequinHeadData.Accessories, accessoryID) then
		return
	end

	table.insert(mannequinHeadData.Accessories, accessoryID)

	MannequinHead.private.regenerateMannequinHead(self)
end

--[=[
	@method RemoveAccessory
	@within ClothingDisplay.MannequinHead

	@param accessoryID number

	Removes given accessory from the Mannequin Head if it was added before
]=]
function MannequinHead.prototype.RemoveAccessory(self: Types.MannequinHead, accessoryID: number)
	local mannequinHeadData = MannequinHead.data[self]

	local accessoryIndex: number? = table.find(mannequinHeadData.Accessories, accessoryID)
	if not accessoryIndex then
		return
	end

	table.remove(mannequinHeadData.Accessories, accessoryIndex)

	MannequinHead.private.regenerateMannequinHead(self)
end

--[=[
	@method RemoveAllAccessories
	@within ClothingDisplay.MannequinHead

	@param accessoryID number

	Removes all applied accessories
]=]
function MannequinHead.prototype.RemoveAllAccessories(self: Types.MannequinHead)
	local mannequinHeadData = MannequinHead.data[self]

	mannequinHeadData.Accessories = {}

	MannequinHead.private.regenerateMannequinHead(self)
end

--[=[
	@method GetAccessories
	@within ClothingDisplay.MannequinHead

	Returns all applied accessories
]=]
function MannequinHead.prototype.GetAccessories(self: Types.MannequinHead): { number }
	return MannequinHead.data[self].Accessories
end

--[=[
	@method new
	@within ClothingDisplay.MannequinHead

	@param headID number?
	@param bodyColor3 Color3?

	@return MannequinHead

	Creates new accessory model if the given accessoryID is valid
]=]
function MannequinHead.interface.new(headID: number?, bodyColor3: Color3?): Types.MannequinHead?
	-- https://www.roblox.com/catalog/14488197116/Faceless-Dynamic-Head
	-- the faceless head that is available on Marketplace
	local headBodyPartID: number = headID or 14488197116
	local headColor: Color3 = bodyColor3 or Color3.fromRGB(127, 127, 127) -- 127, 127, 127 is the default avatar color

	local newModel: Model? = MannequinHead.private.createMannequinHead(headBodyPartID, headColor)
	if not newModel then
		return nil
	end

	local self: Types.MannequinHead = setmetatable(
		{
			Instance = newModel,
		} :: any,
		{
			__index = MannequinHead.prototype,
		}
	) :: Types.MannequinHead

	MannequinHead.data[self] = {
		Accessories = {},
		HeadPartID = headBodyPartID,
		BodyColor = headColor,
	}

	return self
end

return MannequinHead.interface
