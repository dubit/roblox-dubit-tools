---
sidebar_position: 2
---

# Roact

**QuiltRoact** package provides some methods to wrap some of **Quilt's** functionality so it's easier to work with it while creating interfaces with **Roact**, by using it you can escape updating Quilts interface size and position by hand, instead the library can do it on it's own.

It also injects automatically a `Visible` property to the top most component of your interface that changes with [Interface's Instance](/api/Interface) state.

To add it into your project add a **QuiltRoact** dependency into your project by adding the line below to your `wally.toml` file.

```lua
QuiltRoact = "dubit/quilt-roact@0.1.0"
```

:::caution
For **QuiltRoact** to work there also **<u>needs</u>** to be a [Quilt](/docs/Quilt/getting_started/) dependency added!
:::

## Handling interfaces
There are two ways to handle interfaces with **QuiltRoact**:
- Mounting and unmounting Roact interface when Quilt's interface status changes, it's a good way to hide and show interfaces **<u>if there is no animations</u>** when interface is hidden or shown, unmounting the interface means there is no leftover Roblox instances created when the interface is not visible.
Example implementation: [Wrapper Method](/docs/Quilt/getting_started/roact/wrapper/)
:::info
There can be animation added when the interface is changing it's state from `hidden / overlapped` to `visible` as we can utilize **Roact's** method `didMount` to initiate the animation.
:::
*This is the most recommended method of using **Quilt** with **Roact** for beginners or simple interfaces.*

- Handling the visibility ourselves using the `Visible` property that **QuiltRoact** injects into the component when given component is wrapped within `QuiltRoact.ScreenGui`, this approach most importantly allows us to define our own animations to when the interface is hidden away, or not hide interface at all when that property changes. (For example; we might wanna make the interface little bit more transparent if the interface is not visible, not hide it away completely, maybe we just want to have an interface which lifecycle shouldn't be interrupted because of the visibility change - this can be used for that too)
Example implementation: [By Hand Method](/docs/Quilt/getting_started/roact/by_hand/)

## Which element should be the reference?

Choosing a reference element for the interface might be confusing when first starting with Quilt, but it's not that hard! Try to imagine which elements defines the bounding box of you interface the best.

### First example
![image](/quilt/ref_examples/center_example.png)

In this example an interface is made with 2 top most elements:
![small-center](/quilt/ref_examples/center_example_explorer.png)

As you can see there is a big dark blue element in the background serving as a parent so the square fills the screen from top to bottom, and then there is a frame with lighter shade of blue which is our *main* part of the interface, this is the element that should have a **QuiltRoact** reference. (***Second Frame***)

### Second example
![image](/quilt/ref_examples/multiple_example.png)

In this example an interface is made with 2 top most elements:
![small-center](/quilt/ref_examples/multiple_example_explorer.png)

As you can see there is a big dark blue element in the background serving as a parent so the square fills the screen from top to bottom, and then there is a frame with lighter shade of blue which is our *main* part of the interface, this is the element that should have a **QuiltRoact** reference. (***Second Frame***)


### Third example
![image](/quilt/ref_examples/leaderboard_example.png)

In this example an interface is made with just one element:
![small-center](/quilt/ref_examples/leaderboard_example_explorer.png)

As you can see there is just one element affecting the final position and size of the *main* element of the interface, this is the element that should have a **QuiltRoact** reference. (***Frame***)