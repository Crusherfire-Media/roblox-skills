const Players = game:GetService("Players")
const RunService = game:GetService("RunService")

const Vide = require("@game/ReplicatedStorage/Packages/Vide")

const BlockPlacer = require("./BlockPlacer")
const HotbarGui = require("./HotbarGui")

Vide.strict = RunService:IsStudio()

local localPlayer = Players.LocalPlayer
print(`client started for {localPlayer.Name}`)

local playerGui = localPlayer:WaitForChild("PlayerGui")
Vide.mount(HotbarGui, playerGui)

BlockPlacer.start()
