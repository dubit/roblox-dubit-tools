--[[
	Roblox Validator - validates a datastore session id from a datastore key info instance.
]]
--

local SESSION_EXPIRY_TIME = 60 * 30

local Validator = {}

Validator.interface = {}

--[[
	simple method to validate that the key info instance is referenced to the current server.
]]
--
function Validator.interface:ValidateSessionIdFromKeyInfo(keyInfo)
	-- keyInfo can be nil on our first GET request.
	if not keyInfo then
		return true
	end

	local metadata = keyInfo:GetMetadata()

	-- if there's no previous metadata, it's not been saved with DubitStore before.
	if not metadata then
		return true
	end

	-- if there's no previous SessionId, it's not locked.
	if not metadata.SessionId then
		return true
	end

	-- SessionId can be set to "" while running in studio.
	if metadata.SessionId == "" then
		return true
	end

	-- if there is a SessionId, the only our server should be able to write to that key.
	if metadata.SessionId == game.JobId then
		return true
	end

	local dateTime = DateTime.now()
	local dateTimeMillis = dateTime.UnixTimestampMillis
	local sessionLength = keyInfo.UpdatedTime - dateTimeMillis

	-- in cases where the previous server crashes, we want to make sure that the players data isn't locked forever.
	if sessionLength > SESSION_EXPIRY_TIME then
		return true
	end

	return false
end

return Validator.interface :: typeof(Validator.interface)
