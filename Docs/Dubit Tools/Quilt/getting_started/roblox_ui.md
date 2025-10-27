---
sidebar_position: 1
---

# Roblox UI

Quilt can be used also without any external UI libraries, although without that you will miss out on some of the thigns that are handled automatically for you, when choosing this approach you need to update the interface data about position and size yourself.

## Handling interfaces

With this approach you need to synchronize all of the changes that happen to Roblox instance of an interface to Quilt's Interface instance, there are 2 methods exposed to do so:

```lua
QuiltInterface:SetPosition(position: UDim2)
QuiltInterface:SetSize(size: UDim2)
```

:::caution
Change in position or size means that recalculation needs to happen within Quilt to calculate new overlaps.
:::

## Handling state change

It's up to you how you handle the state change, one way to go about it would be to listen to StatusChanged on Interface instance and reflect that change showing or hiding the UI Instance

```lua
local interfaceFrame: Frame = ... -- some code defining interfaceFrame

quiltInterface.StatusChanged:Connect(function(newStatus: string)
	-- Logic based on newStatus
	interfaceFrame.Visible = newStatus == "Visible"
end)
```