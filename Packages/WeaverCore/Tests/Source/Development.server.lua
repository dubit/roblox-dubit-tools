local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaverCore = require(ReplicatedStorage.Packages.WeaverCore)

local Behaviour = WeaverCore.Behaviour.new({
	Tag = "Spawn",
})

function Behaviour:WeaverUpdateBehaviour(object)
	self.Instance = object
end

function Behaviour:WeaverDestroyBehaviour()
	self.Instance = nil
end

function Behaviour:Constructor()
	print(`Constructed {self.Instance.Name}`)
end

function Behaviour:Deconstructor()
	print(`Removed {self.Instance.Name}`)
end

WeaverCore:ImplementBehaviourLifecycleMethod("WeaverUpdateBehaviour", false)
WeaverCore:ImplementBehaviourLifecycleMethod("Constructor", false)

WeaverCore:ImplementBehaviourLifecycleMethod("Deconstructor", true)
WeaverCore:ImplementBehaviourLifecycleMethod("WeaverDestroyBehaviour", true)

WeaverCore:Init():andThen(function(...)
	print(...)
end)
