return function(DebugTools)
	DebugTools.Tab.new("IMGui Test", function(parent: Frame)
		local boolean: boolean = true
		local counter: number = 0

		local imGuiCleanup = DebugTools.IMGui:Connect(parent, function()
			DebugTools.IMGui:BeginHorizontal()

			DebugTools.IMGui:BeginGroup(UDim2.fromScale(0.50, 1.00))
			DebugTools.IMGui:BeginVertical()
			DebugTools.IMGui:Label("Hello")

			if DebugTools.IMGui:Button(`Counter: {counter}`).activated() then
				counter += 1
			end

			DebugTools.IMGui:BeginHorizontal()
			DebugTools.IMGui:Label("Inline!")
			DebugTools.IMGui:Button("One Button")
			if DebugTools.IMGui:Button("Second Button").hovered() then
				DebugTools.IMGui:Label("Hovering")
			end
			DebugTools.IMGui:End()

			if DebugTools.IMGui:Checkbox("Hello Checkbox", boolean).activated() then
				boolean = not boolean
			end

			if DebugTools.IMGui:Checkbox("Hello Checkbox Reverse", not boolean).activated() then
				boolean = not boolean
			end

			DebugTools.IMGui:End()
			DebugTools.IMGui:End()

			DebugTools.IMGui:BeginGroup(UDim2.fromScale(0.50, 1.00))
			DebugTools.IMGui:BeginVertical()
			DebugTools.IMGui:Label("Hello")

			if DebugTools.IMGui:Button("Hello").activated() then
				print("Press!")
			end

			DebugTools.IMGui:BeginHorizontal()
			DebugTools.IMGui:Label("Inline!")
			DebugTools.IMGui:Button("One Button")
			DebugTools.IMGui:Button("Second Button")
			DebugTools.IMGui:End()

			if DebugTools.IMGui:Checkbox("Hello Checkbox", boolean).activated() then
				boolean = not boolean
			end

			if DebugTools.IMGui:Checkbox("Hello Checkbox Reverse", not boolean).activated() then
				boolean = not boolean
			end

			DebugTools.IMGui:End()
			DebugTools.IMGui:End()

			DebugTools.IMGui:End()
		end)

		return function()
			imGuiCleanup()
		end
	end)
end
