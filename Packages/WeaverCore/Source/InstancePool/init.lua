--[[
	InstancePool:
]]
--

local CollectionService = game:GetService("CollectionService")

local Signal = require(script.Parent.Parent.Signal)

local InstancePool = {}

InstancePool.connections = {}
InstancePool.interface = {}

InstancePool.interface.InstanceAdded = Signal.new()
InstancePool.interface.InstanceDestroyed = Signal.new()

function InstancePool.interface:CreateInstanceTagConnections(tag)
	assert(InstancePool.connections[tag] == nil, `Expected {tag} connections to not exist.`)

	InstancePool.connections[tag] = {}

	table.insert(
		InstancePool.connections[tag],
		CollectionService:GetInstanceAddedSignal(tag):Connect(function(object)
			InstancePool.interface.InstanceAdded:Fire(tag, object)
		end)
	)

	table.insert(
		InstancePool.connections[tag],
		CollectionService:GetInstanceRemovedSignal(tag):Connect(function(object)
			InstancePool.interface.InstanceDestroyed:Fire(tag, object)
		end)
	)

	for _, object in CollectionService:GetTagged(tag) do
		InstancePool.interface.InstanceAdded:Fire(tag, object)
	end
end

function InstancePool.interface:DestroyInstanceTagConnections(tag)
	assert(InstancePool.connections[tag] ~= "nil", `Expected {tag} connections to exist.`)

	for _, connection in InstancePool.connections[tag] do
		connection:Disconnect()
	end

	InstancePool.connections[tag] = nil
end

return InstancePool.interface
