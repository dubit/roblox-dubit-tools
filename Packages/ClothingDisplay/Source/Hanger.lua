--!strict

--[=[
	@class ClothingDisplay.Hanger
]=]

local InsertService = game:GetService("InsertService")

local Types = require(script.Parent.Types)

local Hanger = {}
Hanger.interface = {}
Hanger.prototype = {}
Hanger.private = {}

function Hanger.private.prepareModel(accessoryID: number): Model?
	local success: boolean, instance: Instance = pcall(InsertService.LoadAsset, InsertService, accessoryID)
	if not success or instance.ClassName ~= "Model" then
		return
	end

	for _, desecendantInstance: Instance in instance:GetDescendants() do
		--[[ Thumbnail Configuration is useless in this case we don't need it and
			it's using bandwidth when replicating.
			WrapLayer prevents the Accessory from being scaled ]]
		if
			(desecendantInstance.Name == "ThumbnailConfiguration" and desecendantInstance:IsA("Configuration"))
			or desecendantInstance:IsA("WrapLayer")
		then
			desecendantInstance:Destroy()
		end

		if not desecendantInstance:IsA("BasePart") then
			continue
		end

		desecendantInstance.CanCollide = false
		desecendantInstance.CanTouch = false
		desecendantInstance.CanQuery = false
		desecendantInstance.Anchored = true
	end

	return instance :: Model
end

--[=[
	@method PivotTo
	@within ClothingDisplay.Hanger

	A wrapper for Hanger.Instance:PivotTo()
]=]
function Hanger.prototype.PivotTo(self: Types.Hanger, cframe: CFrame)
	self.Instance:PivotTo(cframe)
end

--[=[
	@method GetPivot
	@within ClothingDisplay.Hanger

	@return CFrame

	A wrapper for Hanger.Instance:GetPivot()
]=]
function Hanger.prototype.GetPivot(self: Types.Hanger): CFrame
	return self.Instance:GetPivot()
end

--[=[
	@method ScaleTo
	@within ClothingDisplay.Hanger

	A wrapper for Hanger.Instance:ScaleTo()
]=]
function Hanger.prototype.ScaleTo(self: Types.Hanger, scale: number)
	return self.Instance:ScaleTo(scale)
end

--[=[
	@method ScaleTo
	@within ClothingDisplay.Hanger

	@return number

	A wrapper for Hanger.Instance:GetScale()
]=]
function Hanger.prototype.GetScale(self: Types.Hanger): number
	return self.Instance:GetScale()
end

--[=[
	@method Destroy
	@within ClothingDisplay.Hanger

	Destroys the instance
]=]
function Hanger.prototype.Destroy(self: Types.Hanger)
	self.Instance:Destroy()
end

--[=[
	@method ChangeTo
	@within ClothingDisplay.Hanger

	@param accessoryID number

	Changes the model to a different accessory if the given accessoryID is valid
]=]
function Hanger.prototype.ChangeTo(self: Types.Hanger, accessoryID: number)
	if self.AccessoryID == accessoryID then
		warn(
			`Tried to change Hanger Accessory but it's already that accessory. Instance path: {self.Instance:GetFullName()}`
		)
		return
	end

	self.AccessoryID = accessoryID

	local newModel: Model? = Hanger.private.prepareModel(accessoryID)
	if not newModel then
		return
	end

	newModel.Name = self.Instance.Name
	newModel:PivotTo(self.Instance:GetPivot())
	newModel:ScaleTo(self.Instance:GetScale())
	newModel.Parent = self.Instance.Parent

	self.Instance:Destroy()
	self.Instance = newModel
end

--[=[
	@method new
	@within ClothingDisplay.Hanger

	@param accessoryID number

	@return Hanger

	Creates new accessory model if the given accessoryID is valid
]=]
function Hanger.interface.new(accessoryID: number): Types.Hanger?
	local newModel: Model? = Hanger.private.prepareModel(accessoryID)
	if not newModel then
		return
	end

	return setmetatable(
		{
			Instance = newModel,

			AccessoryID = accessoryID,
		} :: any,
		{
			__index = Hanger.prototype,
		}
	)
end

return Hanger.interface
