local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BUDGET_NAME = "BudgetTest1"

local AllocationPool = require(ReplicatedStorage.Packages.AllocationPool)

local player = game.Players:WaitForChild("AsynchronousMatrix")

AllocationPool.CreatePoolAsync(BUDGET_NAME, 1000):await()

local status, resolve = AllocationPool.ConsumePoolAsync(player, BUDGET_NAME, nil):await()

warn("Consumed:", 1, "from", BUDGET_NAME, "response:", status, resolve)

print(AllocationPool.HasConsumedAsync(player, BUDGET_NAME):expect())

print("Reset:", AllocationPool.ResetConsumedAsync(player, BUDGET_NAME):expect())

print(AllocationPool.HasConsumedAsync(player, BUDGET_NAME):expect())

-- AllocationPool.ResetPoolAsync(BUDGET_NAME):await()
