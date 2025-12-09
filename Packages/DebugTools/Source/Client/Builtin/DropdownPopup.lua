local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local DebugToolRootPath = script.Parent.Parent

local Constants = require(DebugToolRootPath.Parent.Shared.Constants)

local Imgui = require(DebugToolRootPath.IMGui)

local DropdownPopup = {}

local function isPointInFrame(frame: Frame, point: Vector2)
	local insetSize = GuiService:GetGuiInset()
	local framePosition: Vector2 = frame.AbsolutePosition
	framePosition += insetSize

	local frameSize = frame.AbsoluteSize
	local mouseRelativePositon = point - framePosition
	return mouseRelativePositon.X >= 0
		and mouseRelativePositon.X <= frameSize.X
		and mouseRelativePositon.Y >= 0
		and mouseRelativePositon.Y <= frameSize.Y
end

function DropdownPopup.new<T>(
	parentInstance: GuiObject,
	options: { T },
	initialValue: T,
	selected: (T) -> (),
	closed: (() -> ())?
)
	local connections = table.create(#options)

	local insetSize = GuiService:GetGuiInset()

	local absolutePosition = parentInstance.AbsolutePosition
	absolutePosition += insetSize
	local absoluteSize = parentInstance.AbsoluteSize

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "Dropdown"
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = Constants.DROPDOWN_DISPLAY_ORDER
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local function destroy()
		screenGui:Destroy()

		for _, connection in connections do
			connection:Disconnect()
		end
	end

	local dropdownFrame = Instance.new("Frame")
	dropdownFrame.AutomaticSize = Enum.AutomaticSize.Y
	dropdownFrame.Position = UDim2.fromOffset(absolutePosition.X, absolutePosition.Y + absoluteSize.Y)
	dropdownFrame.Size = UDim2.fromOffset(absoluteSize.X, absoluteSize.Y)
	dropdownFrame.BackgroundTransparency = 1.00
	dropdownFrame.Parent = screenGui

	local uiListLayout = Instance.new("UIListLayout")
	uiListLayout.Parent = dropdownFrame

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
			connections,
			dropdownOption.Activated:Connect(function()
				destroy()
				selected(option)
			end)
		)
	end

	screenGui.Parent = Players.LocalPlayer.PlayerGui

	table.insert(
		connections,
		parentInstance:GetPropertyChangedSignal("AbsolutePosition"):Once(function()
			destroy()
			if closed then
				closed()
			end
		end)
	)

	table.insert(
		connections,
		parentInstance:GetPropertyChangedSignal("AbsoluteSize"):Once(function()
			destroy()
			if closed then
				closed()
			end
		end)
	)

	local isInitialClick = true
	table.insert(
		connections,
		UserInputService.InputEnded:Connect(function(inputObject)
			if inputObject.UserInputType ~= Enum.UserInputType.MouseButton1 then
				return
			end

			local insetSize = GuiService:GetGuiInset()
			local mousePosition = Vector2.new(inputObject.Position.X, inputObject.Position.Y)
			mousePosition += insetSize

			if not isInitialClick and not isPointInFrame(dropdownFrame, mousePosition) then
				destroy()

				if closed then
					closed()
				end
			end

			isInitialClick = false
		end)
	)

	return {
		Destroy = function(self)
			destroy()
		end,
	}
end

return DropdownPopup
