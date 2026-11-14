--!strict

const Players = game:GetService("Players")
const RunService = game:GetService("RunService")

const Vide = require("@game/ReplicatedStorage/Packages/Vide")

const BlockPlacer = require("./BlockPlacer")
const hud = require("./Hud")

Vide.strict = RunService:IsStudio()

const localPlayer = Players.LocalPlayer
print(`client started for {localPlayer.Name}`)

const playerGui = localPlayer:WaitForChild("PlayerGui")
Vide.mount(hud, playerGui)

BlockPlacer.start()
