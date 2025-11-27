# Overview

SequenceAnimator is a package that implements a custom animation system for Roblox Models using KeyframeSequence objects as the source of animation data.

It parses keyframe data which it uses to later update Motor6Ds and Bones on every frame to animate the model, it is used in places where Roblox Animations cannot be used, for ex. sharing animations across multiple experiences without making them publicly accessible.

The goal of this package is to be **similar** to how Robloxes Animator functions, however it's not mature enough yet to have 1:1 feature parity, its feature set could expand over time as it is used in more projects and more complex scenarios.

## Adding Sequence Animator to a Project

To add the SequenceAnimator package to your project, add the following to your wally.toml file:

```toml
[dependencies]
SequenceAnimator = "dubit/sequence-animator@^0"
```

## Examples

```luau
local animator = SequenceAnimator.new(drill)

local startTrack = animator:LoadSequence(drillStartKeyframeSequence)
startTrack.Looped = false

local idleTrack = animator:LoadSequence(drillAnimationSource.Idle)

startTrack.Ended:Once(function()
	idleTrack:Play()
end)
```
