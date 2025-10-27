--[=[
    @type TimeZone { CentralAfricaTime: number, EastAfricaTime: number, WestAfricaTime: number, SouthAfricaStandardTime: number, MoroccoStandardTime: number, IndiaStandardTime: number, ChinaStandardTime: number, JapanStandardTime: number, KoreaStandardTime: number, CentralEuropeanTime: number, EasternEuropeanTime: number, BritishSummerTime: number, GreenwichMeanTime: number, EasternStandardTime: number, CentralStandardTime: number, MountainStandardTime: number, PacificStandardTime: number, AlaskaStandardTime: number, HawaiiAleutianStandardTime: number, AustralianEasternStandardTime: number, AustralianCentralStandardTime: number, AustralianWesternStandardTime: number, LordHoweStandardTime: number }
    @within EventTracker
]=]
--

return {
	-- Africa
	["CentralAfricaTime"] = (2 * 60 * 60),
	["EastAfricaTime"] = (3 * 60 * 60),
	["WestAfricaTime"] = (1 * 60 * 60),
	["SouthAfricaStandardTime"] = (2 * 60 * 60),

	-- Asia
	["IndiaStandardTime"] = (5.5 * 60 * 60),
	["ChinaStandardTime"] = (8 * 60 * 60),
	["JapanStandardTime"] = (9 * 60 * 60),
	["KoreaStandardTime"] = (9 * 60 * 60),

	-- Europe
	["CentralEuropeanTime"] = (1 * 60 * 60),
	["EasternEuropeanTime"] = (2 * 60 * 60),
	["BritishSummerTime"] = (1 * 60 * 60),
	["GreenwichMeanTime"] = (0 * 60 * 60),

	-- North America
	["EasternStandardTime"] = -(5 * 60 * 60),
	["CentralStandardTime"] = -(6 * 60 * 60),
	["MountainStandardTime"] = -(7 * 60 * 60),
	["PacificStandardTime"] = -(8 * 60 * 60),
	["AlaskaStandardTime"] = -(9 * 60 * 60),
	["HawaiiAleutianStandardTime"] = -(10 * 60 * 60),

	-- Oceania
	["AustralianEasternStandardTime"] = (10 * 60 * 60),
	["AustralianCentralStandardTime"] = (9.5 * 60 * 60),
	["AustralianWesternStandardTime"] = (8 * 60 * 60),
	["LordHoweStandardTime"] = (10.5 * 60 * 60),
}
