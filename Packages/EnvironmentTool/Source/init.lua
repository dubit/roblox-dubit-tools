--[=[
	@class EnvironmentTool

	Roblox environment tool with the ability to determine if the current environment is the edge, stable, production or
	local. This module has equal behaviour from both the client and server, can be required from anywhere, and has no
	dependencies.

	Example Usages:
		local isProduction = EnvironmentTool:IsProduction()
		if isProduction then
			--Do something super special on the production environment
		end

		--Set up different badge IDs for each environment
		local badgeIds = {
			[EnvironmentTool.Environment.Edge] = 2348972347892,
			[EnvironmentTool.Environment.Stable] = 329847234892379,
			[EnvironmentTool.Environment.Production] = 3241897819110,
			[EnvironmentTool.Environment.Local] = 0,
		}

		local awardBadgeId = badgeIds[EnvironmentTool:GetEnvironment()]

	In practice, it's not recommended to overuse this system. This is mainly because using features that are specific
	to a certain environment creates less consistency between those environments, giving us a harder time when doing QA
	on projects.

	In order for this tool to work, the branch attribute of workspace must be set during bitbucket pipeline deployment.
	This can be achieved using a lune deploy script containing the following:

	project/.lune/deploy.lua
		print(`[Deploy-To]: Set workspace attribute 'Branch' to: '{process.env.BITBUCKET_BRANCH}'`)
		game.Workspace:SetAttribute("Branch", process.env.BITBUCKET_BRANCH)

	This module will produce a warning if the branch attribute is not found on a non-local build.
]=]
local RunService = game:GetService("RunService")

local PRODUCTION_BRANCH_NAMES = table.freeze({
	["master"] = true,
	["main"] = true,
})

local EDGE_BRANCH_NAMES = table.freeze({
	["development"] = true,
	["develop"] = true,
})

local RELEASE_BRANCH_PREFIXES = table.freeze({
	["release"] = true,
	["stable"] = true,
})

local EnvironmentTool = {}

--[=[
	@prop Environment {[string] : string}
	@within EnvironmentTool
]=]
EnvironmentTool.Environment = {
	Edge = "Edge",
	Stable = "Stable",
	Production = "Production",
	Local = "Local",
}

--[=[
	@method GetBranch
	@within EnvironmentTool
	@private
	@return string

	Internal function - gets the branch attribute of workspace, represents the bitbucket branch that was used to create
	this build. Please refer to the EnvironmentTool documentation to learn how to set the branch attribute correctly
	during place deployment.

	Returns empty string for local builds
]=]
function EnvironmentTool._GetBranch(_: EnvironmentTool): string
	local branchAttribute = workspace:GetAttribute("Branch")

	if not RunService:IsStudio() and not branchAttribute then
		warn(`EnvironmentTool unable to determine environment, has the "branch" attribute been set during deployment?`)
	end

	return branchAttribute or ""
end

--[=[
	@method IsProduction
	@within EnvironmentTool
	@return boolean

	Determines if the current environment is production, returns boolean value

	Example usage:
		local isProduction = EnvironmentTool:IsProduction()
]=]
function EnvironmentTool.IsProduction(self: EnvironmentTool): boolean
	return PRODUCTION_BRANCH_NAMES[self:_GetBranch()] == true
end

--[=[
	@method IsStable
	@within EnvironmentTool
	@return boolean

	Determines if the current environment is stable, returns boolean value

	Example usage:
		local isStable = EnvironmentTool:IsStable()
]=]
function EnvironmentTool.IsStable(self: EnvironmentTool): boolean
	local branchName = self:_GetBranch()
	for prefix in RELEASE_BRANCH_PREFIXES do
		--Check if branch name begins with this prefix
		if string.match(branchName, `^{prefix}`) then
			return true
		end
	end
	return false
end

--[=[
	@method IsEdge
	@within EnvironmentTool
	@return boolean

	Determines if the current environment is edge, returns boolean value

	Returns false for local builds

	Example usage:
		local isEdge = EnvironmentTool:IsEdge()
]=]
function EnvironmentTool.IsEdge(self: EnvironmentTool): boolean
	return EDGE_BRANCH_NAMES[self:_GetBranch()] == true
end

--[=[
	@method IsLocal
	@within EnvironmentTool
	@return boolean

	Determines if the current environment is local, returns boolean value

	Only returns true if the "Branch" attribute of workspace is nil or empty. NOTE: This can still return true in an
	online roblox studio team create, if the branch name attribute has not been set by any pipelines. However, it
	will return false for online edge or stable environments

	Example usage:
		local isLocalEnvironment = EnvironmentTool:IsLocal()
]=]
function EnvironmentTool.IsLocal(self: EnvironmentTool): boolean
	local branchName = self:_GetBranch()
	return branchName == "" or branchName == nil
end

--[=[
	@method GetEnvironment
	@within EnvironmentTool
	@return Environment -- environment string which can be "Edge", "Stable", "Production" or "Local"

	If the player is in an online roblox studio, where the place has been built using bitbucket pipelines, it will
	correctly identify the build. If no such environment is found, it will return "Local"

	Example usage:
		local isEdge = EnvironmentTool:GetEnvironment() == EnvironmentTool.Environment.Edge
]=]
function EnvironmentTool.GetEnvironment(self: EnvironmentTool): Environment
	if self:IsProduction() then
		return self.Environment.Production
	elseif self:IsStable() then
		return self.Environment.Stable
	elseif self:IsEdge() then
		return self.Environment.Edge
	end
	return self.Environment.Local
end

export type EnvironmentTool = typeof(EnvironmentTool)

export type Environment = "Edge" | "Stable" | "Production" | "Local"

return EnvironmentTool
