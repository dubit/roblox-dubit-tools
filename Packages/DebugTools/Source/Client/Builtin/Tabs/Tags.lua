--[[
	Responsible for rendering a components menu on the Debug Tool.
]]

local CollectionService = game:GetService("CollectionService")
local DebugToolRootPath = script.Parent.Parent.Parent

local Tab = require(DebugToolRootPath.Tab)
local IMGui = require(DebugToolRootPath.IMGui)

local Explorer = require(script.Parent.Explorer)

local Components = {}

Components.interface = {}
Components.internal = {
	ExpandedInstances = {},
}

function Components.internal.processTags(tag: string)
	local taggedInstances = CollectionService:GetTagged(tag)

	IMGui:Label(`<b>{tag}</b> / {#taggedInstances} in total`)

	if #taggedInstances == 0 then
		IMGui:Label("No instances")
	else
		for _, instance in CollectionService:GetTagged(tag) do
			local object = instance
			local ancestors = {}

			while object ~= nil or object == game do
				table.insert(ancestors, object)

				object = object.Parent
			end

			local flippedAncestors = {}

			for i = #ancestors, 1, -1 do
				table.insert(flippedAncestors, ancestors[i])
			end

			ancestors = flippedAncestors

			table.remove(flippedAncestors, 1)

			if Components.internal.ExpandedInstances[instance] == nil then
				Components.internal.ExpandedInstances[instance] = false
			end

			for index = 1, #ancestors do
				local ancestor = Components.internal.ExpandedInstances[instance] and flippedAncestors[index] or instance

				local arrowIcon = ancestor ~= instance and ""
					or Components.internal.ExpandedInstances[instance] and "http://www.roblox.com/asset/?id=111171269745562"
					or "http://www.roblox.com/asset/?id=110693549312858"
				local newDepth = Components.internal.ExpandedInstances[instance] and (index - 1) or 0

				if IMGui:TreeNode(Explorer.getSelectedObject() == ancestor).activated() then
					Explorer.setSelectedObject(ancestor)
				end

				IMGui:BeginGroup(UDim2.fromOffset(10 * newDepth, 0))
				IMGui:End()

				if IMGui:ImageButton(UDim2.fromOffset(12, 12), arrowIcon).activated() then
					if ancestor ~= instance then
						return
					end

					Components.internal.ExpandedInstances[instance] =
						not Components.internal.ExpandedInstances[instance]
				end

				IMGui:Label(ancestor.Name)

				IMGui:End()

				if not Components.internal.ExpandedInstances[instance] then
					break
				end
			end
		end
	end
end

Tab.new("Tags", function(parent: Frame)
	return IMGui:Connect(parent, function()
		IMGui:ScrollingFrameY(UDim2.fromScale(1, 1))

		for _, tag in CollectionService:GetAllTags() do
			Components.internal.processTags(tag)
		end

		IMGui:End()
	end)
end)

return nil
