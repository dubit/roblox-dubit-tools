local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

--[[
	Note - This utility class is named unlike other DubitUtils classes as "Instance"
	is an existing member of the Roblox API.
]]
local InstanceUtility = {}

function InstanceUtility.verifyInstance(
	instanceName: string,
	instanceType: string,
	instanceParent: Instance?,
	timeout: number?
): Instance?
	if typeof(instanceType) ~= "string" then
		warn(`Expected instanceType to be of type string, got {typeof(instanceType)}`)
		return nil
	end

	local finalInstanceParent = if typeof(instanceParent) == "Instance" then instanceParent else workspace
	timeout = if typeof(timeout) == "number" then timeout else 0

	local existingInstance
	if timeout > 0 then
		existingInstance = finalInstanceParent:WaitForChild(instanceName, timeout)
	else
		existingInstance = finalInstanceParent:FindFirstChild(instanceName)
	end

	if existingInstance and existingInstance:IsA(instanceType) then
		return existingInstance
	elseif existingInstance then
		warn(`Found instance '{instanceName}' is not of type '{instanceType}', creating new instance of given type`)
	end

	local newInstance = Instance.new(instanceType)
	newInstance.Name = instanceName
	newInstance.Parent = instanceParent

	return newInstance
end

function InstanceUtility.waitForChildren(instance: Instance, childrenString: string, timeout: number?): Instance?
	local childrenSplit = childrenString:split(".")
	local child = instance

	timeout = if typeof(timeout) == "number" then timeout else 5

	for _, childName in childrenSplit do
		child = child:WaitForChild(childName, timeout)

		if not child then
			return nil
		end
	end

	return child
end

function InstanceUtility.findInstance(parent: Instance, path: string): Instance?
	local instance = parent
	local paths = path:split(".")

	for _, childName in paths do
		instance = instance:FindFirstChild(childName)

		if instance == nil then
			return nil
		end
	end

	return instance
end

function InstanceUtility.setDescendantTransparency(instance: Instance, transparency: number)
	if instance:IsA("BasePart") then
		if RunService:IsClient() then
			instance.LocalTransparencyModifier = transparency
		elseif RunService:IsServer() then
			instance.Transparency = transparency
		end
	end

	for _, descendant in instance:GetDescendants() do
		if descendant:IsA("BasePart") then
			if RunService:IsClient() then
				descendant.LocalTransparencyModifier = transparency
			elseif RunService:IsServer() then
				descendant.Transparency = transparency
			end
		end
	end
end

function InstanceUtility.findAncestorWithTag(instance: Instance, tag: string): Instance?
	local currentInstance = instance.Parent
	while currentInstance do
		if CollectionService:HasTag(currentInstance, tag) then
			return currentInstance
		end

		currentInstance = currentInstance.Parent
	end

	return nil
end

function InstanceUtility.findDescendantsWithTag(instance: PVInstance, tag: string): { PVInstance? }
	local descendants = instance:GetDescendants()
	local taggedDescendants = {}

	for _, descendant in descendants do
		if CollectionService:HasTag(descendant, tag) then
			table.insert(taggedDescendants, descendant)
		end
	end

	return taggedDescendants
end

return InstanceUtility
