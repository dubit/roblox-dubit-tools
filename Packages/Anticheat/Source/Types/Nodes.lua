--[[
	Nodes represent the fundamental building blocks of the Anticheat system. Each node defines a specific feature or functionality.

	- Nodes are used throughout the codebase as signatures for detecting specific behaviors.
	- For example, if a player is speed hacking, the AntiSpeed node will be flagged.
]]

export type Enum = "ProximityPrompt" | "Honeypot" | "AntiClimb" | "AntiSwim" | "AntiFly" | "AntiNoclip" | "AntiSpeed"

return nil
