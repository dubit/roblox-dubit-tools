local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local DubitUtils = require(ReplicatedStorage.Packages.DubitUtils)

--Time
print("\n TIME UTILITY TESTS \n")
print("formatToRaceTimer Test: ", DubitUtils.Time.formatToRaceTimer(127.134))
print("formatToRaceTimerDetailed Test: ", DubitUtils.Time.formatToRaceTimerDetailed(127.134))
print("getFormattedTimeOfDay Test: ", DubitUtils.Time.getFormattedTimeOfDay())
print("formatSecondsToMinutesAndSeconds Test: ", DubitUtils.Time.formatSecondsToMinutesAndSeconds(972))

--Number
print("\n NUMBER UTILITY TESTS \n")
print("lerp Test: ", DubitUtils.Number.lerp(1.00, 2.00, 0.50))
print("formatDigitLength Test: ", DubitUtils.Number.formatDigitLength(59, 4))
print("roundToNearest Test: ", DubitUtils.Number.roundToNearest(22, 5))
print("abbreviate Test 1: ", DubitUtils.Number.abbreviate(27))
print("abbreviate Test 2: ", DubitUtils.Number.abbreviate(4678918263))
print("abbreviate Test 3: ", DubitUtils.Number.abbreviate(1000000))
print("abbreviate Test 4: ", DubitUtils.Number.abbreviate(10000000, false))
print("abbreviate Test 5: ", DubitUtils.Number.abbreviate(4967827362967902, true, 2))
print("commaSeparate Test 1: ", DubitUtils.Number.commaSeparate(528))
print("commaSeparate Test 2: ", DubitUtils.Number.commaSeparate(1000000))
print("commaSeparate Test 3: ", DubitUtils.Number.commaSeparate(-10000000))
print("commaSeparate Test 4: ", DubitUtils.Number.commaSeparate(56692.42491))

--Table
print("\n TABLE UTILITY TESTS \n")
print("deepClone Test: ", DubitUtils.Table.deepClone({ test = true }))
print("merge Test: ", DubitUtils.Table.merge({ test = true, foo = 8 }, { test = false, bar = 16 }))
print(
	"getRandomDictionaryEntry Test: ",
	DubitUtils.Table.getRandomDictionaryEntry({ foo = "apple", bar = "banana", var = "grape" })
)

--Accessory
print("\n ACCESSORY UTILITY TESTS \n")
print("matchAssetTypeToAccessoryType Test: ", DubitUtils.Accessory.matchAssetTypeToAccessoryType(Enum.AssetType.TShirt))
print("isAssetTypeAccessory Test: ", DubitUtils.Accessory.isAssetTypeAccessory(Enum.AssetType.ShortsAccessory))
print("isAssetTypeAccessory Test 2: ", DubitUtils.Accessory.isAssetTypeAccessory(Enum.AssetType.Animation))

--Instance
--Short wait so the player can view the tests
task.wait(5)
print("\n INSTANCE UTILITY TESTS \n")
print("verifyInstance Test: ", DubitUtils.Instance.verifyInstance("TestFolder", "Folder", workspace, 2))
if workspace:FindFirstChild("WaitForChildrenTestFolder") then
	local testFolder = workspace:FindFirstChild("WaitForChildrenTestFolder")
	local finalChild = DubitUtils.Instance.waitForChildren(testFolder, "SomeModel.SomeBasePart.SomeProximityPrompt", 5)
	print("waitForChildren Test: ", finalChild)
	print("findAncestorWithTag Test: ", DubitUtils.Instance.findAncestorWithTag(finalChild, "TestAncestorTag"))
end
if workspace:FindFirstChild("GeneralTestModel") then
	DubitUtils.Instance.setDescendantTransparency(workspace.GeneralTestModel, 0.5)
	print(
		"findDescendantsWithTag Test: ",
		DubitUtils.Instance.findDescendantsWithTag(workspace.GeneralTestModel, "TestDescendantTag")
	)
end

--Vector
print("\n VECTOR UTILITY TESTS \n")
if workspace:FindFirstChild("GeneralTestPart") then
	print("getRandomPointInPart Test: ", DubitUtils.Vector.getRandomPointInPart(workspace.GeneralTestPart, true))
end

--RobloxGroup
print("\n ROBLOX GROUP UTILITY TESTS \n")
print("getMemberRank Test: ", DubitUtils.RobloxGroup.getMemberRank(Players:FindFirstChildWhichIsA("Player"), nil, 3))
print(
	"isPlayerAboveGroupRank Test: ",
	DubitUtils.RobloxGroup.isPlayerAboveGroupRank(Players:FindFirstChildWhichIsA("Player"), 250, nil, 3)
)

--Character
print("\n CHARACTER UTILITY TESTS \n")
local testPlayer = Players:FindFirstChildOfClass("Player")
local testCharacter = testPlayer and testPlayer.Character
if testCharacter then
	print("Freezing character & making transparent temporarily")
	DubitUtils.Character.setCharacterTransparency(testCharacter, 0.7, TweenInfo.new(1))
	DubitUtils.Character.setCharacterFrozen(testCharacter, true)

	task.delay(5, function()
		DubitUtils.Character.resetCharacterTransparency(testCharacter, TweenInfo.new(1))
		task.wait(1)
		DubitUtils.Character.setCharacterFrozen(testCharacter, false)
	end)
end
