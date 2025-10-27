-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local Packages = ReplicatedStorage:WaitForChild("Packages")

-- local Notifications = require(Packages.Notifications)

-- local testNotificationIds = table.freeze({
-- 	WelcomePopup = "WelcomePopup",
-- 	GoodbyePopup = "GoodbyePopup",
-- 	InterruptingPopup = "InterruptingPopup",
-- })

-- Notifications.Shown:Connect(function(id: string, metadata: any)
-- 	print(`Notification {id} started with data {metadata} from a Signal.`)
-- end)

-- Notifications.Hidden:Connect(function(id: string, metadata: any)
-- 	print(`Notification {id} completed with data {metadata} from a Signal.`)
-- end)

-- Notifications:Show(testNotificationIds.WelcomePopup, { duration = 4 }, { message = "This is a welcome popup" })
-- Notifications:Show(testNotificationIds.GoodbyePopup, { duration = 4 }, { message = "This is a goodbye popup" })

-- Notifications:ShowNext(
-- 	testNotificationIds.InterruptingPopup,
-- 	{ duration = 4 },
-- 	{ message = "This is an interrupting popup" },
-- 	function(_, metadata)
-- 		print(`Interrupting popup started with data {metadata} from a callback.`)
-- 	end,
-- 	function(_, metadata)
-- 		print(`Interrupting popup completed with data {metadata} from a callback.`)
-- 	end
-- )
