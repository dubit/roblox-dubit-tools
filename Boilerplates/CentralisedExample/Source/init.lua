--[[
	ToolName:
		Tool Description/summary

	R&D Documentation:
		Tool R&D Documentation

	Documentation has been written in a Moonwave styled format, for documentation outside of moonwave - comments have been made to provide insight.
]]
--

local Types = require(script.Types)

--[[
	@class ToolName

	Tool Description/summary

	---

	In depth summary of what your tool offers, what its purpose is and anything else you'd like to share, this is the first thing developers will see.

	---

	R&D Documentation:
	- Tool R&D Documentation
]]
local ToolName = {}

ToolName.interface = {}
ToolName.internal = {}

--[[
	Tools follow a modular approach in contrast to the generic return of a value, tools have a 'core' table, and an 'interface' table.

	The 'interface' table represents what the end user - the developer, gets.
	The 'core' table represents the tool.

	in the case you'd like to implement private methods, an 'internal' table should be generated under the 'core' table.
]]
--

return ToolName.interface :: Types.ToolName & {
	-- implement further properties or LSP your tool requires.
}
