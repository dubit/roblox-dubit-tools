# Simple Store

DubitStore is a mammoth of a library, which means it's got quite a steep learning curve and most 
developers won't be able to pick it up at a glance, and because of that - we need a library that
provides an easy to interact with interface that can be scaleable and used
alongside dubitstore if required.

## Programming Examples

```lua
local SimpleStore = require(path.to.SimpleStore)

local Store = SimpleStore:Get("player_data")

Store:Set(player, {})
Store:SetKey(player, "abc", 123)

Store:Get(player)
Store:GetKey(player, "abc")

Store:Merge(player, { abc = 123 })
Store:MergeKey(player, "def", { abc = 123 })

Store:Update(player, function(oldValue)
	return {}
end)

Store:UpdateKey(player, "abc", function(oldValue)
	return {}
end)

Store:Save()
```