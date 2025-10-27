--[[
	Weaver:
]]
--

local Promise = require(script.Parent.Promise)
local Signal = require(script.Parent.Signal)

local Weaver = {}

Weaver.interface = {}
Weaver.internal = {}
Weaver.lifecycles = {}

Weaver.lifecycles.systems = {}
Weaver.lifecycles.behaviours = {}

Weaver.lifecycles.behaviours.startOfLife = {}
Weaver.lifecycles.behaviours.endOfLife = {}

Weaver.interface.Behaviour = require(script.Behaviour)
Weaver.interface.System = require(script.System)

Weaver.interface.Initialized = Signal.new()
Weaver.interface.IsInitialized = false

Weaver.InstancePool = require(script.InstancePool)

function Weaver.internal:SortSystemsByPriority(systemsList)
	table.sort(systemsList, function(systemA, systemB)
		return systemA.Priority > systemB.Priority
	end)

	return systemsList
end

function Weaver.internal:InitSystems()
	local offsetTime = os.clock()

	return Promise.new(function(resolve)
		local registeredSystems

		registeredSystems = Weaver.interface.System.fetchAllInstances()
		registeredSystems = Weaver.internal:SortSystemsByPriority(registeredSystems)

		for _, lifecycleMethod in Weaver.lifecycles.systems do
			for _, systemObject in registeredSystems do
				systemObject:_InvokeLifecycleMethod(lifecycleMethod)
			end
		end

		resolve(os.clock() - offsetTime)
	end)
end

function Weaver.internal:InitBehaviours()
	local offsetTime = os.clock()

	return Promise.new(function(resolve)
		Weaver.InstancePool.InstanceAdded:Connect(function(tag, object)
			local taggedObjects = Weaver.interface.Behaviour.fetch(tag)

			for _, lifecycleMethod in Weaver.lifecycles.behaviours.startOfLife do
				for _, behaviour in taggedObjects do
					behaviour:_InvokeLifecycleMethod(lifecycleMethod, object)
				end
			end
		end)

		Weaver.InstancePool.InstanceDestroyed:Connect(function(tag, object)
			local taggedObjects = Weaver.interface.Behaviour.fetch(tag)

			for _, lifecycleMethod in Weaver.lifecycles.behaviours.endOfLife do
				for _, behaviour in taggedObjects do
					behaviour:_InvokeLifecycleMethod(lifecycleMethod, object)
				end
			end
		end)

		for _, tag in Weaver.interface.Behaviour.fetchTags() do
			Weaver.InstancePool:CreateInstanceTagConnections(tag)
		end

		resolve(os.clock() - offsetTime)
	end)
end

function Weaver.interface:ImplementSystemLifecycleMethod(lifecycleMethodName)
	table.insert(Weaver.lifecycles.systems, lifecycleMethodName)
end

function Weaver.interface:ImplementBehaviourLifecycleMethod(lifecycleMethodName, isEndOfLifeLifecycleMethod)
	if isEndOfLifeLifecycleMethod then
		table.insert(Weaver.lifecycles.behaviours.endOfLife, lifecycleMethodName)
	else
		table.insert(Weaver.lifecycles.behaviours.startOfLife, lifecycleMethodName)
	end
end

function Weaver.interface:Init()
	Weaver.interface.IsInitialized = true
	Weaver.interface.Initialized:Fire()

	return Promise.all({
		Weaver.internal:InitSystems(),
		Weaver.internal:InitBehaviours(),
	})
end

return Weaver.interface
