--[[
	This is a helper function to enable us to test our components with TestEz.
	It creates a new instance of the "Chassis" component for each unit test, so we are able to have a
	clean slate for each unit test without worrying of results from previous tests carrying over.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DubitChassis = require(ReplicatedStorage.Packages.DubitChassis)

local OnGeneratePrototype = ReplicatedStorage.Assets.Remotes.OnGeneratePrototype

local function generatePrototype(): (any, Model)
	local currentChassis = OnGeneratePrototype:InvokeServer()

	if not DubitChassis:FromInstance(currentChassis) then
		DubitChassis.OnChassisRegistered:Wait()
	end

	return DubitChassis:FromInstance(currentChassis), currentChassis
end

return generatePrototype
