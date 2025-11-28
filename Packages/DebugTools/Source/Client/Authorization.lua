local Players = game:GetService("Players")

local Constants = require(script.Parent.Parent.Shared.Constants)

local Authorization = {}

function Authorization.IsLocalPlayerAuthorized(self)
	assert(self == Authorization, "Expected ':' not '.' calling member function IsLocalPlayerAuthorized")

	local authorized

	repeat
		task.wait()
		authorized = Players.LocalPlayer:GetAttribute(Constants.IS_AUTHORIZED_ATTRIBUTE)
	until typeof(authorized) == "boolean"

	return authorized
end

return Authorization
