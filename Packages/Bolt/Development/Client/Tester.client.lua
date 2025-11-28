local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Bolt = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Bolt"))

local string = ""
string ..= HttpService:GenerateGUID(false)
string ..= HttpService:GenerateGUID(false)
string ..= HttpService:GenerateGUID(false)
string ..= HttpService:GenerateGUID(false)

Bolt.ReliableEvent("Hello"):FireServer(string) -- Should be using u16

local string127 = string.rep("a", 127)
Bolt.ReliableEvent("Hello"):FireServer(string127) -- Should be using u8

string127 ..= "!"
Bolt.ReliableEvent("Hello"):FireServer(string127) -- Should be using u16
