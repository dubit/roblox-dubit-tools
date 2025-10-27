return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local DubitStore = require(ReplicatedStorage.Packages.DubitStore)

	local TEST_SCHEMA_NAME = "TEST_RECONSILE_SCHEMA"

	describe("reconciling data schemes", function()
		beforeAll(function()
			DubitStore:CreateDataSchema(TEST_SCHEMA_NAME, {
				Key = DubitStore.Container.new(0),
				KeyTable = DubitStore.Container.new({
					Key = DubitStore.Container.new(0),
				}),
			})
		end)

		it("filling in blocks of data schemes", function()
			local reconciledData = DubitStore:ReconcileData({
				Key2 = 0,
			}, TEST_SCHEMA_NAME)

			expect(reconciledData.Key).to.equal(0)
			expect(reconciledData.Key2).to.equal(0)
		end)

		it("overwriting blocks in data scheme", function()
			local reconciledData = DubitStore:ReconcileData({
				Key = 1,
			}, TEST_SCHEMA_NAME)

			expect(reconciledData.Key).to.equal(1)
		end)

		it("filling in blocks of complicated data schemes", function()
			local reconciledData = DubitStore:ReconcileData({
				KeyTable = {
					Key2 = 1,
				},
			}, TEST_SCHEMA_NAME)

			expect(reconciledData.Key).to.equal(0)
			expect(reconciledData.KeyTable.Key).to.equal(0)
			expect(reconciledData.KeyTable.Key2).to.equal(1)
		end)

		it("overwriting blocks in complicated data scheme", function()
			local reconciledData = DubitStore:ReconcileData({
				KeyTable = {
					Key = 1,
				},
			}, TEST_SCHEMA_NAME)

			expect(reconciledData.Key).to.equal(0)
			expect(reconciledData.KeyTable.Key).to.equal(1)
		end)
	end)
end
