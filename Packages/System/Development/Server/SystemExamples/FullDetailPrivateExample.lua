local FullDetailPrivateExample = {
	Public = {
		Name = "FullDetailPrivateExample",
		Priority = 6,
		Icon = "👽",
	},
	Private = {},
}

function FullDetailPrivateExample.Private:PrivateExamplePrint()
	print("FullDetailPrivateExample:PrivateExamplePrint()")
end

function FullDetailPrivateExample.Public:Init()
	print("FullDetailPrivateExample:Init()")
	FullDetailPrivateExample.Private:PrivateExamplePrint()
end

return FullDetailPrivateExample.Public
