# Getting Started

You can add the AllocationPool library to your project by adding the following into your `wally.toml` file.

```lua
[place]
shared-packages = "game.ReplicatedStorage.Packages"

[server-dependencies]
AllocationPool = "dubit/allocation-pool@^0"
```

## What is the Allocation Pool package?

The goal for this package is to provide developers with an easy way to create globally synced budgets. A budget in this scenario represents an array of items that can be consumed - and we want to make sure only X items are consumed, nothing more.

The allocation pool offers the following features;

- Consuming Global Budgets
- Manipulating Global Budgets
- Counting how many items are left in a budget

### Examples

The below example details how to create a pool with a limit:

```lua
local AllocationPool = require(path.to.module)

-- Create a pool named "MyPool" with a limit of 100 allocations
AllocationPool.CreatePoolAsync("MyPool", 100):expect()
```

The below example shows how to consume from a pool and award an item:

```lua
local AllocationPool = require(path.to.module)

-- Consume 1 allocation from "MyPool" for the given player
AllocationPool.ConsumePoolAsync(player, "MyPool")
	:andThen(function()
		-- Pool was successfully consumed, award the item
		self:AwardPlayerUGCAsync(player, "ugcId"):await()
	end)
	:catch(function(err)
		warn("Failed to award item to " .. player.Name .. " - " .. err)
	end)

-- You can also consume anonymously without tracking per-player
AllocationPool.ConsumePoolAsync(nil, "MyPool")
	:andThen(function()
		-- Pool was successfully consumed
		self:AwardPlayerUGCAsync(player, "ugcId"):await()
	end)
	:catch(function(err)
		warn("Failed to award item - " .. err) 
	end)
```

Other useful functions:

```lua
-- Get remaining allocations in a pool
local remaining = AllocationPool.GetPoolReserveAsync("MyPool"):expect()

-- Get total consumed allocations
local consumed = AllocationPool.GetPoolCountAsync("MyPool"):expect()

-- Check if a player has consumed from a pool
local hasConsumed = AllocationPool.HasConsumedAsync(player, "MyPool"):expect()

-- Reset a pool's consumption back to 0
AllocationPool.ResetPoolAsync("MyPool"):expect()

-- Update a pool's limit
AllocationPool.UpdatePoolLimitAsync("MyPool", 200):expect()
```

#### Practical Example

Below is an example of how you'd use the allocation pool to award players 10 items per day.

```lua
local AllocationPool = require(path.to.AllocationPool)

-- Create a pool for today with a limit of 10 items
local function getDailyPoolName(offset)
	local date = os.date("*t", os.time() - (offset or 0) * 86400)
	return string.format("DailyPool_%d_%d_%d", date.year, date.month, date.day)
end

-- When server starts, create/ensure today's pool exists
local function initializeDailyPool()
	local yesterdayPool = getDailyPoolName(1)
	local todayPool = getDailyPoolName()

	return AllocationPool.GetPoolReserveAsync(yesterdayPool)
		:andThen(function(remainingFromYesterday)
			return AllocationPool.CreatePoolAsync(todayPool, 10 + remainingFromYesterday)
		end)
		:catch(function()
			-- If yesterday's pool doesn't exist, just create with base limit
			return AllocationPool.CreatePoolAsync(todayPool, 10)
		end)
end

-- Function to try award an item to a player
local function tryAwardDailyItem(player)
	local poolName = getDailyPoolName()
	
	-- Check if player already received their daily item
	return Promise.new(function(resolve, reject)
		AllocationPool.HasConsumedAsync(player, poolName)
			:andThen(function(hasConsumed)
				if hasConsumed then
					return reject("Already claimed today's item")
				end
				
				-- Try to consume from today's pool
				return AllocationPool.ConsumePoolAsync(player, poolName)
					:andThen(function()
						resolve()
					end)
					:catch(reject)
			end)
			:catch(reject)
	end)
end
```