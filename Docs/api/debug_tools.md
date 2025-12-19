# API

## Action

### Methods

#### .new
```luau { .fn_type }
DebugTools.Action.new(name: string, description: string?, action: (any...) -> ()), arguments: { Type: "string" | "number" | "boolean" | "Player", Name: string?, Default: any?, Options: { any }? })
```

Defines a new action, for more information check out **[Overview](../packages/debug_tools.md#actions)**.

## Authorization

### Properties

#### PlayerAuthorized
```luau { .fn_type }
DebugTools.Authorization.PlayerAuthorized: Signal<Player>
```

Fires whenever player gets authorized and is allowed to use DebugTools.

!!! success ""
	This is a server only property.

---

#### PlayerAuthorizationLost
```luau { .fn_type }
DebugTools.Authorization.PlayerAuthorizationLost: Signal<Player>
```

Fires whenever player looses the rights to use DebugTools.

!!! success ""
	This is a server only property.

### Methods

#### :IsPlayerAuthorizedAsync
```luau { .fn_type }
DebugTools.Authorization:IsPlayerAuthorizedAsync(player: Player): boolean
```

Returns true if player is authorized to use DebugTools, this function can yield if player is in the process of being authorized.

!!! danger
	This function can yield.

!!! success ""
	This is a server only method.

---

#### :SetAuthorizationCallback
```luau { .fn_type }
DebugTools.Authorization:SetAuthorizationCallback(callback: ((player: Player) -> boolean)?): ()
```

Defines a new authorization callback, if callback is missing the default authorization method is used.

When changing the authorization callback all of the players in the server will be reauthorized again.

!!! success ""
	This is a server only method.

## Console

### Methods

#### :AddMessage
```luau { .fn_type }
DebugTools.Console:AddMessage(text: string, textType: Enum.MessageType, serverSided: boolean): ()
```

Adds a message to internal DebugTools console which won't print anything to Robloxes output, the messages will appear only within **[GetOutputLog](#getoutputlog)** and **Output** widget.

!!! info ""
	This is a client only method.

---

#### :GetOutputLog
```luau { .fn_type }
DebugTools.Console:GetOutputLog(): string
```

Returns a string with last 400 messages logged to the internal DebugTools console.

!!! info ""
	This is a client only method.

## Widget

### Methods

#### .new
```luau { .fn_type }
DebugTools.Widget.new(widgetName: string, widgetCreateFunction: (parent: ScreenGui) -> () -> ())): ()
```

Defines a new widget, for more information check out **[Overview](../packages/debug_tools.md#widgets)**.

!!! info ""
	This is a client only method.

---

#### :GetAll
```luau { .fn_type }
DebugTools.Widget:GetAll(): { [string]: { Mounted: boolean, ScreenGui: ScreenGui? } }
```

Returns all of the defined widgets.

!!! info ""
	This is a client only method.

---

#### :Hide
```luau { .fn_type }
DebugTools.Widget:Hide(widgetName: string): ()
```

Hides a widget.

!!! info ""
	This is a client only method.

---

#### :Show
```luau { .fn_type }
DebugTools.Widget:Show(widgetName: string): ()
```

Shows a widget.

!!! info ""
	This is a client only method.

---

#### :IsVisible
```luau { .fn_type }
DebugTools.Widget:IsVisible(widgetName: string): boolean
```

Returns true if widget is visible.

!!! info ""
	This is a client only method.

---

#### :SwitchVisibility
```luau { .fn_type }
DebugTools.Widget:SwitchVisibility(widgetName: string): ()
```

Switches between the current visibility state of a widget, if it's hidden then the widget will be shown and vice versa.

!!! info ""
	This is a client only method.

## Networking

### Methods

#### :SendMessage
```luau { .fn_type }
DebugTools.Networking:SendMessage(topic: string, ...): ()
```

If used from client side, it will send a message to the server.

If used from server side, it will send a message to all of the authorized players in the server.

---

#### :SendMessageToPlayer
```luau { .fn_type }
DebugTools.Networking:SendMessageToPlayer(player: Player, topic: string, ...): ()
```

Works similarly to **[SendMessage](#sendmessage)** but the message will be only sent to just one player.

!!! success ""
	This is a server only method.

---

#### :SubscribeToTopic
```luau { .fn_type }
DebugTools.Networking:SubscribeToTopic(topic: string, callback: (...any) -> ...any): ()
```

Subscribes to a message with a given topic, will trigger a callback with whatever parameters were passed when the message was sent.

## Tab

### Methods

#### .new
```luau { .fn_type }
DebugTools.Tab.new(name: string, constructorFunction: (parent: Frame) -> () -> ())
```

Defines a new tab, for more information check out **[Overview](../packages/debug_tools.md#tabs)**.

!!! info ""
	This is a client only method.

## IMGui

### Methods

#### .applyFrameStyle
```luau { .fn_type }
DebugTools.IMGui.applyFrameStyle(instance: Frame | TextButton): ()
```

Applies IMGui styling to a given Instance.

!!! info ""
	This is a client only method.

---

#### .applyTextStyle
```luau { .fn_type }
DebugTools.IMGui.applyTextStyle(instance: TextLabel | TextButton): ()
```

Applies IMGui styling to a given Instance.

!!! info ""
	This is a client only method.

---

#### :Connect
```luau { .fn_type }
DebugTools.IMGui:Connect(parent: GuiBase, tickLoop: () -> ()): () -> ()
```

Mounts IMGui under the specified parent instance. The parent and all created instances are fully managed by the IMGui system, so modifying them outside of IMGui’s internal logic is not recommended. All UI logic should be implemented inside the tickLoop function.

Returns a destructor function that unmounts the interface from the parent and performs cleanup.

!!! info ""
	This is a client only method.

---

#### :NewWidgetDefinition
```luau { .fn_type }
DebugTools.IMGui:NewWidgetDefinition(identifier: string, definition: WidgetDefinition): ()
```

Defines a new IMGui widget that can be accessed by IMGui:*identifier*.

??? example "Example Usage"
	```lua
	IMGui:NewWidgetDefinition("Label", {
		Construct = function(self: ImguiLabel, parent: GuiObject, text: string)
			local textInstance: TextLabel = Instance.new("TextLabel")
			textInstance.Name = `Label ({self.ID})`
			textInstance.AutomaticSize = Enum.AutomaticSize.XY
			textInstance.Text = text
			textInstance.RichText = true
			textInstance.BackgroundTransparency = 1
			textInstance.BorderSizePixel = 0

			IMGui.applyTextStyle(textInstance)

			textInstance.Parent = parent

			return textInstance
		end,

		Update = function(self: ImguiLabel, text: string)
			self.TopInstance.Text = text
		end,
	})
	```

!!! info ""
	This is a client only method.

---

#### :GetTick
```luau { .fn_type }
DebugTools.IMGui:GetTick(): number
```

Returns the current tick of the active tick loop. The value is monotonically increasing.

!!! info ""
	This is a client only method.

---

#### :GetConfig
```luau { .fn_type }
DebugTools.IMGui:GetConfig(): any
```

Returns a table with current IMGui config.

!!! info ""
	This is a client only method.