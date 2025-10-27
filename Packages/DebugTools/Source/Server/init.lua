local ServerDebugTools = {}

require(script.Builtin.Console)
require(script.Builtin.Actions)
require(script.Builtin.ActionModules.SetTPS)
require(script.Builtin.ActionModules.LockServer)
require(script.Builtin.Info)

ServerDebugTools.Module = require(script.Module)
ServerDebugTools.Action = require(script.Parent.Shared.Action)

ServerDebugTools.Networking = require(script.Networking)

return ServerDebugTools
