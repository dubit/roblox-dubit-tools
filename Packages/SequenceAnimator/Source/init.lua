local RunService = game:GetService("RunService")

export type SequenceTrack = {
	Speed: number,
	Length: number,

	IsPlaying: boolean,
	Looped: boolean,

	Ended: RBXScriptSignal,
	DidLoop: RBXScriptSignal,

	Play: (self: SequenceTrack) -> (),
	Stop: (self: SequenceTrack) -> (),
}

export type SequenceAnimator = {
	LoadSequence: (self: SequenceAnimator, sequence: KeyframeSequence) -> SequenceTrack,

	Destroy: (self: SequenceAnimator) -> (),
}

type SequenceTrackData = {
	Keyframes: { SequenceKeyframe },
	KeyframesCount: number,

	EndedBindable: BindableEvent,
	DidLoopBindable: BindableEvent,

	PreRenderConnection: RBXScriptConnection?,
}

type SequenceAnimatorData = {
	Model: Model,

	Movers: { [string]: Motor6D | Bone },

	SequenceData: { [SequenceTrack]: SequenceTrackData },

	DescendantAddedConnection: RBXScriptConnection,
	AncestryChangedConnection: RBXScriptConnection,
}

type SequencePose = {
	CFrame: CFrame,
}

type SequenceKeyframe = {
	Time: number,
	Poses: { [string]: SequencePose },
}

local animatorFromTrackLookup: { [SequenceTrack]: SequenceAnimator } = {}
local animatorData: { [SequenceAnimator]: SequenceAnimatorData } = {}

local function checkAndRegisterMover(sequenceAnimator: SequenceAnimator, instance: Instance)
	if instance:IsA("Motor6D") or instance:IsA("Bone") then
		local data = animatorData[sequenceAnimator]
		if not data then
			return
		end

		local filteredMotor6D = string.gsub(instance.Name, "Motor6D", "")

		data.Movers[instance.Name] = instance

		if filteredMotor6D ~= instance.Name then
			data.Movers[filteredMotor6D] = instance
		end
	end
end

function sequenceTrackPlay(sequenceTrack: SequenceTrack)
	local sequenceAnimator = animatorFromTrackLookup[sequenceTrack]

	local data = animatorData[sequenceAnimator]
	local trackData = data.SequenceData[sequenceTrack]

	if trackData.PreRenderConnection then -- already playing
		return
	end

	local keyframes = trackData.Keyframes

	local looped = sequenceTrack.Looped
	local speed = sequenceTrack.Speed

	local animationT = 0.00
	local currentIndex = 1
	trackData.PreRenderConnection = RunService.PreRender:Connect(function(deltaTime)
		if animationT >= sequenceTrack.Length then
			if looped then
				animationT = 0.00
				currentIndex = 1

				trackData.DidLoopBindable:Fire()
			else
				trackData.PreRenderConnection:Disconnect()
				trackData.PreRenderConnection = nil

				trackData.EndedBindable:Fire()
				return
			end
		end

		while animationT >= keyframes[currentIndex + 1].Time do
			currentIndex += 1
		end

		local currentPose = keyframes[currentIndex]
		local nextPose = keyframes[math.min(trackData.KeyframesCount, currentIndex + 1)]

		local poseT = 1 - (nextPose.Time - animationT) * (1 / (nextPose.Time - currentPose.Time))

		local modelScale = data.Model:GetScale()

		for moverName, pose in currentPose.Poses do
			local mover = data.Movers[moverName]

			if not mover then
				continue
			end

			local transformCFrame = pose.CFrame:Lerp(nextPose.Poses[moverName].CFrame, poseT)
			local transformRotation = transformCFrame - transformCFrame.Position

			mover.Transform = CFrame.new(transformCFrame.Position * modelScale) * transformRotation
		end

		animationT += deltaTime * speed
	end)

	sequenceTrack.IsPlaying = true
end

function sequenceTrackStop(sequenceTrack: SequenceTrack)
	local sequenceAnimator = animatorFromTrackLookup[sequenceTrack]

	local data = animatorData[sequenceAnimator]
	local trackData = data.SequenceData[sequenceTrack]

	sequenceTrack.IsPlaying = false

	if trackData.PreRenderConnection then
		trackData.PreRenderConnection:Disconnect()
		trackData.PreRenderConnection = nil
	end
end

