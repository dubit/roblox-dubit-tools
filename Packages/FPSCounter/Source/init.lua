--[=[
	@class FPSCounter

	FPS Counter is a super lightweight FPS counter. This FPS counter has no permissions system, any player may open
	this UI widget.

	It can be opened by typing /fps into the chat, or pressing F7.

	This module will self-initialize using the Initializer script, developers do not even need to require the module.
	This is because it contains a script in ReplicatedStorage with the "Client" RunContext.

	The :Mount function should be called immediately if the FPS counter should be enabled by default.
]=]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local didStart = false

local FPSCounter = {}

--[=[
	@prop IsMounted boolean
	@within FPSCounter
]=]
FPSCounter.IsMounted = false

--[=[
	@prop ScreenGui ScreenGui?
	@within FPSCounter
]=]
FPSCounter.ScreenGui = nil

--[=[
	@prop HeartbeatConnection RBXScriptConnection?
	@within FPSCounter
]=]
FPSCounter.HeartbeatConnection = nil :: RBXScriptConnection?

--[=[
	@method Mount
	@within FPSCounter
	@client

	Mounts the FPS counter and starts listening to a heartbeat connection to update the FPS value
]=]
function FPSCounter:Mount()
	if self.IsMounted then
		return
	end

	self.ScreenGui = Instance.new("ScreenGui")
	self.ScreenGui.ResetOnSpawn = false
	self.ScreenGui.DisplayOrder = 1000
	self.ScreenGui.Parent = player.PlayerGui

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(0.1, 0, 0, 20)
	textLabel.Position = UDim2.fromScale(0, 1)
	textLabel.AnchorPoint = Vector2.new(0, 1)
	textLabel.Text = "FPS"
	textLabel.Parent = self.ScreenGui

	local frameUpdateTable: { [number]: number? } = {}
	local fpsTrackStartTime: number = os.clock()
	self.HeartbeatConnection = RunService.Heartbeat:Connect(function()
		-- https://devforum.roblox.com/t/get-client-fps-trough-a-script/282631/
		local lastIteration = os.clock()

		for Index = #frameUpdateTable, 1, -1 do
			frameUpdateTable[Index + 1] = frameUpdateTable[Index] >= lastIteration - 1 and frameUpdateTable[Index]
				or nil
		end

		frameUpdateTable[1] = lastIteration

		local fps: number = math.floor(
			os.clock() - fpsTrackStartTime >= 1 and #frameUpdateTable
				or #frameUpdateTable / (os.clock() - fpsTrackStartTime)
		)

		textLabel.Text = `FPS: {fps}`
	end)

	self.IsMounted = true
end

--[=[
	@method Unmount
	@within FPSCounter
	@client

	Unmounts the FPS counter and disconnects any active heartbeat connections
]=]
function FPSCounter:Unmount()
	if not self.IsMounted then
		return
	end

	if self.ScreenGui then
		self.ScreenGui:Destroy()
		self.ScreenGui = nil
	end

	if self.HeartbeatConnection then
		self.HeartbeatConnection:Disconnect()
		self.HeartbeatConnection = nil
	end

	self.IsMounted = false
end

--[=[
	@method Toggle
	@within FPSCounter
	@client

	Toggles the visibility of the FPS counter
]=]
function FPSCounter:Toggle()
	if self.IsMounted then
		self:Unmount()
	else
		self:Mount()
	end
end

--[=[
	@method Start
	@within FPSCounter
	@client

	Starts the FPS counter. This should be called to initialize the system
]=]
function FPSCounter:Start()
	if didStart then
		return
	end

	if not RunService:IsClient() then
		warn("FPS Counter may only be used on the client")
		return
	end

	didStart = true

	player.Chatted:Connect(function(message: string)
		if message == "/fps" then
			self:Toggle()
		end
	end)

	UserInputService.InputBegan:Connect(function(inputObject: InputObject)
		if inputObject.UserInputState ~= Enum.UserInputState.Begin then
			return
		end

		if inputObject.KeyCode == Enum.KeyCode.F7 then
			self:Toggle()
		end
	end)
end

return FPSCounter
