--[[
	System:
		System gives us the ability to manage in-game systems, both on the client side and server side. It provides
		support for lifecyle methods "Init" and "Start", as well as priority-based loading.

	Documentation has been written in a Moonwave styled format, for documentation outside of moonwave - comments have
	been made to provide insight.
]]
local RunService = game:GetService("RunService")

local DEBUG_PRIORITY = true

local INIT_FUNCTION_NAME = "Init"
local START_FUNCTION_NAME = "Start"
local METHOD_TIMEOUT_SECONDS = 5

local addedSystems: { { system: System, failedOnce: boolean } } = {}
local errors: { [string]: { { system: System, response: string } } } = {}

--[=[
	@class System

		System gives us the ability to manage in-game systems.

	---

		Supports systems on both client side and server side. It provides support for lifecyle methods "Init" and
		"Start", as well as priority-based loading.

]=]
local System = {}

System.RuntimeStart = os.clock()

local function prioritySortAddedSystems()
	table.sort(addedSystems, function(a, b)
		return a.system.Priority < b.system.Priority
	end)

	if DEBUG_PRIORITY then
		warn(`[System] {RunService:IsServer() and "Server" or "Client"} load order:`)
		for loadOrder, system in addedSystems do
			local iconString = system.system.Icon and `{system.system.Icon} ` or ""
			print(`{loadOrder} - [{iconString}{system.system.Name}] :: {system.system.Priority}`)
		end
	end
end

local function initializeSystemMethod(methodName: string)
	methodName = if typeof(methodName) == "string" then methodName else INIT_FUNCTION_NAME

	if not errors[methodName] then
		errors[methodName] = {}
	end

	for _, data in addedSystems do
		if data.failedOnce then
			continue
		end

		local success, errorMessage = pcall(function()
			if typeof(data.system[methodName]) ~= "function" then
				return
			end

			local yieldCoroutine = coroutine.create(function()
				data.system[methodName](data.system)
			end)

			local yieldTime = 0

			local executed, message = coroutine.resume(yieldCoroutine)
			if not executed then
				error(message, 2)
			end

			while coroutine.status(yieldCoroutine) == "suspended" do
				yieldTime += task.wait(1)

				if yieldTime > METHOD_TIMEOUT_SECONDS then
					warn(
						`[System] Module {data.system.Name}:{methodName} took more than {METHOD_TIMEOUT_SECONDS} seconds to initialize.`
					)
					data.failedOnce = true
					return
				end
			end

			if coroutine.status(yieldCoroutine) == "dead" and not executed then
				error(message)
			end
		end)

		if not success then
			table.insert(errors[methodName], { system = data.system, response = errorMessage })
			warn(
				`[System] Module {data.system.Name}:{methodName} failed to initialize: {errorMessage}\n{debug.traceback()}`
			)
		end
	end
end

--[=[
	@method AddSystemsFolder
	@within System
	@param folder Folder -- Folder should contain children that are modules.

	Add a folder that contains children that are systems to be initialized.
	Note that systems without a priority are processed last.
]=]
function System:AddSystemsFolder(instance: Instance)
	for _, systemModule in instance:GetChildren() do
		if not systemModule:IsA("ModuleScript") then
			continue
		end

		local success, errorMessage = pcall(function()
			local newlyAddedSystem = require(systemModule)

			newlyAddedSystem.Icon = newlyAddedSystem.Icon
			newlyAddedSystem.Name = newlyAddedSystem.Name or `❓ {systemModule.Name}`
			newlyAddedSystem.Priority = newlyAddedSystem.Priority or math.huge

			table.insert(addedSystems, { system = newlyAddedSystem, failedOnce = false })
		end)

		if not success then
			warn(`[System] Failed to add {systemModule.Name} to systems: {errorMessage}\n{debug.traceback()}`)
		end
	end
end

--[=[
	@method Start
	@within System
	@return table -- errors can return a table of errors thrown during initialization.

	Call only after you've added any folders containing modules that you wish to become systems.
]=]
function System:Start()
	prioritySortAddedSystems()

	initializeSystemMethod(INIT_FUNCTION_NAME)
	initializeSystemMethod(START_FUNCTION_NAME)

	for _, methodErrorGroup in errors do
		if #methodErrorGroup > 0 then
			for methodName, errorMessage in methodErrorGroup do
				warn(`[System] {errorMessage.system.Name}:{methodName} failed to initialize: {errorMessage.response}`)
			end
		end
	end

	return errors
end

export type System = {
	Icon: string?,
	Name: string,
	Priority: number,
	[any]: any,
}

return System
