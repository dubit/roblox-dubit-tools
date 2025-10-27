return function()
	local Provider = require(script.Parent)

	local TEST_DATASTORE = "__DATASTORE_TEST"
	local TEST_KEY = "__KEY"

	describe("offline datastore budget", function()
		if game.PlaceId ~= 0 then
			return
		end

		Provider.isOffline = true

		it("get async budget should equal 2500", function()
			expect(Provider:GetBudgetForRequestType(Enum.DataStoreRequestType.GetAsync)).to.equal(2500)
			expect(Provider:GetBudgetForRequestType(Enum.DataStoreRequestType.GetSortedAsync)).to.equal(2500)
		end)

		it("set async budget should equal 2500", function()
			expect(Provider:GetBudgetForRequestType(Enum.DataStoreRequestType.SetIncrementAsync)).to.equal(2500)
			expect(Provider:GetBudgetForRequestType(Enum.DataStoreRequestType.SetIncrementSortedAsync)).to.equal(2500)
		end)

		it("update async budget should equal 2500", function()
			expect(Provider:GetBudgetForRequestType(Enum.DataStoreRequestType.UpdateAsync)).to.equal(2500)
		end)
	end)

	describe("online datastore budget", function()
		if game.PlaceId == 0 then
			return
		end

		Provider.isOffline = false

		it("get async budget should return number", function()
			expect(Provider:GetBudgetForRequestType(Enum.DataStoreRequestType.GetAsync)).to.be.a("number")
			expect(Provider:GetBudgetForRequestType(Enum.DataStoreRequestType.GetSortedAsync)).to.be.a("number")
		end)

		it("set async budget should return number", function()
			expect(Provider:GetBudgetForRequestType(Enum.DataStoreRequestType.SetIncrementAsync)).to.be.a("number")
			expect(Provider:GetBudgetForRequestType(Enum.DataStoreRequestType.SetIncrementSortedAsync)).to.be.a(
				"number"
			)
		end)

		it("update async budget should return number", function()
			expect(Provider:GetBudgetForRequestType(Enum.DataStoreRequestType.UpdateAsync)).to.be.a("number")
		end)
	end)

	describe("datastore should be able to set, get & remove data", function()
		it("UpdateAsync() should SET value in datastore", function()
			expect(function()
				local success, message = Provider:UpdateAsync(TEST_DATASTORE, TEST_KEY, function()
					return 0
				end, Provider.datastoreTypes.Normal):await()

				if not success then
					error(message)
				end
			end).never.to.throw()
		end)

		it("GetAsync() should be return the SET value", function()
			expect(function()
				expect(function()
					local sucess, value = Provider:GetAsync(TEST_DATASTORE, TEST_KEY, Provider.datastoreTypes.Normal)
						:await()

					expect(sucess).to.equal(true)
					expect(value).to.equal(0)
				end).never.to.throw()
			end).never.to.throw()
		end)

		it("RemoveAsync() should be remove the SET value", function()
			expect(function()
				expect(function()
					local success, message = Provider:RemoveAsync(TEST_DATASTORE, TEST_KEY):await()

					if not success then
						error(message)
					end
				end).never.to.throw()
			end).never.to.throw()
		end)

		it("GetAsync() should be return nothing", function()
			expect(function()
				local sucess, value = Provider:GetAsync(TEST_DATASTORE, TEST_KEY):await()

				expect(sucess).to.equal(true)
				expect(value).to.equal(nil)
			end).never.to.throw()
		end)
	end)
end
