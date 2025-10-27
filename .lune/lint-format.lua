--# selene: allow(incorrect_standard_library_use)

--# usage: lune lint-format

-- https://lune-org.github.io/docs/api-reference/process
local process = require("@lune/process")

-- https://lune-org.github.io/docs/api-reference/fs
local fileSystem = require("@lune/fs")

local AFTMAN_CI_DIR = ".aftman-ci"

print(`[Lint-Format]: Setting 'AFTMAN_ROOT' var to: '{process.cwd}{AFTMAN_CI_DIR}'`)

process.env.AFTMAN_ROOT = `{process.cwd}{AFTMAN_CI_DIR}`

local function execute(toolName, toolArgs)
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

	if not result.ok then
		process.exit(result.code)
	end
end

local function getAllChangedLuauFiles()
	local unfilteredLuauFilepaths = {}
	local filteredLuauFilepaths = {}
	local gitStatus = process.spawn("git", {
		"diff",
		"--name-only",
		"HEAD",
		`origin/{process.env.BITBUCKET_PR_DESTINATION_BRANCH}`,
	})

	if not gitStatus.ok then
		error(gitStatus.stderr)
	end

	unfilteredLuauFilepaths = string.split(gitStatus.stdout, "\n")

	for _, filepath in unfilteredLuauFilepaths do
		if string.sub(filepath, -3) ~= "lua" and string.sub(filepath, -4) ~= "luau" then
			continue
		end

		if string.sub(filepath, -6) == ".d.lua" or string.sub(filepath, -7) == ".d.luau" then
			continue
		end

		if not fileSystem.isFile(filepath) then
			continue
		end

		table.insert(filteredLuauFilepaths, filepath)
	end

	return filteredLuauFilepaths
end

if not process.env.BITBUCKET_PR_DESTINATION_BRANCH then
	print("[Lint-Format]: No pull request destination branch detected, skipping linting and formatting.")
	process.exit(0)
end

local changedLuauFiles = getAllChangedLuauFiles()
if #changedLuauFiles == 0 then
	print("[Lint-Format]: No changed luau files detected, skipping linting and formatting.")
	process.exit(0)
end

execute("stylua", {
	"--check",
	"--output-format",
	"Summary",
	table.unpack(changedLuauFiles),
})

execute("selene", changedLuauFiles)
