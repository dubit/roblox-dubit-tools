return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local DubitStore = require(ReplicatedStorage.Packages.DubitStore)

	local DataStore = "DataStore" .. script.Name
	local Key = "Example"

	describe("Should be able to load & save a CFrame value", function()
		beforeEach(function()
			DubitStore:SetDataAsync(DataStore, Key, { Data = CFrame.new(0, 5, 0) }):await()
			local success, errorMessage = DubitStore:PushAsync(DataStore, Key):await()

			if not success then
				return warn(errorMessage)
			end

			DubitStore:ClearCache(DataStore, Key)
		end)

		it("Should be able to parse/deserialise the CFrame", function()
			local success, data = DubitStore:GetDataAsync(DataStore, Key):await()

			expect(success).to.equal(true)

			expect(data.Data).to.be.a("userdata")
			expect(data.Data.X).to.equal(0)
			expect(data.Data.Y).to.equal(5)
			expect(data.Data.Z).to.equal(0)
		end)
	end)

	describe("Should be able to load & save a Vector3 value", function()
		beforeEach(function()
			DubitStore:SetDataAsync(DataStore, Key, { Data = Vector3.new(5, 0, 5) }):await()
			local success, errorMessage = DubitStore:PushAsync(DataStore, Key):await()

			if not success then
				return warn(errorMessage)
			end

			DubitStore:ClearCache(DataStore, Key)
		end)

		it("Should be able to parse/deserialise the Vector3", function()
			local success, data = DubitStore:GetDataAsync(DataStore, Key):await()

			expect(success).to.equal(true)

			expect(data.Data).to.be.a("vector")
			expect(data.Data.X).to.equal(5)
			expect(data.Data.Y).to.equal(0)
			expect(data.Data.Z).to.equal(5)
		end)
	end)
end
