--[[
	EmoticonReporter - A fork of `TestEz.Reporters.EmoticonReporter` that implements the following;

	Updated Status Symbols:
		[🟣]: Unknown Test Status
		[🟢]: Successful Test Status
		[🔴]: Failed Test Status
		[🟡]: Skipped Test Status

	Updated Indent:
		3 Spaces -> 1 Tab

	Updated Code Style to match Dubit StyleGuide
]]
--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestService = game:GetService("TestService")

local TestEz = require(ReplicatedStorage.DevPackages.TestEz)

local INDENT = "   "
local UNKNOWN_STATUS_SYMBOL = "🟣"
local STATUS_SYMBOLS = table.freeze({
	[TestEz.TestEnum.TestStatus.Success] = "🟢",
	[TestEz.TestEnum.TestStatus.Failure] = "🔴",
	[TestEz.TestEnum.TestStatus.Skipped] = "🟡",
})

local EmoticonReporter = {}

local function reportNode(node, buffer, level)
	buffer = buffer or {}
	level = level or 0

	if node.status == TestEz.TestEnum.TestStatus.Skipped then
		return buffer
	end

	local line

	if node.status then
		local symbol = STATUS_SYMBOLS[node.status] or UNKNOWN_STATUS_SYMBOL

		line = ("%s[%s] %s"):format(INDENT:rep(level), symbol, node.planNode.phrase)
	else
		line = ("%s%s"):format(INDENT:rep(level), node.planNode.phrase)
	end

	table.insert(buffer, line)

	for _, child in ipairs(node.children) do
		reportNode(child, buffer, level + 1)
	end

	return buffer
end

local function reportRoot(node)
	local buffer = {}

	for _, child in ipairs(node.children) do
		reportNode(child, buffer, 0)
	end

	return buffer
end

local function report(root)
	local buffer = reportRoot(root)

	return table.concat(buffer, "\n")
end

function EmoticonReporter.report(results)
	local resultBuffer = {
		"Test results:",
		report(results),
		("%d passed, %d failed, %d skipped"):format(results.successCount, results.failureCount, results.skippedCount),
	}

	print(table.concat(resultBuffer, "\n"))

	if results.failureCount > 0 then
		print(("%d test nodes reported failures."):format(results.failureCount))
	end

	if #results.errors > 0 then
		print("Errors reported by tests:")
		print("")

		for _, message in results.errors do
			TestService:Error(message)

			-- Insert a blank line after each error
			print("")
		end
	end
end

return EmoticonReporter
