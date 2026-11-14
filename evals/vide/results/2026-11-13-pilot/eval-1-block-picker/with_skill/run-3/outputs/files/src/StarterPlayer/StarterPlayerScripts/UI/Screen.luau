--!strict
--@author: Crusherfire
--@date: 2026-11-13
--[[@description:
	Facts about the player's screen, as Vide sources: how much the whole UI
	grows, the viewport in UI units, and whether the touch layout applies.
	UI binds to these so it follows window resizes and device switches live.
]]

const GuiService = game:GetService("GuiService")
const RunService = game:GetService("RunService")
const UserInputService = game:GetService("UserInputService")

const Vide = require("@game/ReplicatedStorage/Packages/Vide")

const batch = Vide.batch
const source = Vide.source

-- UI sizes are authored for a screen this many pixels on its short side.
const REFERENCE_SHORT_SIDE = 1080
const MINIMUM_SCALE = 1
const MAXIMUM_SCALE = 3
-- TVs are read from a couch.
const LARGE_DISPLAY_BOOST = 1.25
-- In UI units. Phones held sideways are 360 to 440 tall, tablets start near 600.
const PHONE_SHORT_SIDE = 600
const FALLBACK_VIEWPORT = Vector2.new(1920, 1080)

local Module = {}

local realViewport = source(FALLBACK_VIEWPORT)
local prefersTouch = source(false)
local prefersKeyboard = source(true)
local isLargeDisplay = source(false)
local viewportConnection: RBXScriptConnection? = nil

local function refresh()
	local camera = workspace.CurrentCamera
	batch(function()
		-- ViewportSize can read (1, 1) before the first frame, which would
		-- pass for a tiny phone.
		if camera and camera.ViewportSize.X > 1 and camera.ViewportSize.Y > 1 then
			realViewport(camera.ViewportSize)
		end
		prefersTouch(UserInputService.PreferredInput == Enum.PreferredInput.Touch)
		prefersKeyboard(UserInputService.PreferredInput == Enum.PreferredInput.KeyboardAndMouse)
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
	How much the whole UI grows on this screen. Bind it to a UIScale under
	every ScreenGui the game builds.
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
	The viewport in UI units.
]]
function Module.viewport(): Vector2
	return realViewport() / Module.uiScale()
end

--[[
	Whether touch is the primary input, which is when Roblox shows its touch
	controls.
]]
function Module.isTouch(): boolean
	return prefersTouch()
end

--[[
	Whether keyboard and mouse is the primary input, so keyboard shortcuts are
	worth showing.
]]
function Module.isKeyboard(): boolean
	return prefersKeyboard()
end

function Module.isPhone(): boolean
	const view = Module.viewport()
	return math.min(view.X, view.Y) < PHONE_SHORT_SIDE
end

--[[
	Whether a HUD should use its touch layout: the touch controls are up, or
	the screen is too small for the desktop layout.
]]
function Module.isTouchLayout(): boolean
	return prefersTouch() or Module.isPhone()
end

-- Connections would outlive the fresh module copies that edit-mode tools load.
if RunService:IsRunning() then
	watchCamera()
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
	GuiService:GetPropertyChangedSignal("ViewportDisplaySize"):Connect(refresh)
	UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(refresh)
else
	refresh()
end

return Module
