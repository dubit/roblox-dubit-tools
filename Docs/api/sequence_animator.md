# API

## SequenceAnimator

### Functions

#### .new
```luau { .fn_type }
SequenceAnimator.new(model: Model): SequenceAnimatorInstance
```

Creates a new SequenceAnimatorInstance allowing for playing KeyframeSequences on a given Model.

## SequenceAnimatorInstance

### Functions

#### :LoadSequence
```luau { .fn_type }
SequenceAnimatorInstance:LoadSequence(sequence: KeyframeSequence): SequenceTrack
```

This function loads the given KeyframeSequence onto this SequenceAnimatorInstance, returning a playable SequenceTrack.

---

#### :Destroy
```luau { .fn_type }
SequenceAnimatorInstance:Destroy(): ()
```

## SequenceTrack

### Properties

#### Speed
```luau { .fn_type }
SequenceTrack.Speed: number
```

When equal to **1**, the amount of time an animation takes to complete is equal to **[Length](#length)**, in seconds.

Changing this property while animation is being played won't result in it speeding up / slowing down, instead next time **[Play](#play)** is called the new speed will be applied.

---

#### Length
```luau { .fn_type }
SequenceTrack.Length: number
```

Length in seconds.

!!! warning
	This property can be modified, but you shouldn't really have a reason to do so.

---

#### IsPlaying
```luau { .fn_type }
SequenceTrack.IsPlaying: boolean
```

Returns true when SequenceTrack is playing an animation.

---

#### Looped
```luau { .fn_type }
SequenceTrack.Looped: boolean
```

This property sets whether the animation will repeat after finishing.

Changing this property while animation is being played won't result in it looping once it reaches the end, instead next time **[Play](#play)** is called the new change will be applied.

---

#### Ended
```luau { .fn_type }
SequenceTrack.Ended: RBXScriptSignal
```

Fires when the SequenceTrack is completely done moving anything in the world, meaning the animation has finished playing.

---

#### DidLoop
```luau { .fn_type }
SequenceTrack.DidLoop: RBXScriptSignal
```

This event fires whenever a looped SequenceTrack completes a loop.

### Functions

#### :Play
```luau { .fn_type }
SequenceTrack:Play(): ()
```

When called the animation will start playing.

!!! notice
	Currently SequenceAnimator doesn't support fadeTime and weight unlike Robloxes AnimationTrack.

---

#### :Stop
```luau { .fn_type }
SequenceTrack:Stop(): ()
```

Stops the current animation, if one is playing. Stopping an animation will not cause the pose to reset to its default state.

!!! notice
	Currently SequenceAnimator doesn't support fadeTime and weight unlike Robloxes AnimationTrack.