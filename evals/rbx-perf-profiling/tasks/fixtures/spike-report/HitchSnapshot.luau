--[[
	Dev-only hitch catcher, started by the debug panel during playtests. When a frame takes longer
	than HITCH_MS, it waits a few frames so the MicroProfiler still holds the frames around the
	hitch, then saves them to slot 2, which survives the switch back to Edit mode in Studio.
]]

local RunService = game:GetService("RunService")

local LibMP = require(script.Parent.LibMPLoader)

local HITCH_MS = 50
local FRAMES_AFTER_HITCH = 10
local SNAPSHOT_SLOT = 2

local HitchSnapshot = {}

local connection: RBXScriptConnection? = nil

function HitchSnapshot.start()
	if connection then
		return
	end
	LibMP.Control:EnableProfiler(true)
	LibMP.Control:EnableCapture(true)

	local framesUntilSnapshot: number? = nil
	connection = RunService.Heartbeat:Connect(function(deltaTime: number)
		if framesUntilSnapshot then
			framesUntilSnapshot -= 1
			if framesUntilSnapshot <= 0 then
				framesUntilSnapshot = nil
				LibMP.Control:CaptureToSlotSync(SNAPSHOT_SLOT)
				print(`HitchSnapshot: saved the MicroProfiler frames to slot {SNAPSHOT_SLOT}`)
			end
		elseif deltaTime * 1000 > HITCH_MS then
			framesUntilSnapshot = FRAMES_AFTER_HITCH
		end
	end)
end

function HitchSnapshot.stop()
	if connection then
		connection:Disconnect()
		connection = nil
	end
end

return HitchSnapshot
