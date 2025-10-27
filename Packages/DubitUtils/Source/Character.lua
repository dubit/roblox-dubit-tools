--[=[
	@class DubitUtils.Character
]=]

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local modifiedTransparencyCharacters = {}
local descendantAddedTransparencyConnections = {}

local Character = {}

--[=[
	Creates a clone of the provided character, without overhead display of display name & health.
	
	@within DubitUtils.Character

	@param character Model -- The character model to create a clone of.
	@param isAnchored boolean? -- Whether the cloned character should be anchored. Defaults to false.

	@return Model? -- The cloned character model.

	#### Example Usage

	```lua
	DubitUtils.Character.cloneCharacter(Players.LocalPlayer.Character, true)
	```
]=]
function Character.cloneCharacter(character: Model, isAnchored: boolean?): Model?
	if typeof(character) ~= "Instance" or not character:IsA("Model") then
		return
	end

	character.Archivable = true
	local clone = character:Clone()
	character.Archivable = false

	local humanoidRootPart: BasePart = clone:FindFirstChild("HumanoidRootPart")
	local humanoid: Humanoid = clone:FindFirstChildOfClass("Humanoid")
	if not humanoid or not humanoidRootPart then
		return
	end

	humanoidRootPart.Anchored = isAnchored or false
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	return clone
end

--[=[
	@yields

	Sets the transparency of all valid parts within the provided character to the provided value.
	This will also apply to any valid parts which become a descendant of the character before transparency values are reset.
	
	@within DubitUtils.Character

	@param character Model -- The character model to set the transprency of.
	@param targetTransparency number -- The transparency value to set. Supports values between 0 and 1 (inclusive).
	@param tweenInfo TweenInfo? -- The TweenInfo to apply to the transparency change. Will not tween if not provided.

	#### Example Usage

	```lua
	DubitUtils.Character.setCharacterTransparency(Players.LocalPlayer.Character, 0.7, true)
	```

	:::info
	This function is usually intended to be used in conjunction with resetCharacterTransparency, as it will
	restore the original transparency values of each part, which are stored through this function.
	:::
]=]
function Character.setCharacterTransparency(character: Model, targetTransparency: number, tweenInfo: TweenInfo?)
	if typeof(targetTransparency) ~= "number" then
		return
	end
	if targetTransparency == 0 then
		Character.resetCharacterTransparency(character, tweenInfo)
		return
	end

	if not modifiedTransparencyCharacters[character] then
		modifiedTransparencyCharacters[character] = {}
	elseif
		modifiedTransparencyCharacters[character]
		and not modifiedTransparencyCharacters[character]:IsDescendantOf(workspace)
	then
		modifiedTransparencyCharacters[character] = nil

		if descendantAddedTransparencyConnections[character.Name] then
			descendantAddedTransparencyConnections[character.Name]:Disconnect()
			descendantAddedTransparencyConnections[character.Name] = nil
		end
	end

	if #character:GetDescendants() == 0 then
		local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
		if not humanoidRootPart then
			return
		end
	end

	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") or part:IsA("Decal") then
			if not modifiedTransparencyCharacters[character][part] then
				modifiedTransparencyCharacters[character][part] = part.Transparency
			end
			if tweenInfo then
				TweenService:Create(part, tweenInfo, { Transparency = targetTransparency }):Play()
			else
				part.Transparency = targetTransparency
			end
		end
	end

	local descendantAddedEvent
	descendantAddedEvent = character.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") or descendant:IsA("Decal") then
			if not modifiedTransparencyCharacters[character][descendant] then
				modifiedTransparencyCharacters[character][descendant] = descendant.Transparency
			end
			if tweenInfo then
				TweenService:Create(descendant, tweenInfo, { Transparency = targetTransparency }):Play()
			else
				descendant.Transparency = targetTransparency
			end
		end
	end)

	descendantAddedTransparencyConnections[character.Name] = descendantAddedEvent

	local player = Players:GetPlayerFromCharacter(character)
	if player then
		player.CharacterRemoving:Once(function(removingCharacter)
			if descendantAddedTransparencyConnections[removingCharacter.Name] then
				descendantAddedTransparencyConnections[removingCharacter.Name]:Disconnect()
				descendantAddedTransparencyConnections[removingCharacter.Name] = nil
			end
			if modifiedTransparencyCharacters[removingCharacter] then
				modifiedTransparencyCharacters[removingCharacter] = nil
			end
		end)
	end
end

--[=[
	Resets the transparency of all parts within the provided character to the original value,
	if it was made invisible via Character.setCharacterTransparency.
	
	@within DubitUtils.Character

	@param character Model -- The character model to reset the transparency of.
	@param tweenInfo TweenInfo? -- The TweenInfo to apply to the transparency change. Will not tween if not provided.

	#### Example Usage

	```lua
	DubitUtils.Character.makeCharacterVisible(Players.LocalPlayer.Character, false)
	```

	:::info
	This function must be used in conjunction with Character.setCharacterTransparency, which stores the original
	transparency values of each part.
	If the character did not have its transparency modified via that function, this function will fail.
	:::
]=]
function Character.resetCharacterTransparency(character: Model, tweenInfo: TweenInfo?)
	if not next(modifiedTransparencyCharacters) or not modifiedTransparencyCharacters[character] then
		return
	end

	for part, transparency in modifiedTransparencyCharacters[character] do
		if tweenInfo then
			TweenService:Create(part, tweenInfo, { Transparency = transparency }):Play()
		else
			part.Transparency = transparency
		end
	end

	descendantAddedTransparencyConnections[character.Name]:Disconnect()
	descendantAddedTransparencyConnections[character.Name] = nil
	modifiedTransparencyCharacters[character] = nil
end

--[=[
	Set a provided character to be frozen or unfrozen.
	
	@within DubitUtils.Character

	@param character Model -- The character model to freeze/unfreeze.
	@param frozen boolean? -- Whether to freeze or unfreeze the character. Defaults to true.

	#### Example Usage

	```lua
	DubitUtils.Character.setCharacterFrozen(Players.LocalPlayer.Character, true)
	```
]=]
function Character.setCharacterFrozen(character: Model, frozen: boolean?)
	frozen = if typeof(frozen) == "boolean" then frozen else true
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart then
		humanoidRootPart.Anchored = frozen
	end
end

return Character
