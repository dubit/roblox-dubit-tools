--!strict

--[=[
	@class ClothingDisplay
]=]

local ClothingDisplay = {}
ClothingDisplay.private = {}
ClothingDisplay.public = {
	ItemDetails = require(script.ItemDetails),
	Outfit = require(script.Outfit),
	Mannequin = require(script.Mannequin),
	MannequinHead = require(script.MannequinHead),
	Hanger = require(script.Hanger),
	Types = require(script.Types),
	Utils = require(script.Utils),
}

return ClothingDisplay.public
