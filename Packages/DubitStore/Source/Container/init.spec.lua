return function()
	local Container = require(script.Parent)

	describe("new", function()
		local class

		beforeAll(function()
			class = Container.new("Example")
		end)

		it("should allocate test 'Example' data", function()
			expect(class._allocated).to.equal("Example")
		end)

		it("ToString() expected to return container type", function()
			expect(class:ToString():match("Container")).to.be.ok()
		end)

		it("ToString() expected to return data type", function()
			expect(class:ToString():match("string")).to.be.ok()
		end)

		it("ToString() expected to return data as string", function()
			expect(class:ToString():match("Example")).to.be.ok()
		end)

		it("ToValue() expected to return input data", function()
			expect(class:ToString():match("Example")).to.be.ok()
		end)

		it("ToDataType() expected to return input data", function()
			expect(class:ToDataType()).to.equal("string")
		end)
	end)

	describe("it", function()
		local class = Container.new("Example")

		it("should have container type match", function()
			expect(Container.is(class)).to.equal(true)
		end)
	end)
end
