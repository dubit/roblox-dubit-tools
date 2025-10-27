return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local DubitStore = require(ReplicatedStorage.Packages.DubitStore)

	describe("datastore autosaving system should function as expected", function()
		it("should invoke the connected function", function()
			local invoked = false

			DubitStore:OnAutosave("Example"):Once(function()
				invoked = true
			end)

			expect(invoked).to.equal(false)

			DubitStore:InvokeAutosave("Example")

			expect(invoked).to.equal(true)
		end)

		it("should invoke the yielding function", function()
			local invoked = false

			task.spawn(function()
				DubitStore:OnAutosave("Example"):Wait()

				invoked = true
			end)

			expect(invoked).to.equal(false)

			DubitStore:InvokeAutosave("Example")

			expect(invoked).to.equal(true)
		end)

		it("should invoke all connected functions", function()
			local tasks = {}

			for index = 1, 5 do
				DubitStore:OnAutosave("Example"):Once(function()
					table.insert(tasks, index)
				end)
			end

			expect(#tasks).to.equal(0)

			DubitStore:InvokeAutosave("Example")

			expect(#tasks).to.equal(5)
		end)
	end)
end
