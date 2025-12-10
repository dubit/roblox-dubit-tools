local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local modifiedTransparencyCharacters = {}
local descendantAddedTransparencyConnections = {}

local Character = {}

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

function Character.setCharacterFrozen(character: Model, frozen: boolean?)
	frozen = if typeof(frozen) == "boolean" then frozen else true
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart then
		humanoidRootPart.Anchored = frozen
	end
end

return Character
