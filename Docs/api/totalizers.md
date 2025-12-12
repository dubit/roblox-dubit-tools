# API

## Properties

### TotalizerUpdated
```luau { .fn_type }
Totalizers.TotalizerUpdated: Signal<string, number>
```

Invoked when a totalizer value is updated, either by the server the script is running on or by another server within the experience if **[SetBroadcastingEnabled](#setbroadcastingenabled)** is enabled (which it is by default).

!!! success ""
	This is a server only property.

## Methods

### :GetAsync
```luau { .fn_type }
Totalizers:GetAsync(identifier: string): number
```

Returns the current value of the totalizer.

!!! success ""
	This is a server only method.

---

### :IncrementAsync
```luau { .fn_type }
Totalizers:IncrementAsync(identifier: string, incrementBy: number? = 1): (boolean, number)
```

Increments the current value of the totalizer. Returns **true** followed by the **new value** if the increment was successful.

!!! success ""
	This is a server only method.

---

### :ResetAsync
```luau { .fn_type }
Totalizers:ResetAsync(identifier: string): boolean
```

Resets the current value of the totalizer to 0. Returns **true** when successful.

!!! success ""
	This is a server only method.

---

### :SetUpdateRate
```luau { .fn_type }
Totalizers:SetUpdateRate(updateRate: number = >=30): ()
```

Sets the current update rate.

Default: 60 seconds

!!! success ""
	This is a server only method.

---

### :GetUpdateRate
```luau { .fn_type }
Totalizers:GetUpdateRate(): number
```

Returns the current update rate.

Default: 60 seconds

!!! success ""
	This is a server only method.

---

### :SetBroadcastingEnabled
```luau { .fn_type }
Totalizers:SetBroadcastingEnabled(enabled: boolean): ()
```

Enables or disables the broadcasting feature. When enabled, updates to totalizer values are sent between servers, resulting in more responsive and accurate totalizer values across the entire experience.

!!! success ""
	This is a server only method.