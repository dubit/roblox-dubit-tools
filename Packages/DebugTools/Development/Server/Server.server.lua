local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DebugTools = require(ReplicatedStorage.Packages.DebugTools)

DebugTools.Action.new("Destroy Universe", nil, function() end)

DebugTools.Action.new("Test Action", nil, function(player: Player)
	print(`Player '{player.DisplayName}' executed an action!`)
end, {
	{
		Type = "Player",
		Name = "Player",
	},
})

local updated = false
local fruitList = {
	"apple",
	"strawberry",
	"cherry",
}
local alternativeFruitList = {
	"apple",
	"banana",
	"orange",
}

DebugTools.Action.new("Fruits/Pick an option", "Pick a fruit please.", function() end, {
	{
		Type = "string",
		Name = "Fruit",
		Default = "apple",
		Options = fruitList,
	},
})

DebugTools.Action.new("Fruits/Update 'Pick an option'", "Update the options for 'Pick an option'", function()
	updated = not updated
	DebugTools.Action.new("Fruits/Pick an option", "Pick a fruit please.", function() end, {
		{
			Type = "string",
			Name = "Fruit",
			Default = "apple",
			Options = updated and alternativeFruitList or fruitList,
		},
	})
end)
