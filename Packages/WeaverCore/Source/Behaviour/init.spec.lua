return function()
	local Behaviour = require(script.Parent)

	it("Should be able to generate a new Behaviour object", function()
		expect(Behaviour.new({ Tag = "abc" })).to.be.ok()
	end)

	it("Should throw when passing an invalid tag/source object", function()
		expect(function()
			Behaviour.new({})
		end).to.throw()

		expect(function()
			Behaviour.new()
		end).to.throw()
	end)

	it("Should be able to identify behaviour instances", function()
		local behaviour = Behaviour.new({ Tag = "abc" })

		expect(Behaviour.is(behaviour)).to.equal(true)
	end)

	describe("Behaviour tags & fetching", function()
		it("should be able to fetch behaviour objects", function()
			local behaviour = Behaviour.new({ Tag = "abc" })
			local index = table.find(Behaviour.fetch("abc"), behaviour)

			expect(index).to.be.ok()
		end)

		it("should be able to fetch the tags of all behaviour objects", function()
			Behaviour.new({ Tag = "abc" })

			expect(#Behaviour.fetchTags()).to.equal(1)
		end)
	end)

	describe("Behaviour lifecycles", function()
		it("should be able to execute behaviour lifecycle methods", function()
			local behaviour = Behaviour.new({ Tag = "abc" })
			local flag = false

			function behaviour:LifeCycle()
				flag = true
			end

			behaviour:_InvokeLifecycleMethod("LifeCycle")

			expect(flag).to.equal(true)
		end)

		it("Should be able to manipulate varadic arguments", function()
			local behaviour = Behaviour.new({ Tag = "abc" })
			local a, b, c

			function behaviour:LifeCycle(a1, b1, c1)
				a, b, c = a1, b1, c1
			end

			behaviour:_InvokeLifecycleMethod("LifeCycle", 1, 2, 3)

			expect(a).to.equal(1)
			expect(b).to.equal(2)
			expect(c).to.equal(3)
		end)
	end)
end
