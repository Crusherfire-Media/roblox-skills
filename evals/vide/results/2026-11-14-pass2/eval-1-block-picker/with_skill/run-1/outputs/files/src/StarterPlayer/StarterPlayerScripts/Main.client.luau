--!strict

const Players = game:GetService("Players")
const RunService = game:GetService("RunService")

const Vide = require("@game/ReplicatedStorage/Packages/Vide")

const BlockPlacer = require("./BlockPlacer")
const HotbarScreen = require("./HotbarScreen")

Vide.strict = RunService:IsStudio()

const localPlayer = Players.LocalPlayer
print(`client started for {localPlayer.Name}`)

HotbarScreen.mount(localPlayer:WaitForChild("PlayerGui"))
-- Yields until the server's remote exists, so it goes after the UI.
BlockPlacer.start()
