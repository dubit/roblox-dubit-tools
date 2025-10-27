local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CaptureService = game:GetService("CaptureService")
local UserInputService = game:GetService("UserInputService")

local Signal = require(script.Parent.Signal)

local check3dIABScreenRatio = require(script.Functions.iab.check3dScreenRatio)
local check3dIABScreenCoverage = require(script.Functions.iab.check3dScreenCoverage)
local check3dIABScreenAngle = require(script.Functions.iab.check3dScreenAngle)
local check2dIABScreenRatio = require(script.Functions.iab.check2dScreenRatio)
local check2dIABScreenCoverage = require(script.Functions.iab.check2dScreenCoverage)

local calculatePartFaceCFrame = require(script.Functions.geometry.calculatePartFaceCFrame)
local checkGuiVisibility = require(script.Functions.checkGuiVisibility)

local getPackageRemoteEvent = require(script.Functions.getPackageRemoteEvent)
local bindToTag = require(script.Functions.bindToTag)

local IAB_DELAY_BEFORE_REGISTRATION = 1

local isInitialised = false

--[=[
	@class Engagements
	@__index = internal

	The Roblox Engagement tool is a package that enables developers to easily query and handle events, objects,
	interfaces engagements from within a Roblox experience.

	---

	IAB (Interactive Advertising Bureau) provides a generalized set of rules/guidelines that we can follow in order to
	better evaluate if a player has engaged with an event or not.

	Sources in order for us to be IAB (Interactive Advertising Bureau) compliance are as follows:
		https://www.iab.com/wp-content/uploads/2015/06/dig_vid_imp_meas_guidelines_finalv2.pdf
]=]
local Engagements = {}

Engagements.internal = {}
Engagements.interface = {}

Engagements.internal.trackedZones = {} :: { Model }
Engagements.internal.trackedVideos = {} :: { VideoFrame }
Engagements.internal.trackedObjects = {} :: { Model }
Engagements.internal.trackedGuis = {} :: { ScreenGui }

Engagements.internal.playerActive = {} :: { [Player]: { [Model]: boolean } }
Engagements.internal.active = {} :: { [Model]: boolean }
Engagements.internal.activeThreads = {} :: { [Model]: thread? }

Engagements.internal.characterOverlapParams = OverlapParams.new()
Engagements.internal.characterOverlapParams.FilterType = Enum.RaycastFilterType.Include

Engagements.interface.ZoneEntered = Signal.new()
Engagements.interface.ZoneLeft = Signal.new()
Engagements.interface.WatchedVideo = Signal.new()

Engagements.interface.ViewedGui = Signal.new()
Engagements.interface.InteractedWithGui = Signal.new()

Engagements.interface.InScreenshot = Signal.new()
Engagements.interface.LookedAt = Signal.new()

--[[
	Validates whether the player is touching a tracked zone and triggers the appropriate `ZoneEntered` or `ZoneLeft`
	events.
]]
function Engagements.internal.ValidateZone()
	local remoteEvent = getPackageRemoteEvent()

	for _, model in Engagements.internal.trackedZones do
		if not model:IsDescendantOf(workspace) then
			continue
		end

		local isPlayerTouchingModel = false

		for _, object in model:GetDescendants() do
			if not object:IsA("BasePart") then
				continue
			end

			local touchingParts = workspace:GetPartsInPart(object, Engagements.internal.characterOverlapParams)

			isPlayerTouchingModel = #touchingParts ~= 0

			if isPlayerTouchingModel then
				break
			end
		end

		if isPlayerTouchingModel then
			if Engagements.internal.active[model] then
				continue
			end

			if Engagements.internal.activeThreads[model] then
				continue
			end

			Engagements.internal.activeThreads[model] = task.delay(IAB_DELAY_BEFORE_REGISTRATION, function()
				Engagements.internal.activeThreads[model] = nil

				Engagements.internal.active[model] = true

				remoteEvent:FireServer("ZoneEntered", model)
			end)
		else
			if not Engagements.internal.active[model] and not Engagements.internal.activeThreads[model] then
				continue
			end

			if Engagements.internal.activeThreads[model] then
				task.cancel(Engagements.internal.activeThreads[model])

				Engagements.internal.activeThreads[model] = nil
			else
				remoteEvent:FireServer("ZoneLeft", model)

				Engagements.internal.active[model] = nil
			end
		end
	end
