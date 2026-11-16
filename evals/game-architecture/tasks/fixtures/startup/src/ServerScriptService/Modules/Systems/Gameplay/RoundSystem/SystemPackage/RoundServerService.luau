--[[
	Runs build rounds while anyone is in the server: an intermission, then a timed building round.
	Clients read the current phase from the RoundState and RoundEndsAt attributes on Workspace.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local ModuleLoader = require("@game/ReplicatedStorage/Packages/ModuleLoader")

local INTERMISSION_SECONDS = 15
local ROUND_SECONDS = 120

local RoundServerService = {}

local roundEnded = Instance.new("BindableEvent")

--[[
	Fires when a building round ends.
]]
RoundServerService.RoundEnded = roundEnded.Event

local function setState(state: string, seconds: number)
	Workspace:SetAttribute("RoundState", state)
	Workspace:SetAttribute("RoundEndsAt", Workspace:GetServerTimeNow() + seconds)
end

local function runRound()
	setState("Intermission", INTERMISSION_SECONDS)
	task.wait(INTERMISSION_SECONDS)
	setState("Building", ROUND_SECONDS)
	task.wait(ROUND_SECONDS)
	roundEnded:Fire()
end

function RoundServerService:Start()
	-- Every other system has to be running before the first round starts.
	while not ModuleLoader.IsServerLoaded() do
		task.wait()
	end

	while true do
		if #Players:GetPlayers() == 0 then
			Players.PlayerAdded:Wait()
		end
		runRound()
	end
end

return RoundServerService
