return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local DubitStore = require(ReplicatedStorage.Packages.DubitStore)

	local DataStore = "DataStore" .. script.Name
	local Key = "Example"

	beforeEach(function()
		DubitStore:GetDataAsync(DataStore, Key):await()
	end)

	it("Should be able to fetch metadata from cached datastore", function()
		local success, result = DubitStore:GetMetaDataAsync(DataStore, Key):await()

		expect(success).to.equal(true)
		expect(result).to.be.a("table")
	end)

	it("Should be able to set metadata to cached datastore", function()
		local success = DubitStore:SetDataAsync(DataStore, Key, { Data = 1 }):await()

		expect(success).to.equal(true)

		success = DubitStore:SetMetaDataAsync(DataStore, Key, { Example = 123 }):await()

		expect(success).to.equal(true)

		success = DubitStore:PushAsync(DataStore, Key):await()

		expect(success).to.equal(true)

		DubitStore:ClearCache(DataStore, Key)
	end)

	it("Should be able to fetch updated metadata from cached datastore", function()
		local success, result = DubitStore:GetMetaDataAsync(DataStore, Key):await()

		expect(success).to.equal(true)
		expect(result).to.be.a("table")
		expect(result.Example).to.equal(123)
	end)
end