end

--[[
	Validates wether the player can see tracked objects, then triggers the server to let the server know what objects
	the player has in their viewport.
]]
function Engagements.internal.ValidateObjects()
	local remoteEvent = getPackageRemoteEvent()

	for _, model in Engagements.internal.trackedObjects do
		if not model:IsDescendantOf(workspace) then
			continue
		end

		local screenRatio = check3dIABScreenRatio(model)
		local screenCoverage = check3dIABScreenCoverage(model, workspace.CurrentCamera.ViewportSize)

		local validated = screenRatio and screenCoverage

		if validated then
			if Engagements.internal.active[model] or Engagements.internal.activeThreads[model] then
				continue
			end

			Engagements.internal.activeThreads[model] = task.delay(IAB_DELAY_BEFORE_REGISTRATION, function()
				Engagements.internal.activeThreads[model] = nil
				Engagements.internal.active[model] = true

				remoteEvent:FireServer("ObjectActive", model)
			end)
		else
			if not Engagements.internal.active[model] and not Engagements.internal.activeThreads[model] then
				continue
			end

			if Engagements.internal.activeThreads[model] then
				task.cancel(Engagements.internal.activeThreads[model])
				Engagements.internal.activeThreads[model] = nil
			else
				Engagements.internal.active[model] = nil

				remoteEvent:FireServer("ObjectNotActive", model)
			end
		end
	end
end

--[[
	Iterates over all tracked videos and validates whether the video is visible and meets IAB (Interactive Advertising
	Bureau) requirements for viewability.
	
	This function checks both 3D videos in the workspace and 2D videos in the PlayerGui.
]]
function Engagements.internal.ValidateVideo()
	local remoteEvent = getPackageRemoteEvent()

	for _, videoFrame in Engagements.internal.trackedVideos do
		local validated = false

		if not videoFrame.Playing then
			continue
		end

		if videoFrame:IsDescendantOf(workspace) then
			local model = videoFrame:FindFirstAncestorOfClass("Model")

			local screenRatio = check3dIABScreenRatio(model)
			local screenCoverage = check3dIABScreenCoverage(model, workspace.CurrentCamera.ViewportSize)
			local isVisible = checkGuiVisibility(videoFrame)
			local screenAngle = false

			if isVisible then
				local surfaceGui = videoFrame:FindFirstAncestorOfClass("SurfaceGui")

				if surfaceGui then
					local adornee = surfaceGui.Adornee or surfaceGui.Parent

					if adornee then
						local cframe = calculatePartFaceCFrame(adornee, surfaceGui.Face)

						screenAngle = check3dIABScreenAngle(cframe, workspace.CurrentCamera.CFrame.LookVector)
					end
				end

				local billboardGui = videoFrame:FindFirstAncestorOfClass("BillboardGui")

				if billboardGui then
					local adornee = billboardGui.Adornee or billboardGui.Parent

					if
						billboardGui.PlayerToHideFrom == Players.LocalPlayer
						or Players.LocalPlayer:DistanceFromCharacter(adornee.Position) > billboardGui.MaxDistance
					then
						screenAngle = false
					else
						screenAngle = true
					end
				end
			end

			validated = screenRatio and screenCoverage and isVisible and screenAngle
		elseif videoFrame:IsDescendantOf(Players.LocalPlayer.PlayerGui) then
			local guiObjects = Players.LocalPlayer.PlayerGui:GetGuiObjectsAtPosition(
				videoFrame.AbsolutePosition.X + videoFrame.AbsoluteSize.X / 2,
				videoFrame.AbsolutePosition.Y + videoFrame.AbsoluteSize.Y / 2
			)

			local screenRatio = check2dIABScreenRatio(videoFrame)
			local screenCoverage = check2dIABScreenCoverage(videoFrame, workspace.CurrentCamera.ViewportSize)
			local isVisible = table.find(guiObjects, videoFrame) ~= nil

			validated = screenRatio and screenCoverage and isVisible
		end

		if validated then
			if Engagements.internal.active[videoFrame] or Engagements.internal.activeThreads[videoFrame] then
				continue
			end

			Engagements.internal.activeThreads[videoFrame] = task.delay(IAB_DELAY_BEFORE_REGISTRATION, function()
				Engagements.internal.activeThreads[videoFrame] = nil
				Engagements.internal.active[videoFrame] = true

				remoteEvent:FireServer("ObjectActive", videoFrame)
			end)
		else
			if not Engagements.internal.active[videoFrame] and not Engagements.internal.activeThreads[videoFrame] then
				continue
			end

			if Engagements.internal.activeThreads[videoFrame] then
				task.cancel(Engagements.internal.activeThreads[videoFrame])
				Engagements.internal.activeThreads[videoFrame] = nil
			else
				Engagements.internal.active[videoFrame] = nil

				remoteEvent:FireServer("ObjectNotActive", videoFrame)
			end
		end
	end
