local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BlockHud = require(script.Parent.BlockHud)
local BlockPlacer = require(script.Parent.BlockPlacer)
local Vide = require(ReplicatedStorage.Packages.Vide)

Vide.strict = RunService:IsStudio()

local localPlayer = Players.LocalPlayer
print(`client started for {localPlayer.Name}`)

local playerGui = localPlayer:WaitForChild("PlayerGui")
Vide.mount(BlockHud.new, playerGui)

BlockPlacer.start()
