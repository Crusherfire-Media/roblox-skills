local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Vide = require("@game/ReplicatedStorage/Packages/Vide")

local BlockPlacer = require("./BlockPlacer")
local Hotbar = require("./Hotbar")

Vide.strict = RunService:IsStudio()

local localPlayer = Players.LocalPlayer
print(`client started for {localPlayer.Name}`)

Hotbar.mount(localPlayer:WaitForChild("PlayerGui"))
BlockPlacer.start()
