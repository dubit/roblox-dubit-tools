export type UTC = {
	ToString: (self: UTC) -> string,
	SetUTCOffset: (self: UTC, offset: number) -> (),
	GetEpochTime: (self: UTC) -> number,
}

export type UTCModule = {
	now: () -> UTC,
	is: (object: UTC?) -> boolean,
	from: (epoch: number) -> UTC,
	new: (
		dateTable: {
			Year: number,
			Month: number,
			Day: number,
			Hour: number,
			Minute: number,
			Second: number,
		}
	) -> UTC,
}

export type Timer = {
	new: (expirationUTC: UTC) -> Timer,
	is: (object: Timer?) -> boolean,
}

export type Event = {
	Destroy: (self: Event) -> (),
	ToString: (self: Event) -> string,
	GetTimeUntilEnd: (self: Event) -> number,
	GetTimeUntilStart: (self: Event) -> number,
	GetState: (self: Event) -> boolean,
	SetState: (self: Event, state: boolean) -> (),
	UpdateTimers: (self: Event) -> (),

	Label: string,
	Activated: RBXScriptSignal,
	Deactivated: RBXScriptSignal,

	UTCStartTime: UTC?,
	UTCEndTime: UTC?,
}

export type EventModule = {
	new: (name: string, data: { UTCStartTime: UTC?, UTCEndTime: UTC? }) -> Event,
	is: (object: Event?) -> boolean,

	get: (name: string) -> Event | nil,
	getAll: () -> { [string]: Event },
}

export type TimeZone = {
	-- Africa
	CentralAfricaTime: number,
	EastAfricaTime: number,
	WestAfricaTime: number,
	SouthAfricaStandardTime: number,

	-- Asia
	IndiaStandardTime: number,
	ChinaStandardTime: number,
	JapanStandardTime: number,
	KoreaStandardTime: number,

	-- Europe
	CentralEuropeanTime: number,
	EasternEuropeanTime: number,
	BritishSummerTime: number,
	GreenwichMeanTime: number,

	-- North America
	EasternStandardTime: number,
	CentralStandardTime: number,
	MountainStandardTime: number,
	PacificStandardTime: number,
	AlaskaStandardTime: number,
	HawaiiAleutianStandardTime: number,

	-- Oceania
	AustralianEasternStandardTime: number,
	AustralianCentralStandardTime: number,
	AustralianWesternStandardTime: number,
	LordHoweStandardTime: number,
}

export type EventTracker = {
	GetEvent: (self: EventTracker, eventLabel: string) -> (),
	SetTimerFrequency: (self: EventTracker, value: number) -> (),
	GetNextEvent: (self: EventTracker) -> Event?,
	GetUpcomingEvents: (self: EventTracker) -> { Event },
	GetActiveEvents: (self: EventTracker) -> { Event },
	Start: (self: EventTracker) -> (),
}

return {}
