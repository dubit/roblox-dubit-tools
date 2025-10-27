return function()
	local checkGuiVisibility = require(script.Parent.checkGuiVisibility)

	it("should return true for visible GuiObject", function()
		local guiObject = Instance.new("Frame")
		guiObject.Visible = true
		expect(checkGuiVisibility(guiObject)).to.equal(true)
	end)

	it("should return false for invisible GuiObject", function()
		local guiObject = Instance.new("Frame")
		guiObject.Visible = false
		expect(checkGuiVisibility(guiObject)).to.equal(false)
	end)

	it("should return true for enabled LayerCollector", function()
		local layerCollector = Instance.new("ScreenGui")
		layerCollector.Enabled = true
		expect(checkGuiVisibility(layerCollector)).to.equal(true)
	end)

	it("should return false for disabled LayerCollector", function()
		local layerCollector = Instance.new("ScreenGui")
		layerCollector.Enabled = false
		expect(checkGuiVisibility(layerCollector)).to.equal(false)
	end)

	it("should check visibility of parent objects", function()
		local parent = Instance.new("Frame")
		local child = Instance.new("Frame")
		child.Parent = parent

		parent.Visible = true
		child.Visible = true
		expect(checkGuiVisibility(child)).to.equal(true)

		parent.Visible = false
		child.Visible = true
		expect(checkGuiVisibility(child)).to.equal(false)

		parent.Visible = true
		child.Visible = false
		expect(checkGuiVisibility(child)).to.equal(false)
	end)

	it("should check mixed GuiObject and LayerCollector hierarchy", function()
		local screenGui = Instance.new("ScreenGui")
		local frame = Instance.new("Frame")
		frame.Parent = screenGui

		screenGui.Enabled = true
		frame.Visible = true
		expect(checkGuiVisibility(frame)).to.equal(true)

		screenGui.Enabled = false
		frame.Visible = true
		expect(checkGuiVisibility(frame)).to.equal(false)

		screenGui.Enabled = true
		frame.Visible = false
		expect(checkGuiVisibility(frame)).to.equal(false)
	end)
end
