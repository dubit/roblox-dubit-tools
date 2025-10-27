return function()
	local TaskQueueObject = require(script.Parent)

	describe("'TaskQueueObject' should execute given tasks when cycled", function()
		local queueObject

		beforeAll(function()
			queueObject = TaskQueueObject.new(0)
		end)

		it("Queue should execute 1st function when cycled", function()
			local variable = false

			queueObject:AddTask(function()
				variable = true
			end)

			queueObject:Cycle()

			expect(variable).to.equal(true)
		end)

		it("Queue should execute a series of tasks in order", function()
			local tasks = {}

			for index = 1, 5 do
				queueObject:AddTask(function()
					table.insert(tasks, index)
				end)

				queueObject:Cycle()
			end

			expect(#tasks).to.equal(5)

			expect(tasks[1]).to.equal(1)
			expect(tasks[2]).to.equal(2)
			expect(tasks[3]).to.equal(3)
			expect(tasks[4]).to.equal(4)
			expect(tasks[5]).to.equal(5)
		end)

		it("Queue should be able to recycle function", function()
			local cycled = false
			local cycleIndex = 0

			local function test()
				cycleIndex += 1

				queueObject:AddTask(test)

				if not cycled then
					cycled = true

					queueObject:Cycle()
				end
			end

			queueObject:AddTask(test)
			queueObject:Cycle()

			expect(cycled).to.equal(true)
			expect(cycleIndex).to.equal(2)
		end)
	end)
end
