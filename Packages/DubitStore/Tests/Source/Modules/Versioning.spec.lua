return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local DubitStore = require(ReplicatedStorage.Packages.DubitStore)

	local DataStore = "DataStore" .. script.Name
	local Key = "Example"

	local latestVersion

	beforeAll(function()
		DubitStore:SetDataAsync(DataStore, Key, { Test = 123 }):await()

		local _, _, keyInfo = DubitStore:PushAsync(DataStore, Key):await()

		if not keyInfo then
			_, _, keyInfo = DubitStore:PushAsync(DataStore, Key):await()

			latestVersion = keyInfo.Version
		end

		DubitStore:ClearCache(DataStore, Key)
	end)

	it("should be able to fetch all versions of a datastore key", function()
		local success, response = DubitStore:GetDataVersionsAsync(DataStore, Key):await()

		expect(success).to.equal(true)
		expect(response).to.be.ok()

		local instanceVersions = response:GetCurrentPage()

		expect(#instanceVersions > 0).to.equal(true)
	end)

	it("should be able to fetch data from a version", function()
		local success, response = DubitStore:GetDataAsync(DataStore, Key, latestVersion):await()

		expect(success).to.equal(true)
		expect(response).to.be.ok()
		expect(response.Test).to.equal(123)
	end)
end
