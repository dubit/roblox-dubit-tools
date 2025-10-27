---
sidebar_position: 2
---

# By Hand

## Creating Quilt Interface Instance

To create an interface that is controller by Quilt we first need to create an [Interface Instance](/api/Interface):

```lua
-- [Imports omitted for clarity]

local quiltInterface = Quilt.Interface.new("Quilt Interface")
```

*Optionally we can define [Priority](/) or [Feature Flags](/).*

## Hooking up Roact Component

Now that we have our [Interface Instance](/api/Interface) created, we can move to wrapping our **Roact** component within a **QuiltRoact** ScreenGui component which will give us full benefits of the library.

```lua
-- [Imports omitted for clarity]

Roact.createElement(
	QuiltRoact.ScreenGui(
		{ ResetOnSpawn = false, IgnoreGuiInset = true },
		quiltInterface,
		MyRoactComponent,
	)
)
```
:::info
If you want to understand which argument correspond to what, take a look at the API documentation about [QuiltRoact.ScreenGui](/)
:::
:::warning
This tutorial expects you understanding how Roact and it's components function, the above **MyRoactComponent** is <u>imaginary</u> in this case and it should be imported and defined before creating QuiltRoact.ScreenGui Roact element.
:::

Doing so you also need to define a reference to an Instance which will define bounding box and position of your interface as well as automatically update it for you. Choosing appropriate reference element depends on use case scenario for the interface, if you struggle choosing which Instance should be used as a reference, look at [Roact](/docs/Quilt/getting_started/roact/#which-element-should-be-the-reference) tutorial for Quilt.

Example reference in a Roact component:
```lua
-- [Any extra code omitted for clarity]

function RoactComponent:render()
	return Roact.createElement("Frame", {
		AnchorPoint = Vector2.new(0.50, 1.00),
		Position = UDim2.fromScale(0.50, 0.92),
		Size = UDim2.fromScale(0.20, 1.00),

		BackgroundTransparency = 1.00,

		[Roact.Ref] = self.props[QuiltRoact.InterfaceRef],
	})
end
```

## Handling state change

Within this approach the interface is mounted all the time, we can controll the visibility of the interface within the top most component of our interface which has `Visible` as one of it's properties, depending on which you can just switch `Visible` property on one of the interface element or trigger an animation.

*Example code for an animation based approach:*
```lua
-- [Any extra code omitted for clarity]

function RoactComponent:didUpdate(previousProps: any)
	if self.props.Visible ~= previousProps.Visible then
		-- The `Visible` property changed, so you can
		-- trigger an animation / change state of your component
	end
end
```
---

*Example code for property change approach:*
```lua
-- [Any extra code omitted for clarity]

function RoactComponent:render()
	return Roact.createElement("Frame", {
		AnchorPoint = Vector2.new(0.50, 1.00),
		Position = UDim2.fromScale(0.50, 0.92),
		Size = UDim2.fromScale(0.20, 1.00),

		BackgroundTransparency = 1.00,

		Visible = self.props.Visible,

		[Roact.Ref] = self.props[QuiltRoact.InterfaceRef],
	})
end
```