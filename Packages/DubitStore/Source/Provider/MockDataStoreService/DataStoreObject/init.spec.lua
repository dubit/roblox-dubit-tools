return function()
	local DataStoreObject = require(script.Parent)

	describe("datastore should be able to set, get & remove data", function()
		local storeObject

		local TEST_KEY = "__KEY"

		beforeAll(function()
			storeObject = DataStoreObject.new("ExampleOfflineStore")
		end)

		it("Update() should SET value in datastore", function()
			expect(function()
				storeObject:Update(TEST_KEY, function()
					return 0
				end)
			end).never.to.throw()
		end)

		it("Get() should be return the SET value", function()
			expect(function()
				expect(function()
					local value = storeObject:Get(TEST_KEY)

					expect(value).to.equal(0)
				end).never.to.throw()
			end).never.to.throw()
		end)

		it("Remove() should be remove the SET value", function()
			expect(function()
				storeObject:Remove(TEST_KEY)
			end).never.to.throw()
		end)

		it("Get() should be return nothing", function()
			expect(function()
				local value = storeObject:Get(TEST_KEY)

				expect(value).to.equal(nil)
			end).never.to.throw()
		end)
	end)
end
