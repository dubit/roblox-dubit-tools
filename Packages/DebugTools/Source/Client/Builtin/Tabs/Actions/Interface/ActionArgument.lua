--!strict
local Players = game:GetService("Players")

type ArgumentData = {
	Index: number,
	Type: string,
	Name: string?,
	Default: any?,
	Options: { any }?,
}

local DebugToolRootPath = script.Parent.Parent.Parent.Parent.Parent

local ArgumentType = require(DebugToolRootPath.Parent.Shared.Enums.ArgumentType)

local StringPropertyComponent = require(DebugToolRootPath.Components.StringPropertyComponent)
local NumberPropertyComponent = require(DebugToolRootPath.Components.NumberPropertyComponent)
local DropdownPropertyComponent = require(DebugToolRootPath.Components.DropdownPropertyComponent)
local CheckmarkPropertyComponent = require(DebugToolRootPath.Components.CheckmarkPropertyComponent)

return function(parent: Frame, argumentData: ArgumentData, valueChangedCallback: (newValue: any) -> nil)
	local argumentName: string = argumentData.Name and `{string.gsub(argumentData.Name, "^%l", string.upper)}:`
		or `#{argumentData.Index} argument:`

	local destructor
	if argumentData.Type == ArgumentType.Player then
		local options: { string } = {}

		for _, player: Player in Players:GetPlayers() do
			table.insert(options, player.DisplayName)
		end

		destructor = DropdownPropertyComponent({
			PropertyText = argumentName,

			Value = Players.LocalPlayer.DisplayName,
			Options = options,

			Parent = parent,
		}, function(newValue: string)
			for _, player: Player in Players:GetPlayers() do
				if player.DisplayName == newValue then
					valueChangedCallback(player)
					return
				end
			end
		end)

		valueChangedCallback(Players.LocalPlayer)
	elseif argumentData.Options then
		destructor = DropdownPropertyComponent({
			PropertyText = argumentName,

			Value = argumentData.Default or argumentData.Options[1] :: any,
			Options = argumentData.Options :: { any },

			Parent = parent,
		}, function(newValue: any)
			valueChangedCallback(newValue)
		end)
	elseif argumentData.Type == ArgumentType.boolean then
		destructor = CheckmarkPropertyComponent({
			PropertyText = argumentName,

			Value = argumentData.Default :: boolean,

			Parent = parent,
		}, function(newValue: boolean)
			valueChangedCallback(newValue)
		end)
	elseif argumentData.Type == ArgumentType.string then
		destructor = StringPropertyComponent({
			PropertyText = argumentName,

			Value = argumentData.Default :: string,
			Default = argumentData.Default :: string,

			Parent = parent,
		}, function(newValue: string)
			valueChangedCallback(newValue)
		end)
	elseif argumentData.Type == ArgumentType.number then
		destructor = NumberPropertyComponent({
			PropertyText = argumentName,

			Value = argumentData.Default :: number,
			Default = argumentData.Default :: number,

			Parent = parent,
		}, function(newValue: number)
			valueChangedCallback(newValue)
		end)
	end

	return function()
		if destructor then
			destructor()
		end
	end
end
