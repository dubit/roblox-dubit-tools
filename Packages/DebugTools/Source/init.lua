--[[
	Main source file for debug tools. This can be required from both the client and server and it will return the
	correct file (either Server.lua or Client.lua)

	Debug Tools is a package which self-initialises (it contains ModuleScripts with RunContexts set to both client and
	server which cause the package to require itself and initialise itself)

	As it self initialises, developers may experience odd behaviour if DebugTools is required from any Actor contexts.
	Therefore, when using debug tools it is recommended to only require it from standard roblox folders (non-actors).
	This is why this code uses SharedTables to produce a warning if the code is required multiple times.
]]
local RunService = game:GetService("RunService")
local SharedTableRegistry = game:GetService("SharedTableRegistry")

local debugToolsTable = SharedTableRegistry:GetSharedTable("DebugTools_SharedTable")

local DebugTools = {}

--selene: allow(global_usage)
if not debugToolsTable or not debugToolsTable.DidInit then
	local sharedTable = SharedTable.new({ DidInit = true })

	SharedTableRegistry:SetSharedTable("DebugTools_SharedTable", sharedTable)
else
	if _G.Dubit_DebugTools_Client == nil and _G.Dubit_DebugTools_Server == nil then
		warn(
			"Warning - DebugTools has been required multiple times! This may cause Debug Tools to not work as expected."
		)
	end
end

--selene: allow(global_usage)
_G.Dubit_DebugTools_Client = _G.Dubit_DebugTools_Client or script.Client
--selene: allow(global_usage)
_G.Dubit_DebugTools_Server = _G.Dubit_DebugTools_Server or script.Server

if RunService:IsClient() then
	--selene: allow(global_usage)

	DebugTools.Client = require(_G.Dubit_DebugTools_Client)
else
	--selene: allow(global_usage)

	DebugTools.Server = require(_G.Dubit_DebugTools_Server)
end

return DebugTools
