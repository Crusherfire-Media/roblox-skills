--[[
	Dev-only frame time overlay: shows the average and worst frame time over the last second in
	the top left corner, read from the MicroProfiler through LibMP. It keeps one live session open
	for as long as the client runs.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LibMP = require(script.Parent.LibMPLoader)

-- The overlay averages every frame the MicroProfiler holds, so 60 frames is the last second at
-- 60 FPS.
local FRAME_LIMIT = 60

local FpsOverlay = {}

FpsOverlay.FrameLimit = FRAME_LIMIT

local session: any = nil

function FpsOverlay.getSession(): any
	return session
end

function FpsOverlay.start()
	if session then
		return
	end
	LibMP.Control:EnableProfiler(true)
	LibMP.Control:SetFrameLimit(FRAME_LIMIT)
	LibMP.Control:EnableCapture(true)
	session = LibMP.Session.OpenFromLiveData()
	assert(session, "could not open the live MicroProfiler session")
	local tickToMs = session:FetchGlobalDesc().TickToMsCpu

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FpsOverlay"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 100

	local label = Instance.new("TextLabel")
	label.Position = UDim2.fromOffset(8, 8)
	label.Size = UDim2.fromOffset(220, 24)
	label.BackgroundTransparency = 0.4
	label.BackgroundColor3 = Color3.new(0, 0, 0)
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.Code
	label.TextSize = 14
	label.Parent = screenGui

	screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	RunService.Heartbeat:Connect(function()
		local total, worst, count = 0, 0, 0
		for frameId = session:GetFrameIdMin(), session:GetFrameIdMax() do
			local frame = session:FetchFrameDesc(frameId)
			if not frame.IsIncomplete then
				local ms = (frame.TickEndCpu - frame.TickStartCpu) * tickToMs
				total += ms
				worst = math.max(worst, ms)
				count += 1
			end
		end
		if count > 0 then
			label.Text = string.format("avg %.1f ms  worst %.1f ms", total / count, worst)
		end
	end)
end

return FpsOverlay
