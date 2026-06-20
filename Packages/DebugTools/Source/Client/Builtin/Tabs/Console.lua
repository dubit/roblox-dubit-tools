local DebugToolRootPath = script.Parent.Parent.Parent

local Tab = require(DebugToolRootPath.Tab)
local IMGui = require(DebugToolRootPath.IMGui)
local Console = require(DebugToolRootPath.Console)

Tab.new("Console", function(parent: Frame)
	local currentOutput = Console:GetOutputLog()

	return IMGui:Connect(parent, function()
		IMGui:BeginVertical()

		IMGui:ScrollingFrameY(UDim2.fromScale(1, 1))
		IMGui:TextBox(currentOutput, true, Enum.TextXAlignment.Left, Enum.TextYAlignment.Top)
		IMGui:End()

		IMGui:Label("The output is a snapshot from when the tab was opened, not real-time.")

		IMGui:End()
	end)
end)

return nil