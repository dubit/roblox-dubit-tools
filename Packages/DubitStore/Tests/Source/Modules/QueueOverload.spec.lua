return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local DubitStore = require(ReplicatedStorage.Packages.DubitStore)

	it("should error if I stack threads in DubitStore", function()
		local promises = {}
		local didErrorOut = false

		for _ = 1, 10 do
			table.insert(
				promises,
				DubitStore:GetDataAsync("_", "_")
					:andThen(function()
						DubitStore:ClearCache("_", "_")
					end)
					:catch(function()
						didErrorOut = true
					end)
			)
		end

		for _, promise in promises do
			promise:await()
		end

		expect(didErrorOut).to.equal(true)
	end)
end
