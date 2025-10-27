local DefaultLifeCycleMethods = {
	Construct = "Construct",
	Start = "Start",
	Stop = "Stop",
	HeartbeatUpdate = "HeartbeatUpdate",
	SteppedUpdate = "SteppedUpdate",
	RenderSteppedUpdate = "RenderSteppedUpdate",
}

export type DefaultLifeCycleMethods = typeof(DefaultLifeCycleMethods)

return DefaultLifeCycleMethods
