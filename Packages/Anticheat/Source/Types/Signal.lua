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

return nil