function sequenceAnimatorLoadKeyframeSequence(self: SequenceAnimator, sequence: KeyframeSequence)
	local sequenceAnimatorData = animatorData[self]

	local keyframes = {}
	local animationLength = 0

	for _, keyframe in sequence:GetChildren() do
		if not keyframe:IsA("Keyframe") then
			continue
		end

		local poses = {}

		for _, pose in keyframe:GetDescendants() do
			if not pose:IsA("Pose") then
				continue
			end

			poses[pose.Name] = {
				CFrame = pose.CFrame,
			}
		end

		if keyframe.Time > animationLength then
			animationLength = keyframe.Time
		end

		table.insert(
			keyframes,
			table.freeze({
				Time = keyframe.Time,
				Poses = table.freeze(poses),
			})
		)
	end

	table.sort(keyframes, function(keyframeA, keyframeB)
		return keyframeA.Time < keyframeB.Time
	end)

	local keyframeCount = #keyframes

	local sequenceTrack = {
		Speed = 1,
		Length = animationLength,

		IsPlaying = false,
		Looped = sequence.Loop,
	}

	local endedBindable = Instance.new("BindableEvent")
	endedBindable.Parent = script

	local didLoopBindable = Instance.new("BindableEvent")
	didLoopBindable.Parent = script

	sequenceTrack.Ended = endedBindable.Event
	sequenceTrack.DidLoop = didLoopBindable.Event

	sequenceTrack.Play = function(sequenceTrack_: SequenceTrack)
		assert(sequenceTrack == sequenceTrack_, "Expected ':' not '.' calling member function Play")

		sequenceTrackPlay(sequenceTrack_)
	end

	sequenceTrack.Stop = function(sequenceTrack_: SequenceTrack)
		assert(sequenceTrack == sequenceTrack_, "Expected ':' not '.' calling member function Stop")

		sequenceTrackStop(sequenceTrack_)
	end

	animatorFromTrackLookup[sequenceTrack] = self
	sequenceAnimatorData.SequenceData[sequenceTrack] = {
		Keyframes = keyframes,
		KeyframesCount = keyframeCount,

		EndedBindable = endedBindable,
		DidLoopBindable = didLoopBindable,
	}

	return sequenceTrack
end

function sequenceAnimatorDestroy(sequenceAnimator: SequenceAnimator)
	local data = animatorData[sequenceAnimator]
	animatorData[sequenceAnimator] = nil

	if not data then
		return
	end

	data.DescendantAddedConnection:Disconnect()
	data.AncestryChangedConnection:Disconnect()

	for _, trackData in data.SequenceData do
		if trackData.PreRenderConnection then
			trackData.PreRenderConnection:Disconnect()
		end

		trackData.DidLoopBindable:Destroy()
		trackData.EndedBindable:Destroy()
	end
end

local SequenceAnimator = {}

function SequenceAnimator.new(model: Model)
	local sequenceAnimator = {}

	sequenceAnimator.LoadSequence = function(self: SequenceAnimator, sequence: KeyframeSequence)
		assert(self == sequenceAnimator, "Expected ':' not '.' calling member function LoadSequence")
		assert(
			sequence and typeof(sequence) == "Instance" and sequence:IsA("KeyframeSequence"),
			"LoadSequence requires a KeyframeSequence Instance"
		)

		return sequenceAnimatorLoadKeyframeSequence(self, sequence)
	end

	sequenceAnimator.Destroy = function(self)
		assert(self == sequenceAnimator, "Expected ':' not '.' calling member function Destroy")

		sequenceAnimatorDestroy(sequenceAnimator)
	end

	local sequenceAnimatorData = {
		Model = model,

		Movers = {},

		SequenceData = {},
	}

	animatorData[sequenceAnimator] = sequenceAnimatorData :: SequenceAnimatorData

	sequenceAnimatorData.DescendantAddedConnection = model.DescendantAdded:Connect(function(instance: Instance)
		checkAndRegisterMover(sequenceAnimator, instance)
	end)
	for _, descendant in model:GetDescendants() do
		checkAndRegisterMover(sequenceAnimator, descendant)
	end

	sequenceAnimatorData.AncestryChangedConnection = model.AncestryChanged:Connect(function()
		if model.Parent ~= nil then
			return
		end

		sequenceAnimatorDestroy(sequenceAnimator)
	end)

	return table.freeze(sequenceAnimator)
end

return SequenceAnimator
