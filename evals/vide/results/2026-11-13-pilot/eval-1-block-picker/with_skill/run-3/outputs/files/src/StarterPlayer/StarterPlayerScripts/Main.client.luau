--!strict
--@author: Crusherfire
--@date: 2026-11-13
--[[@description:
	Client entry point: mounts the HUD, then starts block placement.
]]

const Players = game:GetService("Players")
const RunService = game:GetService("RunService")

const Vide = require("@game/ReplicatedStorage/Packages/Vide")

const BlockPlacer = require("./BlockPlacer")
const headsUpDisplay = require("./UI/headsUpDisplay")

Vide.strict = RunService:IsStudio()

const localPlayer = Players.LocalPlayer
print(`client started for {localPlayer.Name}`)

const playerGui = localPlayer:WaitForChild("PlayerGui")
Vide.mount(headsUpDisplay, playerGui)

-- Yields until the server's remote exists, so it comes after the UI is up.
BlockPlacer.start()
