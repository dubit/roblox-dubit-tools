return function()
	local Serialisation = require(script.Parent)

	describe("should be able to serialise input values", function()
		it("serialise 'Axes' datatype", function()
			local success, value = Serialisation:Serialise(Axes.new(Enum.NormalId.Front))

			expect(success).to.equal(true)
			expect(value).to.be.a("table")
			expect(value.objectType).to.equal("Axes")
			expect(value.normalIds[1]).to.equal("Back")
			expect(value.normalIds[2]).to.equal("Front")
		end)

		it("serialise 'BrickColor' datatype", function()
			local success, value = Serialisation:Serialise(BrickColor.Red())

			expect(success).to.equal(true)
			expect(value).to.be.a("table")
			expect(value.objectType).to.equal("BrickColor")
			expect(value.name).to.equal("Bright red")
		end)

		it("serialise 'CFrame' datatype", function()
			local success, value = Serialisation:Serialise(CFrame.new())

			expect(success).to.equal(true)
			expect(value).to.be.a("table")
			expect(value.objectType).to.equal("CFrame")
			expect(#value.components).to.equal(12)
		end)

		it("serialise 'Color' datatype", function()
			local success, value = Serialisation:Serialise(Color3.new(1, 0, 1))

			expect(success).to.equal(true)
			expect(value).to.be.a("table")
			expect(value.objectType).to.equal("Color3")
			expect(value.r).to.equal(1)
			expect(value.g).to.equal(0)
			expect(value.b).to.equal(1)
		end)

		it("serialise 'ColorSequence' datatype", function()
			local success, value = Serialisation:Serialise(ColorSequence.new(Color3.new(1, 1, 1)))

			expect(success).to.equal(true)
			expect(value).to.be.a("table")
			expect(value.objectType).to.equal("ColorSequence")

			expect(value.keypoints[1].time).to.equal(0)
			expect(value.keypoints[1].color.r).to.equal(1)
			expect(value.keypoints[1].color.g).to.equal(1)
			expect(value.keypoints[1].color.b).to.equal(1)

			expect(value.keypoints[2].time).to.equal(1)
			expect(value.keypoints[2].color.r).to.equal(1)
			expect(value.keypoints[2].color.g).to.equal(1)
			expect(value.keypoints[2].color.b).to.equal(1)
		end)

		it("serialise 'DateTime' datatype", function()
			local dateTime = DateTime.now()
			local success, value = Serialisation:Serialise(dateTime)

			expect(success).to.equal(true)
			expect(value).to.be.a("table")
			expect(value.objectType).to.equal("DateTime")
			expect(value.iso).to.equal(dateTime:ToIsoDate())
		end)

		it("serialise 'Faces' datatype", function()
			local success, value = Serialisation:Serialise(Faces.new(Enum.NormalId.Front))

			expect(success).to.equal(true)
			expect(value).to.be.a("table")
			expect(value.objectType).to.equal("Faces")
			expect(value.normalIds[1]).to.equal("Front")
		end)

		it("serialise 'FloatCurveKey' datatype", function()
			local success, value = Serialisation:Serialise(FloatCurveKey.new(0.5, 1, Enum.KeyInterpolationMode.Linear))

			expect(success).to.equal(true)
			expect(value).to.be.a("table")
			expect(value.objectType).to.equal("FloatCurveKey")
			expect(value.time).to.equal(0.5)
			expect(value.value).to.equal(1)
			expect(value.interpolation).to.equal("Linear")
		end)

		it("serialise 'NumberRange' datatype", function()
			local success, value = Serialisation:Serialise(NumberRange.new(3, 8))

			expect(success).to.equal(true)
			expect(value).to.be.a("table")
			expect(value.objectType).to.equal("NumberRange")
			expect(value.min).to.equal(3)
			expect(value.max).to.equal(8)
		end)

		it("serialise 'NumberSequence' datatype", function()
			local success, value = Serialisation:Serialise(NumberSequence.new(5))

			expect(success).to.equal(true)
			expect(value).to.be.a("table")
			expect(value.objectType).to.equal("NumberSequence")

			expect(value.keypoints[1].envelope).to.equal(0)
			expect(value.keypoints[1].time).to.equal(0)
			expect(value.keypoints[1].value).to.equal(5)

			expect(value.keypoints[2].envelope).to.equal(0)
			expect(value.keypoints[2].time).to.equal(1)
			expect(value.keypoints[2].value).to.equal(5)
		end)

		it("serialise 'PhysicalProperties' datatype", function()
			local success, value = Serialisation:Serialise(PhysicalProperties.new(Enum.Material.Plastic))

			expect(success).to.equal(true)
			expect(value).to.be.a("table")
			expect(value.objectType).to.equal("PhysicalProperties")

			expect(value.density).to.near(0.7, 2)
			expect(value.elasticity).to.equal(0.5)
			expect(value.elasticityWeight).to.equal(1)
			expect(value.friction).to.near(0.3, 2)
			expect(value.frictionWeight).to.equal(1)
		end)

		it("serialise 'Ray' datatype", function()
			local success, value = Serialisation:Serialise(Ray.new(Vector3.new(0, 0, 0), Vector3.new(0, 0, 0)))

			expect(success).to.equal(true)
			expect(value).to.be.a("table")
			expect(value.objectType).to.equal("Ray")

			expect(value.origin.x).to.equal(0)
			expect(value.origin.y).to.equal(0)
			expect(value.origin.z).to.equal(0)

			expect(value.direction.x).to.equal(0)
			expect(value.direction.y).to.equal(0)
			expect(value.direction.z).to.equal(0)
		end)

		it("serialise 'Rect' datatype", function()
			local success, value = Serialisation:Serialise(Rect.new(Vector2.new(0, 0), Vector2.new(0, 0)))

			expect(success).to.equal(true)
			expect(value).to.be.a("table")
			expect(value.objectType).to.equal("Rect")

			expect(value.min.x).to.equal(0)
			expect(value.min.y).to.equal(0)

			expect(value.max.x).to.equal(0)
			expect(value.max.y).to.equal(0)
		end)

		it("serialise 'Region3' datatype", function()
			local success, value = Serialisation:Serialise(Region3.new(Vector3.new(0, 1, 0), Vector3.new(0, 1, 0)))

			expect(success).to.equal(true)
			expect(value).to.be.a("table")
			expect(value.objectType).to.equal("Region3")

			expect(value.topCorner.x).to.equal(0)
			expect(value.topCorner.y).to.equal(1)
			expect(value.topCorner.z).to.equal(0)

			expect(value.bottomCorner.x).to.equal(0)
			expect(value.bottomCorner.y).to.equal(1)
			expect(value.bottomCorner.z).to.equal(0)
		end)

		it("serialise 'TweenInfo' datatype", function()
			local success, value = Serialisation:Serialise(
				TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.In, 0, false, 0)
			)

			expect(success).to.equal(true)
			expect(value).to.be.a("table")
			expect(value.objectType).to.equal("TweenInfo")

			expect(value.time).to.equal(1)
			expect(value.easingStyle).to.equal(Enum.EasingStyle.Exponential.Value)
			expect(value.easingDirection).to.equal(Enum.EasingDirection.In.Value)
			expect(value.repeatCount).to.equal(0)
			expect(value.reverses).to.equal(false)
			expect(value.delayTime).to.equal(0)
		end)

		it("serialise 'UDim2' datatype", function()
			local success, value = Serialisation:Serialise(UDim2.fromOffset(0, 0))

			expect(success).to.equal(true)
			expect(value).to.be.a("table")
			expect(value.objectType).to.equal("UDim2")

			expect(value.xScale).to.equal(0)
			expect(value.xOffset).to.equal(0)
			expect(value.yScale).to.equal(0)
			expect(value.yOffset).to.equal(0)
		end)

		it("serialise 'UDim' datatype", function()
			local success, value = Serialisation:Serialise(UDim.new(0, 0))

			expect(success).to.equal(true)
			expect(value).to.be.a("table")
			expect(value.objectType).to.equal("UDim")

			expect(value.scale).to.equal(0)
			expect(value.offset).to.equal(0)
		end)

		it("serialise 'Vector3' datatype", function()
			local success, value = Serialisation:Serialise(Vector3.new(0, 1, 0))

			expect(success).to.equal(true)
			expect(value).to.be.a("table")
			expect(value.objectType).to.equal("Vector3")

			expect(value.x).to.equal(0)
			expect(value.y).to.equal(1)
			expect(value.z).to.equal(0)
		end)

		it("serialise 'Vector2' datatype", function()
			local success, value = Serialisation:Serialise(Vector2.new(0, 0))

			expect(success).to.equal(true)
			expect(value).to.be.a("table")
			expect(value.objectType).to.equal("Vector2")

			expect(value.x).to.equal(0)
			expect(value.y).to.equal(0)
		end)
	end)

	describe("should be able to deserialise input values", function()
		it("deserialise 'Axes' datatype", function()
			local success, value = Serialisation:Serialise(Axes.new(Enum.NormalId.Front))

			expect(success).to.equal(true)
			expect(value).to.be.a("table")

			success, value = Serialisation:Deserialise(value)

			expect(success).to.equal(true)
			expect(typeof(value)).to.equal("Axes")
		end)

		it("deserialise 'BrickColor' datatype", function()
			local success, value = Serialisation:Serialise(BrickColor.Red())

			expect(success).to.equal(true)
			expect(value).to.be.a("table")

			success, value = Serialisation:Deserialise(value)

			expect(success).to.equal(true)
			expect(typeof(value)).to.equal("BrickColor")
		end)

		it("deserialise 'CFrame' datatype", function()
			local success, value = Serialisation:Serialise(CFrame.new())

			expect(success).to.equal(true)
			expect(value).to.be.a("table")

			success, value = Serialisation:Deserialise(value)

			expect(success).to.equal(true)
			expect(typeof(value)).to.equal("CFrame")
		end)

		it("deserialise 'Color3' datatype", function()
			local success, value = Serialisation:Serialise(Color3.new(1, 0, 1))

			expect(success).to.equal(true)
			expect(value).to.be.a("table")

			success, value = Serialisation:Deserialise(value)

			expect(success).to.equal(true)
			expect(typeof(value)).to.equal("Color3")
		end)

		it("deserialise 'ColorSequence' datatype", function()
			local success, value = Serialisation:Serialise(ColorSequence.new(Color3.new(1, 1, 1)))

			expect(success).to.equal(true)
			expect(value).to.be.a("table")

			success, value = Serialisation:Deserialise(value)

			expect(success).to.equal(true)
			expect(typeof(value)).to.equal("ColorSequence")
		end)

		it("deserialise 'DateTime' datatype", function()
			local dateTime = DateTime.now()
			local success, value = Serialisation:Serialise(dateTime)

			expect(success).to.equal(true)
			expect(value).to.be.a("table")

			success, value = Serialisation:Deserialise(value)

			expect(success).to.equal(true)
			expect(typeof(value)).to.equal("DateTime")
		end)

		it("deserialise 'Faces' datatype", function()
			local success, value = Serialisation:Serialise(Faces.new(Enum.NormalId.Front))

			expect(success).to.equal(true)
			expect(value).to.be.a("table")

			success, value = Serialisation:Deserialise(value)

			expect(success).to.equal(true)
			expect(typeof(value)).to.equal("Faces")
		end)

		it("deserialise 'FloatCurveKey' datatype", function()
			local success, value = Serialisation:Serialise(FloatCurveKey.new(0.5, 1, Enum.KeyInterpolationMode.Linear))

			expect(success).to.equal(true)
			expect(value).to.be.a("table")

			success, value = Serialisation:Deserialise(value)

			expect(success).to.equal(true)
			expect(typeof(value)).to.equal("FloatCurveKey")
		end)

		it("deserialise 'NumberRange' datatype", function()
			local success, value = Serialisation:Serialise(NumberRange.new(3, 8))

			expect(success).to.equal(true)
			expect(value).to.be.a("table")

			success, value = Serialisation:Deserialise(value)

			expect(success).to.equal(true)
			expect(typeof(value)).to.equal("NumberRange")
		end)

		it("deserialise 'NumberSequence' datatype", function()
			local success, value = Serialisation:Serialise(NumberSequence.new(5))

			expect(success).to.equal(true)
			expect(value).to.be.a("table")

			success, value = Serialisation:Deserialise(value)

			expect(success).to.equal(true)
			expect(typeof(value)).to.equal("NumberSequence")
		end)

		it("deserialise 'PhysicalProperties' datatype", function()
			local success, value = Serialisation:Serialise(PhysicalProperties.new(Enum.Material.Plastic))

			expect(success).to.equal(true)
			expect(value).to.be.a("table")

			success, value = Serialisation:Deserialise(value)

			expect(success).to.equal(true)
			expect(typeof(value)).to.equal("PhysicalProperties")
		end)

		it("deserialise 'Ray' datatype", function()
			local success, value = Serialisation:Serialise(Ray.new(Vector3.new(0, 0, 0), Vector3.new(0, 0, 0)))

			expect(success).to.equal(true)
			expect(value).to.be.a("table")

			success, value = Serialisation:Deserialise(value)

			expect(success).to.equal(true)
			expect(typeof(value)).to.equal("Ray")
		end)

		it("deserialise 'Rect' datatype", function()
			local success, value = Serialisation:Serialise(Rect.new(Vector2.new(0, 0), Vector2.new(0, 0)))

			expect(success).to.equal(true)
			expect(value).to.be.a("table")

			success, value = Serialisation:Deserialise(value)

			expect(success).to.equal(true)
			expect(typeof(value)).to.equal("Rect")
		end)

		it("deserialise 'Region3' datatype", function()
			local success, value = Serialisation:Serialise(Region3.new(Vector3.new(0, 1, 0), Vector3.new(0, 1, 0)))

			expect(success).to.equal(true)
			expect(value).to.be.a("table")

			success, value = Serialisation:Deserialise(value)

			expect(success).to.equal(true)
			expect(typeof(value)).to.equal("Region3")
		end)

		it("deserialise 'TweenInfo' datatype", function()
			local success, value = Serialisation:Serialise(
				TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.In, 0, false, 0)
			)

			expect(success).to.equal(true)
			expect(value).to.be.a("table")

			success, value = Serialisation:Deserialise(value)

			expect(success).to.equal(true)
			expect(typeof(value)).to.equal("TweenInfo")
		end)

		it("deserialise 'UDim2' datatype", function()
			local success, value = Serialisation:Serialise(UDim2.fromOffset(0, 0))

			expect(success).to.equal(true)
			expect(value).to.be.a("table")

			success, value = Serialisation:Deserialise(value)

			expect(success).to.equal(true)
			expect(typeof(value)).to.equal("UDim2")
		end)

		it("deserialise 'UDim' datatype", function()
			local success, value = Serialisation:Serialise(UDim.new(0, 0))

			expect(success).to.equal(true)
			expect(value).to.be.a("table")

			success, value = Serialisation:Deserialise(value)

			expect(success).to.equal(true)
			expect(typeof(value)).to.equal("UDim2")
		end)

		it("deserialise 'Vector3' datatype", function()
			local success, value = Serialisation:Serialise(Vector3.new(0, 1, 0))

			expect(success).to.equal(true)
			expect(value).to.be.a("table")

			success, value = Serialisation:Deserialise(value)

			expect(success).to.equal(true)
			expect(typeof(value)).to.equal("Vector3")
		end)

		it("deserialise 'Vector2' datatype", function()
			local success, value = Serialisation:Serialise(Vector2.new(0, 0))

			expect(success).to.equal(true)
			expect(value).to.be.a("table")

			success, value = Serialisation:Deserialise(value)

			expect(success).to.equal(true)
			expect(typeof(value)).to.equal("Vector2")
		end)
	end)
end