end

--[[
	Validates whether tracked GUIs are visible and meet IAB (Interactive Advertising Bureau) requirements for viewability.
	This function checks if any children of the tracked ScreenGuis are visible and meet the required screen ratio and
	coverage thresholds.
]]
function Engagements.internal.ValidateGuis()
	local remoteEvent = getPackageRemoteEvent()

	for _, screenGui in Engagements.internal.trackedGuis do
		local validated = false
		local screenGuiChildren = screenGui:GetChildren()

		for _, child in screenGuiChildren do
			local guiObjects = Players.LocalPlayer.PlayerGui:GetGuiObjectsAtPosition(
				child.AbsolutePosition.X + child.AbsoluteSize.X / 2,
				child.AbsolutePosition.Y + child.AbsoluteSize.Y / 2
			)

			local screenRatio = check2dIABScreenRatio(child)
			local screenCoverage = check2dIABScreenCoverage(child, workspace.CurrentCamera.ViewportSize)
			local isVisible = table.find(guiObjects, child) ~= nil

			validated = screenRatio and screenCoverage and isVisible

			if validated then
				break
			end
		end

		if validated then
			if Engagements.internal.active[screenGui] or Engagements.internal.activeThreads[screenGui] then
				continue
			end

			Engagements.internal.activeThreads[screenGui] = task.delay(IAB_DELAY_BEFORE_REGISTRATION, function()
				Engagements.internal.activeThreads[screenGui] = nil
				Engagements.internal.active[screenGui] = true

				local identifier = screenGui:GetAttribute(`DubitEngagement_Identifier`)

				remoteEvent:FireServer("GuiActive", identifier)
			end)
		else
			if not Engagements.internal.active[screenGui] and not Engagements.internal.activeThreads[screenGui] then
				continue
			end

			if Engagements.internal.activeThreads[screenGui] then
				task.cancel(Engagements.internal.activeThreads[screenGui])
				Engagements.internal.activeThreads[screenGui] = nil
			else
				Engagements.internal.active[screenGui] = nil
			end
		end
	end
end

--[[
	Handles input events for tracked GUIs, specifically mouse clicks and touch inputs. When a tracked GUI that is
	currently active receives input, it fires a "GuiInteracted" event to the server with the GUI's identifier.
]]
function Engagements.internal.OnGuiInput(inputObject: InputObject, inputProcessed: boolean)
	if
		inputObject.UserInputType ~= Enum.UserInputType.MouseButton1
		and inputObject.UserInputType ~= Enum.UserInputType.Touch
	then
		return
	end

	if not inputProcessed then
		return
	end

	for _, screenGui in Engagements.internal.trackedGuis do
		if not Engagements.internal.active[screenGui] then
			continue
		end

		local remoteEvent = getPackageRemoteEvent()
		local identifier = screenGui:GetAttribute(`DubitEngagement_Identifier`)

		remoteEvent:FireServer("GuiInteracted", identifier)
	end
