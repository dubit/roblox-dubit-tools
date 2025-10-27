return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local DubitStore = require(ReplicatedStorage.Packages.DubitStore)

	local DataStore = "DataStore" .. script.Name
	local Key = "Example"

	it("Should be able to set data", function()
		local success = DubitStore:SetDataAsync(DataStore, Key, { Test = 123 }):await()

		expect(success).to.equal(true)

		success = DubitStore:PushAsync(DataStore, Key):await()

		expect(success).to.equal(true)
	end)

	it("Should be able to get data", function()
		local success, response = DubitStore:GetDataAsync(DataStore, Key):await()

		expect(success).to.equal(true)
		expect(response.Test).to.equal(123)
	end)

	describe("DubitStore Session Locking", function()
		it("Should be able to lock the session data", function()
			DubitStore:SetDataSessionLocked(DataStore, Key, true)
			local success = DubitStore:PushAsync(DataStore, Key):await()

			expect(success).to.equal(true)
		end)

		it("Should be able to unlock the session data", function()
			DubitStore:SetDataSessionLocked(DataStore, Key, false)
			local success = DubitStore:PushAsync(DataStore, Key):await()

			expect(success).to.equal(true)
		end)
	end)
end
