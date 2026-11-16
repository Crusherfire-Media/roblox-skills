local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)

local BlockPlacer = require(script.Parent.BlockPlacer)
local Hotbar = require(script.Parent.Hotbar)

local localPlayer = Players.LocalPlayer
print(`client started for {localPlayer.Name}`)

-- Mount the UI first: BlockPlacer.start() yields until the server's remote exists.
Vide.mount(Hotbar, localPlayer:WaitForChild("PlayerGui"))

BlockPlacer.start()
