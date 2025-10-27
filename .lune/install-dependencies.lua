--# selene: allow(incorrect_standard_library_use)

--# usage: lune install-dependencies
-- arg1: OPTIONAL - github personal access token, used to authenticate aftman

-- https://lune-org.github.io/docs/api-reference/process
local process = require("@lune/process")

-- https://lune-org.github.io/docs/api-reference/fs
local fileSystem = require("@lune/fs")

local AFTMAN_CI_DIR = ".aftman-ci"

local processArguments = table.clone(process.args)

local githubPersonalAccessToken = table.remove(processArguments, 1)

print(`[Install-Dependencies]: Setting 'AFTMAN_ROOT' var to: '{process.cwd}{AFTMAN_CI_DIR}'`)
process.env.AFTMAN_ROOT = `{process.cwd}{AFTMAN_CI_DIR}`

if githubPersonalAccessToken then
	print(`[Install-Dependencies]: Setting up 'Aftman' authentication`)

	if not fileSystem.isDir(process.env.AFTMAN_ROOT) then
		fileSystem.writeDir(process.env.AFTMAN_ROOT)
	end

	fileSystem.writeFile(`{process.env.AFTMAN_ROOT}/auth.toml`, `github="{githubPersonalAccessToken}"`)
	print(`[Install-Dependencies]: Authentication set up`)
end

print(`[Install-Dependencies]: Installing Aftman dependencies!`)
local result = process.spawn("aftman", {
	"install",
	"--no-trust-check",
})

if result.ok then
	print(`[Install-Dependencies]: Installed all Aftman dependencies!`)
	print(`[Install-Dependencies]: Aftman result:`)
else
	print(`[Install-Dependencies]: Failed to install Aftman dependencies:`)
end

for _, line in string.split(`{result.stdout}\n{result.stderr}`, "\n") do
	if string.gsub(line, " ", "") == "" then
		continue
	end

	print(`> {line}`)
end

process.exit(result.code)
