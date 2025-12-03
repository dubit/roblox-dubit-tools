local Players = game:GetService("Players")

local Signal = require(script.Parent.Parent.Shared.Signal)
local Constants = require(script.Parent.Parent.Shared.Constants)

local statusChangedSignal = Signal.new()

local Authorization = {
	StatusChanged = statusChangedSignal,
}

function Authorization.IsLocalPlayerAuthorized(self)
	assert(self == Authorization, "Expected ':' not '.' calling member function IsLocalPlayerAuthorized")

	local authorized

	repeat
		task.wait()
		authorized = Players.LocalPlayer:GetAttribute(Constants.IS_AUTHORIZED_ATTRIBUTE)
	until typeof(authorized) == "boolean"

	return authorized
end

Players.LocalPlayer:GetAttributeChangedSignal(Constants.IS_AUTHORIZED_ATTRIBUTE):Connect(function()
	local isAuthorized = Players.LocalPlayer:GetAttribute(Constants.IS_AUTHORIZED_ATTRIBUTE) == true
	statusChangedSignal:Fire(isAuthorized)
end)

return Authorization
