return function()
	local DataStoreObject = require(script.Parent.Parent.DataStoreObject)
	local DataStorePage = require(script.Parent)

	describe("'VersionDataStorePage' functions hand-in-hand with 'DataStoreObject'", function()
		local storeObject
		local pageObject

		beforeAll(function()
			storeObject = DataStoreObject.new("Data Store Page Demo")
		end)

		it(
			"should be able to generate a 'VersionDataStorePage' from a datastore private _versionOrder table",
			function()
				pageObject = DataStorePage.fromDatastore(storeObject)

				expect(pageObject).to.be.ok()
			end
		)
	end)

	describe("'VersionDataStorePage' should respect the parameters used in traditional version pages", function()
		local storeObject
		local pageObject

		beforeAll(function()
			storeObject = DataStoreObject.new("Data Store Page Demo")

			for index = 1, 10 do
				task.wait(0.01)

				storeObject:Update(`Key{index}`, function()
					return index
				end)
			end
		end)

		it("'VersionDataStorePage' should respect descending/ascending order", function()
			pageObject = DataStorePage.fromDatastore(storeObject, Enum.SortDirection.Descending, nil, nil, 5)

			expect(pageObject).to.be.ok()
			expect(pageObject._page[1].CreatedTime < pageObject._page[2].CreatedTime).to.equal(false)
			expect(pageObject._page[1].CreatedTime > pageObject._page[2].CreatedTime).to.equal(true)

			pageObject = DataStorePage.fromDatastore(storeObject, Enum.SortDirection.Ascending, nil, nil, 5)

			expect(pageObject).to.be.ok()
			expect(pageObject._page[1].CreatedTime > pageObject._page[2].CreatedTime).to.equal(false)
			expect(pageObject._page[1].CreatedTime < pageObject._page[2].CreatedTime).to.equal(true)
		end)

		it("'VersionDataStorePage' should respect the page size parameter", function()
			pageObject = DataStorePage.fromDatastore(storeObject, nil, nil, nil, 5)

			expect(#pageObject._page).to.equal(5)

			pageObject:AdvanceToNextPageAsync()

			expect(#pageObject._page).to.equal(5)
			expect(pageObject.IsFinished).to.equal(true)
		end)

		it(
			"'VersionDataStorePage' should continue onto the next page once :AdvanceToNextPageAsync() is called",
			function()
				pageObject = DataStorePage.fromDatastore(storeObject, nil, nil, nil, 5)

				local key1Version = pageObject._page[1].Version

				expect(key1Version).to.be.ok()

				pageObject:AdvanceToNextPageAsync()

				expect(pageObject._page[1].Version).to.never.equal(key1Version)
				expect(pageObject.IsFinished).to.equal(true)
			end
		)
	end)
end
