return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Notifications = require(ReplicatedStorage.Packages.Notifications)

	local testIds = table.freeze({
		Notification1 = "Notification1",
		Notification2 = "Notification2",
		Notification3 = "Notification3",
	})

	it("Should show and hide notifications in order of request using callbacks.", function()
		local visibility = {
			[testIds.Notification1] = false,
			[testIds.Notification2] = false,
		}

		Notifications:Show(testIds.Notification1, { duration = 1 }, nil, function()
			visibility.Notification1 = true
		end, function()
			visibility.Notification1 = false
		end)

		Notifications:Show(testIds.Notification2, { duration = 1 }, nil, function()
			visibility.Notification2 = true
		end, function()
			visibility.Notification2 = false
		end)

		task.wait(0.5)

		expect(visibility.Notification1).to.equal(true)
		expect(visibility.Notification2).to.equal(false)

		task.wait(1)

		expect(visibility.Notification1).to.equal(false)
		expect(visibility.Notification2).to.equal(true)

		task.wait(1)

		expect(visibility.Notification1).to.equal(false)
		expect(visibility.Notification2).to.equal(false)
	end)

	it("Should show and hide notifications in order of request using Signals.", function()
		local visibility = {
			[testIds.Notification1] = false,
			[testIds.Notification2] = false,
		}

		Notifications.Shown:Connect(function(id)
			visibility[id] = true
		end)

		Notifications.Hidden:Connect(function(id)
			visibility[id] = false
		end)

		Notifications:Show(testIds.Notification1, { duration = 1 })
		Notifications:Show(testIds.Notification2, { duration = 1 })

		task.wait(0.5)

		expect(visibility.Notification1).to.equal(true)
		expect(visibility.Notification2).to.equal(false)

		task.wait(1)

		expect(visibility.Notification1).to.equal(false)
		expect(visibility.Notification2).to.equal(true)

		task.wait(1)

		expect(visibility.Notification1).to.equal(false)
		expect(visibility.Notification2).to.equal(false)
	end)

	it("Should cancel a notification successfully.", function()
		local visibility = {
			[testIds.Notification1] = false,
			[testIds.Notification2] = false,
		}

		Notifications:Show(testIds.Notification1, { duration = 1 }, nil, function()
			visibility.Notification1 = true
		end)

		Notifications:Show(testIds.Notification2, { duration = 1, canCancel = true }, nil, function()
			visibility.Notification2 = true
		end)

		task.wait(0.5)

		local cancelled = Notifications:Cancel(testIds.Notification2)

		task.wait(2)

		expect(cancelled).to.equal(true)
		expect(visibility.Notification2).to.equal(false)
	end)

	it("Should pause and resume notifications", function()
		local visibility = {
			[testIds.Notification1] = false,
			[testIds.Notification2] = false,
		}

		Notifications:Show(testIds.Notification1, { duration = 1 }, nil, function()
			visibility.Notification1 = true
		end, function()
			visibility.Notification1 = false
		end)

		Notifications:Show(testIds.Notification2, { duration = 1 }, nil, function()
			visibility.Notification2 = true
		end, function()
			visibility.Notification2 = false
		end)

		task.wait(0.5)

		Notifications:PauseQueue()

		task.wait(1)

		expect(visibility.Notification1).to.equal(false)
		expect(visibility.Notification2).to.equal(false)

		Notifications:ResumeQueue()

		task.wait(0.5)

		expect(visibility.Notification1).to.equal(false)
		expect(visibility.Notification2).to.equal(true)

		task.wait(1)

		expect(visibility.Notification1).to.equal(false)
		expect(visibility.Notification2).to.equal(false)
	end)
end
