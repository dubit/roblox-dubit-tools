return function()
	local Middleware = require(script.Parent)

	it("should be able to generate a middelware object", function()
		local function test() end

		local object = Middleware.new(test)

		expect(object).to.be.ok()
		expect(object._callback).to.equal(test)
	end)

	it("should be able to process a call request", function()
		local flag = false

		local object = Middleware.new(function()
			flag = true
		end)

		expect(flag).to.equal(false)
		object:Call()
		expect(flag).to.equal(true)
	end)

	it("should be able to process a call request with parameters", function()
		local flag = false

		local object = Middleware.new(function(value)
			flag = value
		end)

		expect(flag).to.equal(false)
		object:Call(1)
		expect(flag).to.equal(1)
	end)

	it("should be able to validate a middleware object", function()
		local object = Middleware.new(function() end)

		expect(Middleware.is(object)).to.equal(true)
	end)

	it("should be able to return the name of the middleware object", function()
		local object = Middleware.new(function() end)

		expect(object:ToString()).to.be.ok()
	end)
end
