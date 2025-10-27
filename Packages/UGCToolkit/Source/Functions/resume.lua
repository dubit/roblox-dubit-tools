return function(thread: thread, ...)
	local success, result = coroutine.resume(thread, ...)

	if not success then
		warn(result)
	end
end