end
--[=[
	@within Engagements
	@client

	Tracks when a GUI is viewed or interacted with by:
	- Setting a unique identifier as an attribute on the GUI.
	- Tagging the GUI so it can be recognized later.
	
	This allows the client side system to detect and respond to GUI visibility and interactions.

	:::info
	This function must be called on the client.
	:::
]=]
function Engagements.interface.TrackGui(gui: ScreenGui, identifier: string)
	assert(RunService:IsClient(), `'TrackGui' can only be called by the client!`)
	assert(gui:IsA("ScreenGui"), `Expected zone to be a ScreenGui, got '{gui.ClassName}'`)
	assert(identifier ~= nil, `Expected identifier to be a string, got 'nil'`)

	gui:SetAttribute(`DubitEngagement_Identifier`, identifier)
	gui:AddTag(`DubitEngagement_Gui`)
end
--[=[
	@within Engagements
	@server

	Tracks when a video is watched by:
	- Setting a unique identifier as an attribute on the video.
	- Tagging the video so it can be recognized later.
	
	This allows the client side system to detect and respond to video playback. The `WatchedVideo` signal will be 
	triggered when the video ends or loops.

	Note: This function must be called on the server.
]=]
function Engagements.interface.TrackVideo(video: VideoFrame, identifier: string?)
	assert(RunService:IsServer(), `'TrackVideo' can only be called by the server!`)
	assert(video:IsA("VideoFrame"), `Expected zone to be a VideoFrame, got '{video.ClassName}'`)

	local function onVideoEnded()
		for player, objects in Engagements.internal.playerActive do
			if not objects[video] then
				continue
			end

			Engagements.interface.WatchedVideo:Fire(player, identifier or video)
		end
	end

	video:SetAttribute(`DubitEngagement_Identifier`, identifier)
	video:AddTag(`DubitEngagement_Video`)

	video.DidLoop:Connect(onVideoEnded)
	video.Ended:Connect(onVideoEnded)
end

--[=[
	@within Engagements
	@server

	Tracks when a player enters or leaves a zone by:
	- Setting a unique identifier as an attribute on the zone.
	- Tagging the zone so it can be recognized later.
	
	This allows the client side system to detect and respond to player movement in and out of designated zones. The
	`ZoneEntered` and `ZoneLeft` signals will be triggered when relevant.

	Note: This function must be called on the server.
]=]
function Engagements.interface.TrackZone(zone: Model, identifier: string?)
	assert(RunService:IsServer(), `'TrackZone' can only be called by the server!`)
	assert(zone:IsA("Model"), `Expected zone to be a Model, got '{zone.ClassName}'`)

	zone:SetAttribute(`DubitEngagement_Identifier`, identifier)
	zone:AddTag(`DubitEngagement_Zone`)
end

--[=[
	@within Engagements
	@server

	Tracks when an object enters the players viewport:
	- Setting a unique identifier as an attribute on the zone.
	- Tagging the zone so it can be recognized later.
	
	This allows the client side system to detect and respond to objects appearing in the players viewport. This
	function will invoke the following signals:

	- InScreenshot

	Note: This function must be called on the server.
]=]
function Engagements.interface.TrackObject(object: Model, identifier: string?)
	assert(RunService:IsServer(), `'TrackObject' can only be called by the server!`)
	assert(object:IsA("Model"), `Expected object to be a Model, got '{object.ClassName}'`)

	object:SetAttribute(`DubitEngagement_Identifier`, identifier)
	object:AddTag(`DubitEngagement_Object`)
end

