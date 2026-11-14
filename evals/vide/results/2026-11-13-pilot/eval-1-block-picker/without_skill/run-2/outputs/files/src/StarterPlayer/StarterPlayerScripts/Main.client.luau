local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)
local BlockPlacer = require(script.Parent.BlockPlacer)
local Hotbar = require(script.Parent.Hotbar)

local localPlayer = Players.LocalPlayer
print(`client started for {localPlayer.Name}`)

-- Mount UI before starting BlockPlacer, since start() yields until the server's remote exists.
local playerGui = localPlayer:WaitForChild("PlayerGui")
Vide.mount(Hotbar, playerGui)

BlockPlacer.start()
