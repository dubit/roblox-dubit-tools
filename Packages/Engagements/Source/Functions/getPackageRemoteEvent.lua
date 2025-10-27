local RunService = game:GetService("RunService")

--[[
	Responsible for getting the remote event required to signal things to/from the client/server.
]]
return function(): RemoteEvent
	if RunService:IsServer() then
		local event = script:FindFirstChild("RemoteEvent")

		if not event then
			event = Instance.new("RemoteEvent")

			event.Parent = script
		end

		return event
	else
		return script:WaitForChild("RemoteEvent")
	end
end
