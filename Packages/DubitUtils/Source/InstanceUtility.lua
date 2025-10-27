--[=[
	@class DubitUtils.InstanceUtility

	Contains utility functions for working with Instance object types.
]=]

local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local PATH_SEPARATOR = "."

--[[
	Note - This utility class is named unlike other DubitUtils classes as "Instance"
	is an existing member of the Roblox API.
]]
local InstanceUtility = {}

--[=[
	@yields

	Ensure that an Instance exists within the given parent Instance, and create it if it does not exist.
	
	@within DubitUtils.InstanceUtility

	@param instanceName string -- The name of the instance to create or return.
	@param instanceType string -- The type of the instance to create or return. Must equate to a valid Instance subclass.
	@param instanceParent Instance? -- The parent of the instance to create or return. Defaults to `workspace`.
	@param timeout number? -- The timeout to wait for the instance to exist. Defaults to `0`.

	@return Instance? -- The found or created instance, as long as a valid instanceType was provided.

	#### Example Usage

	```lua
	DubitUtils.InstanceUtility.verifyInstance("TestFolder", "Folder", workspace.Map, 10)
	```

	:::danger
	Developers should ensure that the provided 'instanceType' equates to a valid Instance subclass.
	This is something that as of current can not be natively checked in Lua/Luau, so will cause an error if it is not valid.
	:::
]=]
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

--[=[
	@yields
	
	Wait for a series of children to appear in an instance.

	@within DubitUtils.InstanceUtility

	@param instance Instance -- The instance to search for children in.
	@param childrenString string -- A string of children to search for, separated by periods.
	@param timeout number? -- The maximum amount of time to wait for each child to appear. Defaults to 5.

	@return Instance? -- The last child in the series of children, if all children exist.

	#### Example Usage

	```lua
	DubitUtils.InstanceUtility.waitForChildren(playerGui, "ScoreGui.MainFrame.ScoreText", 5)
	```

	:::warning
	Will return nil if any of the children do not appear within the provided timeout.
	:::
]=]
function InstanceUtility.waitForChildren(instance: Instance, childrenString: string, timeout: number?): Instance?
	local childrenSplit = childrenString:split(PATH_SEPARATOR)
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

--[[
	Safely and securly search for a descendant instance starting from a provided parent.

	@within DubitUtils.InstanceUtility

	### Parameters

	@param parent Instance -- The parent to begin the find search in.
	@param path string -- A string path split by a deliminator (default is ".").

	@return Instance -- The instance at the provided path.

	#### Example Usage

	```lua
	findInstance(ReplicatedStorage, "Source.Client.Shared.Data.Loot")
	```

	:::warning
	Throws an error if not found.
	:::
]]

function InstanceUtility.findInstance(parent: Instance, path: string): Instance
	local instance = parent
	local paths = path:split(PATH_SEPARATOR)

	for _, childName in paths do
		if childName == "" then
			error(`Invalid path: {path}`, 2)
		end

		instance = instance:FindFirstChild(childName)

		if instance == nil then
			error(`Failed to find {path} in {instance:GetFullName():gsub("%.", PATH_SEPARATOR)}`, 2)
		end
	end

	return instance
end

--[=[
	Sets the transparency of a given instance and all of its descendants to a provided value.
	The transprency to set may be any number, however only values between 0 and 1 are supported 
	(e.g. providing a value above 1 will be equivalent to providing 1).

	@within DubitUtils.InstanceUtility

	@param instance Instance -- The instance to set the transparency of which and its descendants to.
	@param transparency number -- The transparency value to set the LocalTransparencyModifier/Transparency of the instance & its descendants to.

	#### Example Usage

	```lua
	DubitUtils.InstanceUtility.setDescendantTransparency(someCurrentlyOpaqueModel, 0.5)
	```

	:::note
	This function will dynamically set either the LocalTransparencyModifier (client, will not replicate) or the Transparency
	of the instance (server, will replicate), depending on whether the function is called from the client or the server.
	:::
]=]
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

--[=[
	Finds & returns the first ancestor of the given instance with the provided tag, if there is one.

	@within DubitUtils.InstanceUtility

	@param instance PVInstance -- The instance to search the ancestors of.
	@param tag string -- The tag to check for on the instance's ancestors.

	@return PVInstance? -- The first ancestor found with the provided tag, or nil if none were found.

	#### Example Usage

	```lua
	DubitUtils.InstanceUtility.findAncestorWithTag(instanceProvidedFromExternalFunction, "HomePortal")
	```

	:::note
	This function will ignore the provided instance, and only check its ancestors.
	:::
]=]
function InstanceUtility.findAncestorWithTag(instance: PVInstance, tag: string): PVInstance?
	local currentInstance = instance.Parent
	while currentInstance do
		if CollectionService:HasTag(currentInstance, tag) then
			return currentInstance
		end

		currentInstance = currentInstance.Parent
	end

	return nil
end

--[=[
	Finds & returns a table of descendants of the given instance which have the provided tag.

	@within DubitUtils.InstanceUtility

	@param instance PVInstance -- The instance to search the descendants of.
	@param tag string -- The tag to check for on the instance's descendants.

	@return { PVInstance? } -- A table of descendants with the provided tag, will be an empty table if none were found.

	#### Example Usage

	```lua
	DubitUtils.InstanceUtility.findDescendantsWithTag(modelProvidedFromExternalFunction, "PhysicsComponent")
	```

	:::note
	This function will ignore the provided instance, and only check its descendants.
	:::
]=]
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
