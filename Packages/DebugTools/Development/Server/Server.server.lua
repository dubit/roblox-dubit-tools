local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DebugTools = require(ReplicatedStorage.Packages.DebugTools)

DebugTools.Server.Action.new("Destroy Universe", nil, function() end)

DebugTools.Server.Action.new("Test Action", nil, function(player: Player)
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

DebugTools.Server.Action.new("Fruits/Pick an option", "Pick a fruit please.", function() end, {
	{
		Type = "string",
		Name = "Fruit",
		Default = "apple",
		Options = fruitList,
	},
})

DebugTools.Server.Action.new("Fruits/Update 'Pick an option'", "Update the options for 'Pick an option'", function()
	updated = not updated
	DebugTools.Server.Action.new("Fruits/Pick an option", "Pick a fruit please.", function() end, {
		{
			Type = "string",
			Name = "Fruit",
			Default = "apple",
			Options = updated and alternativeFruitList or fruitList,
		},
	})
end)
