return function()
	local DataKeyInfoObject = require(script.Parent)

	describe("keyInfo should report accurate information", function()
		local keyInfo

		beforeAll(function()
			keyInfo = DataKeyInfoObject.new(0)
		end)

		it("Should report valid user Id entries", function()
			local newKeyInfo = DataKeyInfoObject.from(keyInfo, 0, { 1 })
			local keyUserIds = newKeyInfo:GetUserIds()

			expect(keyUserIds[1]).to.equal(1)
			expect(#keyUserIds).to.equal(1)
		end)

		it("Should report valid metadata entries", function()
			local newKeyInfo = DataKeyInfoObject.from(keyInfo, 0, {}, { test = 123 })
			local keyMetadata = newKeyInfo:GetMetadata()

			expect(keyMetadata.test).to.equal(123)
		end)

		it("Should upgrade key info version", function()
			local newKeyInfo = DataKeyInfoObject.from(keyInfo, 1)

			expect(newKeyInfo.Version).to.equal(1)
		end)

		it("Should initiate the object with dateTime now", function()
			local dateTime = DateTime.now()
			local newKeyInfo = DataKeyInfoObject.from(keyInfo, 1)

			expect(newKeyInfo.CreatedTime).to.near(dateTime.UnixTimestampMillis, 5)
			expect(newKeyInfo.UpdatedTime).to.near(dateTime.UnixTimestampMillis, 5)
		end)
	end)
end
