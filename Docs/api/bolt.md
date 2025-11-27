# API

## Bolt

### Functions

#### .ReliableEvent
```luau { .fn_type }
Bolt.ReliableEvent<T...>(eventName: string, serializer: ((writer: BufferWriter, T...) -> ())?, deserializer: ((reader: BufferReader) -> T...)?): ReliableEvent<T...>
```

Creates a **[ReliableEvent](#reliableevent_1)** that is used for communication between client <-> server with a guaranteed delivery on both sides.

#### .RemoteProperty
```luau { .fn_type }
Bolt.RemoteProperty<T>(propertyName: string, defaultValue: T, serializer: ((writer: BufferWriter, T) -> ())?, deserializer: ((reader: BufferReader) -> T)?): RemoteProperty<T>
```

Creates a **[RemoteProperty](#remoteproperty_1)** that automatically synchronizes its value to Players.

#### .RemoteFunction
```luau { .fn_type }
Bolt.RemoteFunction<T..., R...>(functionName: string): RemoteFunction<T..., R...>
```

Creates a **[RemoteFunction](#remotefunction_1)** that allows for clients to execute server functions just like they would do on the client side. The code invoking the function yields until it receives a response from the server.

!!! warning
	Bolt doesn't allow for server to client remote function calls as it's a security risk that's not worth the convinience.

## ReliableEvent

### Properties

#### OnClientEvent
```luau { .fn_type }
ReliableEvent.OnClientEvent: RestrictedConnector<T...>
```

Fires on client side when the server sends an event.

---

#### OnServerEvent
```luau { .fn_type }
ReliableEvent.OnServerEvent: RestrictedConnector<Player, T...>
```

Fires on server side when the client sends an event.

### Functions

#### :FireServer
```luau { .fn_type }
ReliableEvent:FireServer(...: T...): ()
```

Fires the **[OnServerEvent](#onserverevent)** event on the server from one client. Connected events receive the **Player** argument of the firing client. Since this method is used to communicate from a client to the server, it only works when used in a client script.

!!! warning
	This property can be only called from client scripts.

---

#### :FireClient
```luau { .fn_type }
ReliableEvent:FireClient(player: Player, ...: T...): ()
```

Fires the **[OnClientEvent](#onclientevent)** event for the specific client in the required **Player** argument. Since this method is used to communicate from the server to a client, it only works when used in a server script.

!!! warning
	This property can be only called from server scripts.

---

#### :FireAllClients
```luau { .fn_type }
ReliableEvent:FireAllClients(...: T...): ()
```

Fires the **[OnClientEvent](#onclientevent)** event for each connected client. Unlike **[FireClient](#fireclient)**, this event does not take a target **Player** as the first argument, since it fires to all connected players. Since this method is used to communicate from the server to clients, it only works when used in a server script.

!!! warning
	This property can be only called from server scripts.

## RemoteProperty

### Functions

#### :Observe
```luau { .fn_type }
RemoteProperty:Observe(callback: (value: T) -> ()): (() -> ())
```

Registers a callback function that gets called whenever the property value changes.

Registering a callback also means that the first callback it will receive will be the current value of that **[RemoteProperty](#remoteproperty_1)**.

Returns a function that when called disconnects the callback from the **[RemoteProperty](#remoteproperty_1)** and any further value updates won't be received by this callback function.

!!! warning
	This property can be only called from client scripts.

---

#### :Get
```luau { .fn_type }
RemoteProperty:Get(): T
```

Returns the current value of the property.

---

#### :GetFor
```luau { .fn_type }
RemoteProperty:GetFor(player: Player): T
```

Returns the current value of the property for a given player.

---

#### :Set
```luau { .fn_type }
RemoteProperty:Set(newValue: T): ()
```

Sets the value of the remote property to the newly passed one, if the new value is the same as the old value, the value update will be skipped.

When **[Set](#set)** is called all of the values set for players using **[SetFor](#setfor)** get cleared and are set to the newly passed value.

!!! warning
	This function can be only called from server scripts.

---

#### :SetFor
```luau { .fn_type }
RemoteProperty:SetFor(player: Player, newValue: T): ()
```

Sets the value of the remote property for that given player, if the new value is the same as the old value, the value update will be skipped.

Only this specific player will receive the value update, an "overwrite" gets created for this specific player and any further **[SetFor](#setfor)** calls will compare the new value with this one.

!!! warning
	This function can be only called from server scripts.

---

#### :ClearFor
```luau { .fn_type }
RemoteProperty:ClearFor(player: Player): ()
```

Clears the overwriten value that was set by **[SetFor](#setfor)**, if the master value that was set for this remote property is different from the value that was overwritten for the specific player passed in the parameter, they will get a value update.

!!! warning
	This function can be only called from server scripts.

## RemoteFunction

### Properties

#### OnServerInvoke
```luau { .fn_type }
RemoteFunction.OnServerInvoke: (player: Player, ...: T...): R...
```

This callback is called when the RemoteFunction is invoked with **[InvokeServer](#invokeserver)**. When the bound function returns, the returned values are sent back to the calling client.

??? example "Example Usage"
	=== "Server.luau"

		```luau
		local remoteFunction = Bolt.RemoteFunction("Foo") :: Bolt.RemoteFunction<(), (string)>

		remoteFunction.OnServerInvoke = function(player)
			return player.DisplayName
		end
		```

	=== "Client.luau"

		```luau
		local remoteFunction = Bolt.RemoteFunction("Foo") :: Bolt.RemoteFunction<(), (string)>

		print(remoteFunction:InvokeServer()) --> username
		```

!!! warning
	This property can only be set from server scripts.

### Functions

#### :InvokeServer
```luau { .fn_type }
RemoteFunction:InvokeServer(...: T...): R...
```

!!! danger
	This function yields.

Invokes the RemoteFunction which in turn calls the **[OnServerInvoke](#onserverinvoke)** callback. Since this method is used to communicate from a client to the server, it will only work when used in a client script.

Any type of Roblox object such as an Enum, Instance, or others can be passed as a parameter to InvokeServer(), as well as Luau types such as numbers, strings, and booleans.

!!! warning
	This property can be only called from client scripts.

## BufferReader

### Functions

#### .fromBuffer
```luau { .fn_type }
BufferReader.fromBuffer(buffer: buffer): BufferReader
```

---

#### .fromBuffer
```luau { .fn_type }
BufferReader.fromString(string: string): BufferReader
```

---

#### :ReadB8
```luau { .fn_type }
BufferReader:ReadB8(): { boolean }
```

---

#### :ReadI8
```luau { .fn_type }
BufferReader:ReadI8(): number
```

---

#### :ReadI16
```luau { .fn_type }
BufferReader:ReadI16(): number
```

---

#### :ReadI24
```luau { .fn_type }
BufferReader:ReadI24(): number
```

---

#### :ReadI32
```luau { .fn_type }
BufferReader:ReadI32(): number
```

---

#### :ReadU8
```luau { .fn_type }
BufferReader:ReadU8(): number
```

---

#### :ReadU16
```luau { .fn_type }
BufferReader:ReadU16(): number
```

---

#### :ReadU24
```luau { .fn_type }
BufferReader:ReadU24(): number
```

---

#### :ReadU32
```luau { .fn_type }
BufferReader:ReadU32(): number
```

---

#### :ReadU40
```luau { .fn_type }
BufferReader:ReadU40(): number
```

---

#### :ReadU56
```luau { .fn_type }
BufferReader:ReadU56(): number
```

---

#### :ReadF32
```luau { .fn_type }
BufferReader:ReadF32(): number
```

---

#### :ReadF64
```luau { .fn_type }
BufferReader:ReadF64(): number
```

---

#### :ReadInstance
```luau { .fn_type }
BufferReader:ReadInstance(): Instance
```

---

#### :ReadString
```luau { .fn_type }
BufferReader:ReadString(count: number?): string
```

---

#### :ReadVector2
```luau { .fn_type }
BufferReader:ReadVector2(): Vector2
```

---

#### :ReadVector3
```luau { .fn_type }
BufferReader:ReadVector3(): Vector3
```

---

#### :ReadCFrame
```luau { .fn_type }
BufferReader:ReadCFrame(): CFrame
```

---

#### :ReadColor3
```luau { .fn_type }
BufferReader:ReadColor3(): Color3
```

## BufferWriter

### Functions

#### .new
```luau { .fn_type }
BufferWriter.new(size: number): BufferWriter
```

---

#### .fromBuffer
```luau { .fn_type }
BufferWriter.fromBuffer(source: buffer): BufferWriter
```

---

#### :WriteB8
```luau { .fn_type }
BufferWriter:WriteB8(...boolean): ()
```

---

#### :WriteI8
```luau { .fn_type }
BufferWriter:WriteI8(value: number): ()
```

---

#### :WriteI16
```luau { .fn_type }
BufferWriter:WriteI16(value: number): ()
```

---

#### :WriteI24
```luau { .fn_type }
BufferWriter:WriteI24(value: number): ()
```

---

#### :WriteI32
```luau { .fn_type }
BufferWriter:WriteI32(value: number): ()
```

---

#### :WriteU8
```luau { .fn_type }
BufferWriter:WriteU8(value: number): ()
```

---

#### :WriteU16
```luau { .fn_type }
BufferWriter:WriteU16(value: number): ()
```

---

#### :WriteU24
```luau { .fn_type }
BufferWriter:WriteU24(value: number): ()
```

---

#### :WriteU32
```luau { .fn_type }
BufferWriter:WriteU32(value: number): ()
```

---

#### :WriteU40
```luau { .fn_type }
BufferWriter:WriteU40(value: number): ()
```

---

#### :WriteU56
```luau { .fn_type }
BufferWriter:WriteU56(value: number): ()
```

---

#### :WriteF32
```luau { .fn_type }
BufferWriter:WriteF32(value: number): ()
```

---

#### :WriteF64
```luau { .fn_type }
BufferWriter:WriteF64(value: number): ()
```

---

#### :WriteInstance
```luau { .fn_type }
BufferWriter:WriteInstance(instance: Instance): ()
```

---

#### :WriteString
```luau { .fn_type }
BufferWriter:WriteString(string: string, count: number?): ()
```

---

#### :WriteVector2
```luau { .fn_type }
BufferWriter:WriteVector2(value: Vector2): ()
```

---

#### :WriteVector3
```luau { .fn_type }
BufferWriter:WriteVector3(value: Vector3): ()
```

---

#### :WriteCFrame
```luau { .fn_type }
BufferWriter:WriteCFrame(value: CFrame): ()
```

---

#### :WriteColor3
```luau { .fn_type }
BufferWriter:WriteColor3(value: Color3): ()
```

---

#### :Fit
```luau { .fn_type }
BufferWriter:Fit(): ()
```

Shrinks the internal buffer size to the current internal cursor offset.