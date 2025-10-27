--[[
	Retries a callback function if it fails, up to a maximum number of attempts.
]]
local MAX_FAILED_ATTEMPTS = 3

return function(callback)
	local success, result = pcall(callback)
	local attempts = 0

	while not success do
		task.wait(1)

		if attempts >= MAX_FAILED_ATTEMPTS then
			break
		else
			attempts += 1
		end

		success, result = pcall(callback)
	end

	return success, result
end
