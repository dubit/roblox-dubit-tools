return function(DebugTools)
	local loremIpsum: string =
		"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum"

	DebugTools.Action.new("Test/Return 'Hello World'", "This Action returns 'Hello World' as its result", function()
		return "Hello World"
	end)

	DebugTools.Action.new("Test/Return false", "This Action returns false as its result", function()
		return false
	end)

	DebugTools.Action.new("Test/Return true", "This Action returns true as its result", function()
		return true
	end)

	DebugTools.Action.new("Test/Return nothing", "This Action doesn't return anything as its result", function() end)

	DebugTools.Action.new(
		"Test/Arguments Test",
		"This action is used for testing all of the possible argument types.",
		function(string: string, number: number, boolean: boolean, player: Player)
			print(string, number, boolean, player)
		end,
		{
			{
				Type = "string",
				Name = "string",
				Default = "string",
			},
			{
				Type = "number",
				Name = "number",
				Default = 123,
			},
			{
				Type = "boolean",
				Name = "boolean",
				Default = true,
			},
			{
				Type = "Player",
				Name = "player",
			},
		}
	)

	DebugTools.Action.new("Lorem Ipsum", loremIpsum, function() end, {
		{
			Type = "string",
			Name = "short text",
			Default = loremIpsum,
		},
	})

	DebugTools.Action.new("Reverse Lorem Ipsum", loremIpsum, function() end, {
		{
			Type = "string",
			Name = loremIpsum,
			Default = "short text",
		},
	})

	DebugTools.Action.new("Short Text", loremIpsum, function() end, {
		{
			Type = "string",
			Name = "short text",
			Default = "short text",
		},
	})
end
