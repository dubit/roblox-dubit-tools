--[[
	Will return a list of keys for a datastore object.
]]
local Package = script.Parent.Parent

local retryIfFailed = require(Package.Functions.retryIfFailed)

return function(datastore: DataStore, maxPages: number?): { string }
	local response = {}
	local keys = datastore:ListKeysAsync()
	local pageCount = 0

	while true do
		pageCount += 1

		local keysToAdd = keys:GetCurrentPage()

		for _, key: DataStoreKey in keysToAdd do
			table.insert(response, key.KeyName)
		end

		if keys.IsFinished or pageCount >= (maxPages or math.huge) then
			break
		else
			local status = retryIfFailed(function()
				keys:AdvanceToNextPageAsync()
			end)

			if not status then
				return {}
			end
		end
	end

	return response
end
