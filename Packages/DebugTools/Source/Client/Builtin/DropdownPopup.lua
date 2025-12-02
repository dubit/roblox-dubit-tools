--!strict
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local DebugToolRootPath = script.Parent.Parent

local Signal = require(DebugToolRootPath.Parent.Shared.Signal)
local Constants = require(DebugToolRootPath.Parent.Shared.Constants)

local Imgui = require(DebugToolRootPath.IMGui)

local DropdownPopup = {}
DropdownPopup.prototype = {}
DropdownPopup.interface = {}

function DropdownPopup.prototype:IsPointInDropdown(point: Vector2)
	local insetSize: Vector2 = GuiService:GetGuiInset()
	local framePosition: Vector2 = self.DropdownFrame.AbsolutePosition
	framePosition += insetSize

	local frameSize: Vector2 = self.DropdownFrame.AbsoluteSize
	local mouseRelativePositon: Vector2 = point - framePosition
	return mouseRelativePositon.X >= 0
		and mouseRelativePositon.X <= frameSize.X
		and mouseRelativePositon.Y >= 0
		and mouseRelativePositon.Y <= frameSize.Y
end

function DropdownPopup.prototype:Destroy()
	self.Closed:Fire()
	self.Closed:Destroy()

	self.ScreenGui:Destroy()
	self.InputEndedConnection:Disconnect()
	self.EntrySelected:Destroy()

	for _, connection in self.OptionSelectedConnections do
		connection:Disconnect()
	end
end

function DropdownPopup.interface.new(parentInstance: GuiObject, options: { string }, initialValue: string)
	local self

	local insetSize = GuiService:GetGuiInset()

	local entrySelectedSignal: Signal.Signal<string> = Signal.new()
	local closedSignal: Signal.Signal<()> = Signal.new()

	local absolutePosition = parentInstance.AbsolutePosition
	absolutePosition += insetSize
	local absoluteSize = parentInstance.AbsoluteSize

	local screenGui: ScreenGui = Instance.new("ScreenGui")
	screenGui.Name = "Dropdown"
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = Constants.DROPDOWN_DISPLAY_ORDER
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local dropdownFrame = Instance.new("Frame")
	dropdownFrame.Name = "Frame"
	dropdownFrame.AutomaticSize = Enum.AutomaticSize.Y
	dropdownFrame.Position = UDim2.fromOffset(absolutePosition.X, absolutePosition.Y + absoluteSize.Y)
	dropdownFrame.Size = UDim2.fromOffset(absoluteSize.X, absoluteSize.Y)
	dropdownFrame.BackgroundTransparency = 1.00
	dropdownFrame.Parent = screenGui

	local uiListLayout = Instance.new("UIListLayout")
	uiListLayout.Parent = dropdownFrame

	local optionSelectedConnections: { RBXScriptConnection } = table.create(#options)
	for _, option in options do
		local dropdownOption = Instance.new("TextButton")
		dropdownOption.AutoLocalize = false
		dropdownOption.Size = UDim2.fromOffset(absoluteSize.X, absoluteSize.Y)
		dropdownOption.BackgroundColor3 = parentInstance.BackgroundColor3
		dropdownOption.BorderSizePixel = 0
		dropdownOption.Text = tostring(option)
		dropdownOption.TextXAlignment = Enum.TextXAlignment.Left
		dropdownOption.Parent = dropdownFrame

		Imgui.applyTextStyle(dropdownOption)

		table.insert(
			optionSelectedConnections,
			dropdownOption.Activated:Connect(function()
				entrySelectedSignal:Fire(option)
				self:Destroy()
			end)
		)
	end

	screenGui.Parent = Players.LocalPlayer.PlayerGui

	self = setmetatable({
		Value = initialValue,
		Parent = parentInstance,
		Options = options,

		ScreenGui = screenGui,
		DropdownFrame = dropdownFrame,
		EntrySelected = entrySelectedSignal,
		OptionSelectedConnections = optionSelectedConnections,
		Closed = closedSignal,
	}, {
		__index = DropdownPopup.prototype,
	})

	task.defer(function()
		local isInitialClick = true
		self.InputEndedConnection = UserInputService.InputEnded:Connect(function(inputObject: InputObject)
			if inputObject.UserInputType ~= Enum.UserInputType.MouseButton1 then
				return
			end

			local insetSize: Vector2 = GuiService:GetGuiInset()
			local mousePosition: Vector2 = Vector2.new(inputObject.Position.X, inputObject.Position.Y)
			mousePosition += insetSize

			if not isInitialClick and not self:IsPointInDropdown(mousePosition) then
				self:Destroy()
			end

			isInitialClick = false
		end)
	end)

	return self
end

return DropdownPopup.interface
