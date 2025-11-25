# API

## Properties

### CheaterFound
```luau { .fn_type }
AntiCheat.CheaterFound: Signal<Player>
```

Invoked when the anti-cheat determines a player is cheating

```luau
AntiCheat.CheaterFound:Connect(function(player)
	Players:BanAsync({
		UserIds = { player.UserId },
		DisplayReason = "\"There is no right and wrong. There's only fun and boring.\" ~ Hackers"
	})
end)
```

### ViolationTriggered
```luau { .fn_type }
AntiCheat.ViolationTriggered: Signal<Player, string, string>
```

!!! warning
	This signal should not be used to detect cheaters. Use the **[CheaterFound](#cheaterfound)** signal instead!

Invoked when a player triggers a rule violation, increasing their anti-cheat score.

```luau
AntiCheat.ViolationTriggered:Connect(function(player, node, message)
	print(`Player {player.Name} has violated node '{node}': '{message}'`)
end)
```

## Methods

### :AddToWhitelist
```luau { .fn_type }
AntiCheat:AddToWhitelist(player: Player): ()
```

Adds a player to the whitelist. Whitelisted players are exempt from anti-cheat monitoring and can freely bypass restrictions.

!!! success ""
	This is a server only method.

### :Disable
```luau { .fn_type }
AntiCheat:Disable(): ()
```

Disables the anti-cheat. When this method is called, all detection nodes are stopped, meaning players will no longer be monitored.

!!! success ""
	This is a server only method.


### :DisableNode
```luau { .fn_type }
AntiCheat:Disable(node: string | NodeTable): ()
```

Disables a specific "node" of the AntiCheat.

To further explain what a Node is - the anticheat is broken up into several parts, each play their own role in identifying potential exploiters, and then getting them detected.

Developers have the ability to disable/enable different nodes in the event the Noclip detection is currently acting up and we may not have the time to address the issues with it.

```luau
AntiCheat:DisableNode(AntiCheat.AntiFly)
AntiCheat:DisableNode("AntiFly")
```

!!! success ""
	This is a server only method.

### :Enable
```luau { .fn_type }
AntiCheat:Enable(): ()
```

Enables the anti-cheat. This should only be called if the anti-cheat has been previously disabled using the :Disable method.

!!! success ""
	This is a server only method.

### :EnableNode
```luau { .fn_type }
AntiCheat:EnableNode(node: string | NodeTable) → ()
```

Enables a specific "node" of the AntiCheat.

To further explain what a Node is - the anticheat is broken up into several parts, each play their own role in identifying potential exploiters, and then getting them detected.

Developers have the ability to disable/enable different nodes in the event the Noclip detection is currently acting up and we may not have the time to address the issues with it.

```luau
AntiCheat:EnableNode(AntiCheat.AntiFly)
AntiCheat:EnableNode("AntiFly")
```

!!! success ""
	This is a server only method.

### :FlagAsCheater
```luau { .fn_type }
AntiCheat:FlagAsCheater(player: Player): ()
```

Flags a player as a cheater. This information is stored in a datastore, managed entirely by the anti-cheat system.

!!! warning
	This function is automatically called when a player is detected as a cheater. See **[CheaterFound](#cheaterfound)** for more details.

!!! success ""
	This is a server only method.

### :IsFlaggedAsCheater
```luau { .fn_type }
AntiCheat:IsFlaggedAsCheater(player: Player): ()
```

Allows developers on both the client, and the server - to query if the current player is a cheater or not.

### :QueryScores
```luau { .fn_type }
AntiCheat:QueryScores(player: Player): {[string]: number}
```

Allows developers to query the current players score for all nodes. Score indicates how likely that player is to be a cheater, it's not a direct indication that these players are cheaters.

!!! success ""
	This is a server only method.

### :QueryViolations
```luau { .fn_type }
AntiCheat:QueryViolations(player: Player): {[string]: {string}}
```

Allows developers to query a list of violations that the current player has broken, this list includes messages explaining what has gone wrong and information about the event.

This list is broken up to allow developers to see what specific nodes a player has violated, then the messages are bundled under each node.

!!! success ""
	This is a server only method.

### :RemoveFromWhitelist
```luau { .fn_type }
AntiCheat:RemoveFromWhitelist(player: Player): ()
```

Removes a player from the whitelist. See **[AddToWhitelist](#addtowhitelist)** for details.

!!! success ""
	This is a server only method.

### :ResetFlag
```luau { .fn_type }
AntiCheat:ResetFlag(path: string): ()
```

Will reset the flag to whatever it is by default, this allows developers to safely fallback to the defaults without having to create references for each flag before hand.

```luau
AntiCheat:ResetFlag(AntiCheat.AntiFly.RaycastDistance)
```

!!! success ""
	This is a server only method.

### :SetFlag
```luau { .fn_type }
AntiCheat:SetFlag(path: string, value: any): ()
```

Allows developers to configure specific flags the anticheat, and all nodes under it uses to identify and detect potential exploiters.

Be careful when modifying these flags, we should try to optimise the default flags over having different flags defined per project.

```luau
AntiCheat:SetFlag(AntiCheat.AntiFly.RaycastDistance, 1.5)

-- alternatively, if you know what these are called internally, you can use the name of the path you're writing
-- to instead.
AntiCheat:EnableNode("AntiFlyRaycastDistance")
```

!!! success ""
	This is a server only method.

### :SetVerbose
```luau { .fn_type }
AntiCheat:SetVerbose(isVerbose: boolean): ()
```

Enables or disables debug warnings in the Output. By default, this is set to false.

Warnings indicate when a player has violated a node's rules, allowing developers to diagnose unintended behavior (e.g., a player being teleported back after a script-triggered teleport).

!!! success ""
	This is a server only method.

### :WaitUntilReady
```luau { .fn_type }
AntiCheat:WaitUntilReady(): ()
```

Will yield the current thread until the whitelist has marked itself as ready on parallel luau, because the anticheat works by sending messages through bindable events - we need to make sure the other side (parallel luau) is set up before we start emitting events.

!!! success ""
	This is a server only method.