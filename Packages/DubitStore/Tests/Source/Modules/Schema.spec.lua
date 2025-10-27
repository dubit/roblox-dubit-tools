return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local DubitStore = require(ReplicatedStorage.Packages.DubitStore)

	local TEST_SCHEMA_PREFIX = "TEST_SCHEMA_"

	describe("building a dubit store schema", function()
		it("CreateDataSchema() will not throw with basic payload", function()
			expect(function()
				DubitStore:CreateDataSchema(TEST_SCHEMA_PREFIX .. 1, {
					TestKey = DubitStore.Container.new("TestValue"),
				})
			end).never.to.throw()
		end)

		it("CreateDataSchema() will not throw with complicated payload", function()
			expect(function()
				DubitStore:CreateDataSchema(TEST_SCHEMA_PREFIX .. 2, {
					TestKey = DubitStore.Container.new("TestValue"),
					TestTableKey = DubitStore.Container.new({
						TestKey = DubitStore.Container.new("TestValue"),
					}),
				})
			end).never.to.throw()
		end)

		it("CreateDataSchema() should throw with an invalid index payload", function()
			expect(function()
				DubitStore:CreateDataSchema(TEST_SCHEMA_PREFIX .. 3, {
					DubitStore.Container.new("TestValue"),
				})
			end).to.throw()
		end)

		it("CreateDataSchema() should throw with an invalid value payload", function()
			expect(function()
				DubitStore:CreateDataSchema(TEST_SCHEMA_PREFIX .. 4, {
					TestKey = 1,
				})
			end).to.throw()
		end)
	end)

	describe("validating a dubit store schema", function()
		it("ValidateDataSchema() should be able to parse a simple schema", function()
			local response = DubitStore:ValidateDataSchema({
				TestKey = DubitStore.Container.new("TestValue"),
			})

			expect(response).to.equal(true)
		end)

		it("ValidateDataSchema() should be able to parse a complicated schema", function()
			local response = DubitStore:ValidateDataSchema({
				TestKey = DubitStore.Container.new("TestValue"),
				TestTableKey = DubitStore.Container.new({
					TestKey = DubitStore.Container.new("TestValue"),
				}),
			})

			expect(response).to.equal(true)
		end)

		it("ValidateDataSchema() should fail to parse simple payload with invalid index", function()
			local response, message = DubitStore:ValidateDataSchema({
				DubitStore.Container.new("TestValue"),
			})

			expect(response).to.equal(false)
			expect(message).to.be.a("string")
		end)

		it("ValidateDataSchema() should fail to parse simple payload with invalid value", function()
			local response, message = DubitStore:ValidateDataSchema({
				TestKey = 1,
			})

			expect(response).to.equal(false)
			expect(message).to.be.a("string")
		end)

		it("SchemaExists() should return false given an invalid schema identifier", function()
			local response = DubitStore:SchemaExists(TEST_SCHEMA_PREFIX .. "NON_EXISTANT_SCHEMA")

			expect(response).to.equal(false)
		end)

		it("SchemaExists() should return true given an valid schema identifier", function()
			expect(function()
				DubitStore:CreateDataSchema(TEST_SCHEMA_PREFIX .. "EXISTANT_SCHEMA", {})
			end).never.to.throw()

			local response = DubitStore:SchemaExists(TEST_SCHEMA_PREFIX .. "EXISTANT_SCHEMA")

			expect(response).to.equal(true)
		end)

		it("GetDataSchema() should return the schema given to DubitStore", function()
			local schemaTemplate = {}

			expect(function()
				DubitStore:CreateDataSchema(TEST_SCHEMA_PREFIX .. "TEMPLATE", schemaTemplate)
			end).never.to.throw()

			expect(DubitStore:GetDataSchema(TEST_SCHEMA_PREFIX .. "TEMPLATE")).to.equal(schemaTemplate)
		end)

		it("GenerateRawTable() should be able to dump & return the schema without containers", function()
			local schemaTemplate = {
				TestKey = DubitStore.Container.new("Test Key!"),
			}

			expect(function()
				DubitStore:CreateDataSchema(TEST_SCHEMA_PREFIX .. "DUMP", schemaTemplate)
			end).never.to.throw()

			local tableSchema = DubitStore:GetDataSchema(TEST_SCHEMA_PREFIX .. "DUMP")

			expect(tableSchema).to.equal(schemaTemplate)

			local tableDump = DubitStore:GenerateRawTable(tableSchema)

			expect(tableDump.TestKey).to.be.a("string")
			expect(tableDump.TestKey).to.equal("Test Key!")
		end)
	end)
end
