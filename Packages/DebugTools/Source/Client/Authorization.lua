local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Constants = require(script.Parent.Parent.Shared.Constants)

local Authorization = {}
Authorization.internal = {}
Authorization.interface = {}

--[[
	Yields until the DEBUGTOOLS_ISAUTHORIZED attribute is found under the player, or the timeout is reached
]]
function Authorization.waitForAuthorizationAttribute(timeout: number)
	local startTime = tick()
	while true do
		if Players.LocalPlayer:GetAttribute(Constants.IS_AUTHORIZED_ATTRIBUTE) ~= nil then
			break
		end

		if tick() - startTime > timeout then
			break
		end

		task.wait()
	end
end

function Authorization.interface.isLocalPlayerAuthorized(): boolean
	if RunService:IsStudio() then
		return true
	end

	Authorization.waitForAuthorizationAttribute(5)

	return Players.LocalPlayer:GetAttribute(Constants.IS_AUTHORIZED_ATTRIBUTE) == true
end

return Authorization.interface
