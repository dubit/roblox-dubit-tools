return function()
	local System = require(script.Parent)

	it("Should be able to generate a new System object", function()
		expect(System.new({
			Name = "Test",
		})).to.be.ok()
	end)

	it("Should throw when passing an invalid source object", function()
		expect(function()
			System.new({ Name = 1 })
		end).to.throw()
	end)

	it("Should be able to identify system instances", function()
		local system = System.new({ Tag = "abc" })

		expect(System.is(system)).to.equal(true)
	end)

	describe("System lifecycles", function()
		it("should be able to execute system lifecycle methods", function()
			local system = System.new({ Name = "test" })
			local flag = false

			function system:LifeCycle()
				flag = true
			end

			system:_InvokeLifecycleMethod("LifeCycle")

			expect(flag).to.equal(true)
		end)

		it("Should be able to manipulate varadic arguments", function()
			local system = System.new({ Name = "abc" })
			local a, b, c

			function system:LifeCycle(a1, b1, c1)
				a, b, c = a1, b1, c1
			end

			system:_InvokeLifecycleMethod("LifeCycle", 1, 2, 3)

			expect(a).to.equal(1)
			expect(b).to.equal(2)
			expect(c).to.equal(3)
		end)
	end)
end
