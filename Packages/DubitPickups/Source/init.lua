local RunService = game:GetService("RunService")

--[=[
	@class DubitPickups

	DubitPickups entrypoint, this module contains either a `Client` table, if on the client - or a `Server` table, if on the server.
]=]
local DubitPickups = {}

DubitPickups.interface = {}

--[=[
	@client
	@prop Client DubitPickups.Client
	@within DubitPickups
]=]

--[=[
	@server
	@prop Server DubitPickups.Server
	@within DubitPickups
]=]

if RunService:IsServer() then
	DubitPickups.interface.Server = require(script.Server)
else
	DubitPickups.interface.Client = require(script.Client)
end

return DubitPickups.interface
