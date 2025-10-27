--[[
	This is a helper function to enable us to test our components with TestEz.
	This removes the instance used in the "Chassis" component unit test, so we are able to have a
	clean slate for each unit test without worrying of results from previous tests carrying over.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local OnRemovePrototype = ReplicatedStorage.Assets.Remotes.OnRemovePrototype

local function removePrototype(currentChassis: Model)
	OnRemovePrototype:FireServer(currentChassis)
end

return removePrototype
