# API

## Properties

### BudgetConsumed
```luau { .fn_type }
AllocationPool.BudgetConsumed: Signal<string, number>
```

---

### BudgetFailed
```luau { .fn_type }
AllocationPool.BudgetFailed: Signal<string, string>
```

## Functions

### .ConsumePoolAsync
```luau { .fn_type }
AllocationPool.ConsumePoolAsync(player: Player?, poolName: string, size: number?): Promise
```

Consumes a pool allocation for a player. This function updates both the player's consumed pools list and the pool's consumption count. The operation is performed asynchronously and returns a promise that resolves when complete.

If a player is provided, it will mark the pool as consumed for that player before attempting to consume from the pool. The size parameter determines how many allocations to consume from the pool, defaulting to 1 if not specified.

!!! warning
	This promise can reject if the pool is already consumed by the player or if the pool has reached its limit.
	Implement error handling to handle these scenarios.

!!! danger ""
	This function will not error if the pool is already consumed by the player. You need to handle this scenario in your code.

```luau
AllocationPool.ConsumePoolAsync(player, poolName):andThen(function()
	awardUgc(player)
end):catch(function(err)
	warn(err)
end)

-- or in the event you'd like to consume a budget anonymously

AllocationPool.ConsumePoolAsync(nil, poolName):andThen(function()
	awardUgc(player)
end):catch(function(err)
	warn(err)
end)
```

---

### .CreatePoolAsync
```luau { .fn_type }
AllocationPool.CreatePoolAsync(poolName: string, poolLimit: number): ()
```

Creates a new allocation pool with the specified name and limit.

This function creates a new allocation pool in the datastore with the given name and maximum allocation limit. If a pool with the same name already exists, it will update the limit if different from the provided value.

```luau
AllocationPool.CreatePoolAsync("MyPool", 10):expect()
```

---

### .GetPoolCountAsync
```luau { .fn_type }
AllocationPool.GetPoolCountAsync(poolName: string): Promise
```

Returns the current consumption count for a specific pool.

This function retrieves the pool's data from the datastore and returns a promise that resolves with the number of allocations consumed from the pool.

```luau
local poolCount = AllocationPool.GetPoolCountAsync("MyPool"):expect()
```

---

### .GetPoolLimitAsync
```luau { .fn_type }
AllocationPool.GetPoolLimitAsync(poolName: string): Promise
```

Returns the pool's limit value from the datastore.

This function retrieves the pool's data and returns a promise that resolves with the maximum number of allocations allowed for the specified pool.

```luau
local poolLimit = AllocationPool.GetPoolLimitAsync("MyPool"):expect()
```

---

### .GetPoolReserveAsync
```luau { .fn_type }
AllocationPool.GetPoolReserveAsync(poolName: string): Promise
```

Returns the remaining allocations available in a pool.

This function retrieves the pool's data from the datastore and calculates the difference between the pool's limit and current consumption count. The result represents how many more allocations can be made from the pool.

```luau
local lastPoolValue = AllocationPool.GetPoolReserveAsync("PreviousPool"):expect()
local newPoolValue = AllocationPool.CreatePool("NewPool", DEFAULT_POOL_LIMIT + lastPoolValue):expect()
```

---

### .HasConsumedAsync
```luau { .fn_type }
AllocationPool.HasConsumedAsync(player: Player, poolName: string): Promise
```

Checks if a player has consumed a specific pool in the datastore.

This function queries the player's consumed pools list to determine if the specified pool name exists.

The operation is performed asynchronously and returns a promise that resolves with a boolean indicating consumption status.

```luau
local hasConsumed = AllocationPool.HasConsumedAsync(player, poolName):expect()
```

---

### .MarkConsumedAsync
```luau { .fn_type }
AllocationPool.MarkConsumedAsync(player: Player, poolName: string): Promise
```

Marks a pool as consumed for a player in the datastore.

This function updates the player's consumed pools list by adding the specified pool name. The operation is performed asynchronously and returns a promise that resolves when complete.

```luau
AllocationPool.MarkConsumedAsync(player, poolName):expect()
```

---

### .ResetPoolAsync
```luau { .fn_type }
AllocationPool.ResetPoolAsync(poolName: string): Promise
```

Resets a pool's consumption count back to zero.

This function updates the pool's consumption count in the datastore and returns a promise that resolves when complete.

This is useful for resetting pool allocations after a specific event or time period.

```luau
AllocationPool.ResetPoolAsync(player, poolName)
```

---

### .ResetConsumedAsync
```luau { .fn_type }
AllocationPool.ResetConsumedAsync(player: Player, poolName: string?): Promise
```

Will remove the users data from allocation pools datastore

If the second parameter 'PoolName' is given, this function will remove all references to the pool name given.
If the second parameter 'PoolName' is not given, this function will remove all pools from the users pools consumption.

```luau
AllocationPool.ResetConsumedAsync(player, poolName):expect()
```

---

### .UpdatePoolLimitAsync
```luau { .fn_type }
AllocationPool.UpdatePoolLimitAsync(poolName: string, poolLimit: number): ()
```

Updates the pool's limit value in the datastore.

This function updates the pool's maximum allocation limit in the datastore. The new limit will be applied immediately and affects future allocation attempts.

```luau
AllocationPool.UpdatePoolLimitAsync("MyPool", 10):expect()
```

---

### .Initialize
```luau { .fn_type }
AllocationPool.Initialize(): ()
```

Initializes the AllocationPool service and starts the pool synchronization loop.
	
This function sets up player cleanup and continuously updates pool consumption while managing budget limits.