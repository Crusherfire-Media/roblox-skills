--!strict
--[[
	Facts about the player's screen, as Vide sources that follow the live
	device. UI binds to these getters instead of reading the camera or input
	service itself.
]]

local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Vide = require("@game/ReplicatedStorage/Packages/Vide")

local batch = Vide.batch
local source = Vide.source

local REFERENCE_SHORT_SIDE = 1080
local MINIMUM_SCALE = 1
local MAXIMUM_SCALE = 3
local LARGE_DISPLAY_BOOST = 1.25
local FALLBACK_VIEWPORT = Vector2.new(1920, 1080)

local Module = {}

local realViewport = source(FALLBACK_VIEWPORT)
local prefersTouch = source(false)
local isLargeDisplay = source(false)
local viewportConnection: RBXScriptConnection? = nil

local function refresh()
	local camera = workspace.CurrentCamera
	batch(function()
		-- ViewportSize can read (1, 1) before the first frame, which would pass
		-- for a tiny phone, so the fallback stays until a real size arrives.
		if camera and camera.ViewportSize.X > 1 and camera.ViewportSize.Y > 1 then
			realViewport(camera.ViewportSize)
		end
		prefersTouch(UserInputService.PreferredInput == Enum.PreferredInput.Touch)
		isLargeDisplay(GuiService.ViewportDisplaySize == Enum.DisplaySize.Large)
	end)
end

local function watchCamera()
	if viewportConnection then
		viewportConnection:Disconnect()
	end
	local camera = workspace.CurrentCamera
	if camera then
		viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(refresh)
	end
	refresh()
end

--[[
	How much the whole UI grows on this screen. Bind it to a UIScale directly
	under every ScreenGui the game builds.
]]
function Module.uiScale(): number
	local view = realViewport()
	local boost = if isLargeDisplay() then LARGE_DISPLAY_BOOST else 1
	return math.clamp(
		math.min(view.X, view.Y) / REFERENCE_SHORT_SIDE * boost,
		MINIMUM_SCALE,
		MAXIMUM_SCALE
	)
end

--[[
	Whether touch is the primary input, which is when Roblox shows its touch
	controls and keyboard hints mean nothing to the player.
]]
function Module.isTouch(): boolean
	return prefersTouch()
end

if RunService:IsRunning() then
	watchCamera()
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
	GuiService:GetPropertyChangedSignal("ViewportDisplaySize"):Connect(refresh)
	UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(refresh)
else
	refresh()
end

return Module
