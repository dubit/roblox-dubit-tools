--[[
	This is a helper function to enable us to test our components with TestEz.
	It creates a new instance of the "Chassis" component for each unit test, so we are able to have a
	clean slate for each unit test without worrying of results from previous tests carrying over.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DubitChassis = require(ReplicatedStorage.Packages.DubitChassis)

local chassis = ReplicatedStorage.Assets.Kart

local function generatePrototype(): (any, Model)
	local prototype

	local testChassis = chassis:Clone()
	testChassis.Parent = workspace

	DubitChassis.OnChassisRegistered:Wait()

	prototype = DubitChassis:FromInstance(testChassis)

	return prototype, testChassis
end

return generatePrototype
