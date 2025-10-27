return function()
	local DataStoreObject = require(script.Parent.Parent.DataStoreObject)
	local DataStorePage = require(script.Parent)

	describe("'OrderedDataStorePage' functions hand-in-hand with 'DataStoreObject'", function()
		local storeObject
		local pageObject

		beforeAll(function()
			storeObject = DataStoreObject.new("Data Store Page Demo")
		end)

		it("should be able to generate a 'DataStorePage' from a datastore private _keys table", function()
			pageObject = DataStorePage.fromDatastore(storeObject, true, 10)

			expect(pageObject).to.be.ok()
		end)
	end)

	describe("'OrderedDataStorePage' should respect the parameters used in traditional ordered pages", function()
		local storeObject
		local pageObject

		beforeAll(function()
			storeObject = DataStoreObject.new("Data Store Page Demo")

			for index = 1, 10 do
				storeObject:Update(`Key{index}`, function()
					return index
				end)
			end
		end)

		it("'OrderedDataStorePage' should respect ascending order", function()
			pageObject = DataStorePage.fromDatastore(storeObject, true, 10)

			expect(pageObject).to.be.ok()
			expect(pageObject._page[1].key).to.equal("Key1")
			expect(pageObject._page[2].key).to.equal("Key2")
			expect(pageObject._page[3].key).to.equal("Key3")
			expect(pageObject._page[4].key).to.equal("Key4")
			expect(pageObject._page[5].key).to.equal("Key5")
		end)

		it("'OrderedDataStorePage' should respect descendant order", function()
			pageObject = DataStorePage.fromDatastore(storeObject, false, 10)

			expect(pageObject).to.be.ok()
			expect(pageObject._page[1].key).to.equal("Key10")
			expect(pageObject._page[2].key).to.equal("Key9")
			expect(pageObject._page[3].key).to.equal("Key8")
			expect(pageObject._page[4].key).to.equal("Key7")
			expect(pageObject._page[5].key).to.equal("Key6")
		end)

		it("'OrderedDataStorePage' should respect the page size parameter", function()
			pageObject = DataStorePage.fromDatastore(storeObject, true, 5)

			expect(#pageObject._page).to.equal(5)

			pageObject:AdvanceToNextPageAsync()

			expect(#pageObject._page).to.equal(5)
			expect(pageObject.IsFinished).to.equal(true)
		end)

		it(
			"'OrderedDataStorePage' should continue onto the next page once :AdvanceToNextPageAsync() is called",
			function()
				pageObject = DataStorePage.fromDatastore(storeObject, true, 5)

				expect(pageObject._page[1].key).to.equal("Key1")

				pageObject:AdvanceToNextPageAsync()

				expect(pageObject._page[1].key).to.equal("Key6")
				expect(pageObject.IsFinished).to.equal(true)
			end
		)

		it("'OrderedDataStorePage' should should respect minValue parameter", function()
			pageObject = DataStorePage.fromDatastore(storeObject, true, 10, 3)

			expect(pageObject._page[1].key).to.equal("Key3")
			expect(pageObject._page[2].key).to.equal("Key4")
			expect(pageObject._page[3].key).to.equal("Key5")
		end)

		it("'OrderedDataStorePage' should should respect maxValue parameter", function()
			pageObject = DataStorePage.fromDatastore(storeObject, false, 10, 0, 8)

			expect(pageObject._page[1].key).to.equal("Key8")
			expect(pageObject._page[2].key).to.equal("Key7")
			expect(pageObject._page[3].key).to.equal("Key6")
		end)

		it("'OrderedDataStorePage' should should respect both maxValue & minValue parameters", function()
			pageObject = DataStorePage.fromDatastore(storeObject, true, 10, 3, 8)

			expect(pageObject._page[1].key).to.equal("Key3")
			expect(pageObject._page[2].key).to.equal("Key4")

			expect(pageObject._page[5].key).to.equal("Key7")
			expect(pageObject._page[6].key).to.equal("Key8")
		end)
	end)
end
