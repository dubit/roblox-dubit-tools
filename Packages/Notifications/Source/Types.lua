export type Notifications = {
	Shown: Signal<string, any>,
	Hidden: Signal<string, any>,

	SetDelay: (self: Notifications, delay: number) -> (),
	Show: (
		self: Notifications,
		id: string,
		config: NotificationConfigOptions,
		metadata: any,
		onShowCallback: (id: string, metadata: any) -> ()?,
		onHideCallback: (id: string, metadata: any) -> ()?
	) -> (),
	ShowNext: (
		self: Notifications,
		id: string,
		config: NotificationConfigOptions,
		metadata: any,
		onShowCallback: (id: string, metadata: any) -> ()?,
		onHideCallback: (id: string, metadata: any) -> ()?
	) -> (),
	Cancel: (self: Notifications, id: string) -> boolean,
	PauseQueue: (self: Notifications) -> (),
	ResumeQueue: (self: Notifications) -> (),
	ClearQueue: (self: Notifications) -> (),
}

export type NotificationConfigOptions = {
	duration: number?,
	canCancel: boolean?, -- Defaults to true
}

export type QueueEntry = {
	id: string,
	duration: number,
	canCancel: boolean?,
	metadata: any?,
	onShowCallback: () -> ()?,
	onHideCallback: () -> ()?,
}

export type SignalConnection = {
	Disconnect: (self: SignalConnection) -> (),
	Destroy: (self: SignalConnection) -> (),
	Connected: boolean,
}

export type Signal<T...> = {
	Fire: (self: Signal<T...>, T...) -> (),
	FireDeferred: (self: Signal<T...>, T...) -> (),
	Connect: (self: Signal<T...>, fn: (T...) -> ()) -> SignalConnection,
	Once: (self: Signal<T...>, fn: (T...) -> ()) -> SignalConnection,
	DisconnectAll: (self: Signal<T...>) -> (),
	GetConnections: (self: Signal<T...>) -> { SignalConnection },
	Destroy: (self: Signal<T...>) -> (),
	Wait: (self: Signal<T...>) -> T...,
}

return {}
