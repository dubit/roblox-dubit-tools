--# selene: allow(incorrect_standard_library_use)

--# usage: lune lint-projects

-- https://lune-org.github.io/docs/api-reference/process
local process = require("@lune/process")

-- https://lune-org.github.io/docs/api-reference/fs
local fileSystem = require("@lune/fs")

local AFTMAN_CI_DIR = ".aftman-ci"

print(`[Execute]: Setting 'AFTMAN_ROOT' var to: '{process.cwd}{AFTMAN_CI_DIR}'`)

process.env.AFTMAN_ROOT = `{process.cwd}{AFTMAN_CI_DIR}`

if not fileSystem.isFile(`{process.cwd}{AFTMAN_CI_DIR}/bin/selene`) then
	error(`[Execute]: Failed to locate 'selene' binary! Were dependencies installed correctly?`, math.huge)
end

for _, packageName in fileSystem.readDir("Packages") do
	local result = process.spawn(`{process.cwd}{AFTMAN_CI_DIR}/bin/selene`, {
		`.`,
	}, {
		cwd = `{process.cwd}Packages/{packageName}`,
	})

	if result.ok then
		print(`[Lint-Projects]: project '{packageName}' selene lint OK`)
	else
		print(
			`[Lint-Projects]: project '{packageName}' selene lint FAIL ({result.code}):\n{result.stderr}\n{result.stdout}`
		)

		process.exit(result.code)
	end
end

process.exit(0)