--[=[
	@within Engagements

	Initializes the Engagements package by setting up necessary event listeners and tracking systems.

	### How It Works:
	- Ensures initialization only happens once.
	- Retrieves the package's remote event for communication.
	- If running on the **server**, it listens for `ZoneEntered` and `ZoneLeft` events
	  from clients and fires corresponding signals.
	- If running on the **client**, it:
		- Tracks engagement zones by binding to tagged objects.
		- Runs validation checks each frame (`Heartbeat`).
		- Updates character overlap parameters when the player’s character is added or removed.

	:::caution
	The Engagements package initializes itself automatically. Developers requiring this module do not need to call this
	function.
	:::
]=]
function Engagements.interface.Initialize()
	if isInitialised then
		assert(isInitialised == false, `Engagements package is already initialised!`)
	else
		isInitialised = true
	end

	local remoteEvent = getPackageRemoteEvent()

	if RunService:IsServer() then
		Players.PlayerRemoving:Connect(function(player)
			Engagements.internal.playerActive[player] = nil
		end)

		remoteEvent.OnServerEvent:Connect(function(player: Player, event: Event, ...)
			if not Engagements.internal.playerActive[player] then
				Engagements.internal.playerActive[player] = {}
			end

			if event == "ZoneEntered" then
				local model = select(1, ...)
				local identifier = model:GetAttribute(`DubitEngagement_Identifier`)

				Engagements.interface.ZoneEntered:Fire(player, identifier or model)
			elseif event == "ZoneLeft" then
				local model = select(1, ...)
				local identifier = model:GetAttribute(`DubitEngagement_Identifier`)

				Engagements.interface.ZoneLeft:Fire(player, identifier or model)
			elseif event == "ObjectActive" then
				local object = select(1, ...)

				Engagements.internal.playerActive[player][object] = true
			elseif event == "ObjectNotActive" then
				local object = select(1, ...)

				Engagements.internal.playerActive[player][object] = nil
			elseif event == "CaptureTriggered" then
				for model in Engagements.internal.playerActive[player] do
					local identifier = model:GetAttribute(`DubitEngagement_Identifier`)

					Engagements.interface.InScreenshot:Fire(player, identifier or model)
				end
			elseif event == "GuiActive" then
				local identifier = select(1, ...)

				Engagements.interface.ViewedGui:Fire(player, identifier)
			elseif event == "GuiInteracted" then
				local identifier = select(1, ...)

				Engagements.interface.InteractedWithGui:Fire(player, identifier)
			end
		end)
	else
		bindToTag(`DubitEngagement_Zone`, function(model)
			table.insert(Engagements.internal.trackedZones, model)
		end)

		bindToTag(`DubitEngagement_Object`, function(model)
			table.insert(Engagements.internal.trackedObjects, model)
		end)

		bindToTag(`DubitEngagement_Video`, function(video)
			table.insert(Engagements.internal.trackedVideos, video)
		end)

		bindToTag(`DubitEngagement_Gui`, function(gui)
			table.insert(Engagements.internal.trackedGuis, gui)
		end)

		UserInputService.InputEnded:Connect(function(...)
			Engagements.internal.OnGuiInput(...)
		end)

		CaptureService.CaptureEnded:Connect(function()
			remoteEvent:FireServer("CaptureTriggered")
		end)

		RunService.Heartbeat:Connect(function()
			Engagements.internal.ValidateZone()
			Engagements.internal.ValidateObjects()
			Engagements.internal.ValidateVideo()
			Engagements.internal.ValidateGuis()
		end)

		Players.LocalPlayer.CharacterAdded:Connect(function(character)
			Engagements.internal.characterOverlapParams:AddToFilter(character)
		end)

		Players.LocalPlayer.CharacterRemoving:Connect(function(character)
			local clone = table.clone(Engagements.internal.characterOverlapParams.FilterDescendantsInstances)
			local index = table.find(clone, character)

			if index then
				table.remove(clone, index)

				Engagements.internal.characterOverlapParams.FilterDescendantsInstances = clone
			end
		end)
	end
end

export type Event =
	"ZoneEntered"
	| "ZoneLeft"
	| "ObjectActive"
	| "ObjectNotActive"
	| "CaptureTriggered"
	| "GuiActive"
	| "GuiNotActive"
	| "GuiInteracted"

return Engagements.interface
