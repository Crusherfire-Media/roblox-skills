--!strict
--@author: Crusherfire
--@date: 11/13/2026
--[[@description:
	Facts about the player's screen, as Vide sources, so UI follows a window
	resize, a device switch, or a change of primary input while it is up.
]]

const GuiService = game:GetService("GuiService")
const RunService = game:GetService("RunService")
const UserInputService = game:GetService("UserInputService")

const Vide = require("@game/ReplicatedStorage/Packages/Vide")

const batch = Vide.batch
const source = Vide.source

-- UI is authored for a screen 1080 pixels tall and grows on taller ones.
const REFERENCE_SHORT_SIDE = 1080
const MINIMUM_SCALE = 1
const MAXIMUM_SCALE = 3
const LARGE_DISPLAY_BOOST = 1.25
const FALLBACK_VIEWPORT = Vector2.new(1920, 1080)

local Module = {}

local realViewport = source(FALLBACK_VIEWPORT)
local prefersTouch = source(false)
local isLargeDisplay = source(false)
local viewportConnection: RBXScriptConnection? = nil

local function refresh()
	local camera = workspace.CurrentCamera
	batch(function()
		-- ViewportSize can read (1, 1) before the first frame, so the fallback
		-- stays until a real size arrives.
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
	const view = realViewport()
	const boost = if isLargeDisplay() then LARGE_DISPLAY_BOOST else 1
	return math.clamp(
		math.min(view.X, view.Y) / REFERENCE_SHORT_SIDE * boost,
		MINIMUM_SCALE,
		MAXIMUM_SCALE
	)
end

--[[
	Whether touch is the primary input, which is when Roblox shows its touch
	controls.
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
