--# selene: allow(incorrect_standard_library_use)

--# usage: lune execute
-- arg1: tool name
-- arg...: arguments passed into the tool

-- https://lune-org.github.io/docs/api-reference/process
local process = require("@lune/process")

-- https://lune-org.github.io/docs/api-reference/fs
local fileSystem = require("@lune/fs")

local AFTMAN_CI_DIR = ".aftman-ci"

local processArguments = table.clone(process.args)

local toolName = table.remove(processArguments, 1)
local toolArgs = processArguments

print(`[Execute]: Setting 'AFTMAN_ROOT' var to: '{process.cwd}{AFTMAN_CI_DIR}'`)

process.env.AFTMAN_ROOT = `{process.cwd}{AFTMAN_CI_DIR}`

if not fileSystem.isFile(`{process.cwd}{AFTMAN_CI_DIR}/bin/{toolName}`) then
	error(`[Execute]: Failed to locate '{toolName}' binary! Were dependencies installed correctly?`, math.huge)
end

print(`[Execute]: Running '{toolName}':`)
local result = process.spawn(`{process.cwd}{AFTMAN_CI_DIR}/bin/{toolName}`, toolArgs)

if result.ok then
	print(`[Execute]: '{toolName}' successfully executed :`)
else
	print(`[Execute]: '{toolName}' failed to execute with code '{result.code}' :`)
end

for _, line in string.split(`{result.stdout}\n{result.stderr}`, "\n") do
	if string.gsub(line, " ", "") == "" then
		continue
	end

	print(`> {line}`)
end

process.exit(result.code)
