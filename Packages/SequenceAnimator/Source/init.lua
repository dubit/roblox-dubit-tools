--!strict

--[=[
	@class SequenceAnimator
]=]

type MoverInstance = Motor6D | BasePart

type SequencePose = {
	CFrame: CFrame,
	Motor6DName: string,
}

type SequenceKeyframe = {
	Time: number,
	Poses: { SequencePose },
}

type SequenceAnimation = {
	Length: number,
	Keyframes: { SequenceKeyframe },
}

type SequenceAnimatorInstanceData = {
	Model: Model,
	RegisteredAnimations: { [string]: SequenceAnimation },
}

local SequenceAnimator = {}
SequenceAnimator.instance = {}
SequenceAnimator.instanceData = {} :: { [any]: SequenceAnimatorInstanceData }
SequenceAnimator.private = {}
SequenceAnimator.public = {}

function SequenceAnimator.private.CreateSequenceKeyframe(keyframe: Keyframe): SequenceKeyframe
	local poses: { SequencePose } = {}

	for _, pose: Instance in keyframe:GetDescendants() do
		if not pose:IsA("Pose") then
			continue
		end

		table.insert(poses, {
			CFrame = pose.CFrame,
			Motor6DName = pose.Name,
		})
	end

	return {
		Time = keyframe.Time,
		Poses = poses,
	}
end

function SequenceAnimator.private.CreateSequenceAnimation(keyframeSequence: KeyframeSequence): SequenceAnimation
	local keyframes: { SequenceKeyframe } = {}
	local animationLength: number = 0

	for _, keyframe: Instance in keyframeSequence:GetChildren() do
		if not keyframe:IsA("Keyframe") then
			continue
		end

		local sequenceKeyframe = SequenceAnimator.private.CreateSequenceKeyframe(keyframe)
		if sequenceKeyframe.Time > animationLength then
			animationLength = sequenceKeyframe.Time
		end

		table.insert(keyframes, table.freeze(sequenceKeyframe))
	end

	table.sort(keyframes, function(keyframeA: SequenceKeyframe, keyframeB: SequenceKeyframe)
		return keyframeA.Time < keyframeB.Time
	end)

	return {
		Length = animationLength,
		Keyframes = keyframes,
	}
end

function SequenceAnimator.private.PoseModel(movers: { [string]: MoverInstance }, poses: { SequencePose })
	for _, pose in poses do
		local mover: MoverInstance? = movers[pose.Motor6DName]

		if not mover then
			continue
		end

		-- TODO: We need to figure out a good way to handle parts as KeyframeSequences can also animate parts that don't have Motor6Ds
		if mover:IsA("Motor6D") then
			mover.Transform = pose.CFrame
		end
	end
end

function SequenceAnimator.private.CollectMovers(
	model: Model,
	sequenceAnimation: SequenceAnimation
): { [string]: MoverInstance }
	local movers: { [string]: MoverInstance } = {}
	for _, pose: SequencePose in sequenceAnimation.Keyframes[1].Poses do
		local moverPart: Instance? = model:FindFirstChild(pose.Motor6DName)
		if not moverPart or not moverPart:IsA("BasePart") then
			continue
		end

		local childMotor6D: Motor6D? = moverPart:FindFirstChildOfClass("Motor6D")
		if childMotor6D then
			moverPart = childMotor6D
		end

		movers[pose.Motor6DName] = moverPart
	end

	return movers
end

--[=[
	@method AddKeyframeSequence
	@within SequenceAnimator

	Adds the KeyframeSeqence to the registry so it can be played with :PlaySequence()

	```lua
	local sequenceAnimator = SequenceAnimator.new(workspace.CoolModel)
	sequenceAnimator:AddKeyframeSequence("DancePose", ReplicatedStorage.Poses.DancePose)
	sequenceAnimator:PoseFromSequence("DancePose")
	```
]=]
function SequenceAnimator.instance.AddKeyframeSequence(self: any, name: string, keyframeSequence: KeyframeSequence)
	local instanceData = SequenceAnimator.instanceData[self]
	assert(instanceData, "Tried to perform an action on a destroyed SequenceAnimator instance!")
	assert(
		not instanceData.RegisteredAnimations[name],
		"Tried to register a KeyframeSequence with the same name more than once!"
	)

	instanceData.RegisteredAnimations[name] = SequenceAnimator.private.CreateSequenceAnimation(keyframeSequence)
end

--[=[
	@method Pose
	@within SequenceAnimator

	Aligns all the parts within a Model to form a Pose from name, throws an error if pose wasn't registered first.

	```lua
	local sequenceAnimator = SequenceAnimator.new(workspace.CoolModel)
	sequenceAnimator:AddKeyframeSequence("DancePose", ReplicatedStorage.Poses.DancePose)
	sequenceAnimator:PoseFromSequence("DancePose")
	```
]=]
function SequenceAnimator.instance.Pose(self: any, name: string, keyframeIndex: number?)
	local keyframe: number = keyframeIndex or 1
	local instanceData = SequenceAnimator.instanceData[self]
	assert(instanceData, "Tried to perform an action on a destroyed SequenceAnimator instance!")
	assert(not instanceData.RegisteredAnimations[name], `There is no KeyframeAnimation called '{name}'`)

	local sequenceAnimation: SequenceAnimation = instanceData.RegisteredAnimations[name]
	local movers: { [string]: MoverInstance } =
		SequenceAnimator.private.CollectMovers(instanceData.Model, sequenceAnimation)

	SequenceAnimator.private.PoseModel(movers, sequenceAnimation.Keyframes[keyframe].Poses)
end

--[=[
	@method Destroy
	@within SequenceAnimator

	Destroys the SequenceAnimator instance.
]=]
function SequenceAnimator.instance.Destroy(self: any)
	SequenceAnimator.instanceData[self] = nil
end

--[=[
	@method new
	@within SequenceAnimator

	@param model Model

	@return SequenceAnimator

	Just like there is Animator for Humanoids, we need to create SequenceAnimator, they have similarities but they are two different things.
]=]
function SequenceAnimator.public.new(model: Model)
	local self = setmetatable({}, {
		__index = SequenceAnimator.instance,
	})

	SequenceAnimator.instanceData[self] = {
		Model = model,
		RegisteredAnimations = {},
	}

	return self
end

--[=[
	@method poseModelFromKeyframe
	@within SequenceAnimator

	@param model Model
	@param keyframeSequence KeyframeSequence
	@param keyframeIndex number?

	Using this method there is no animator instance created, the Model gets pose applied from the KeyframeSequence,
	it is advised to use these when a pose needs to be applied once in a lifetime of a Model.
]=]
function SequenceAnimator.public.poseModelFromKeyframe(
	model: Model,
	keyframeSequence: KeyframeSequence,
	keyframeIndex: number?
)
	local keyframe: number = keyframeIndex or 1
	local sequenceAnimation: SequenceAnimation = SequenceAnimator.private.CreateSequenceAnimation(keyframeSequence)
	local movers: { [string]: MoverInstance } = SequenceAnimator.private.CollectMovers(model, sequenceAnimation)

	SequenceAnimator.private.PoseModel(movers, sequenceAnimation.Keyframes[keyframe].Poses)
end

return SequenceAnimator.public
