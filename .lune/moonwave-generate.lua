--# moonwave: allow(incorrect_standard_library_use)

--# usage: lune Moonwave-Generate

-- https://lune-org.github.io/docs/api-reference/process
local process = require("@lune/process")

-- https://lune-org.github.io/docs/api-reference/fs
local fileSystem = require("@lune/fs")

local AFTMAN_CI_DIR = ".aftman-ci"

print(`[Execute]: Setting 'AFTMAN_ROOT' var to: '{process.cwd}{AFTMAN_CI_DIR}'`)

process.env.AFTMAN_ROOT = `{process.cwd}{AFTMAN_CI_DIR}`

if not fileSystem.isFile(`{process.cwd}{AFTMAN_CI_DIR}/bin/moonwave`) then
	error(`[Execute]: Failed to locate 'moonwave' binary! Were dependencies installed correctly?`, math.huge)
end

local result = process.spawn(`{process.cwd}{AFTMAN_CI_DIR}/bin/moonwave`, {
	`extract`,
	`--base`,
	`Packages`,
})

if result.ok then
	print(`[Moonwave-Generate]: project moonwave OK`)
else
	print(`[Moonwave-Generate]: project moonwave FAIL ({result.code}):\n{result.stderr}\n{result.stdout}`)

	process.exit(result.code)
end

process.exit(0)
