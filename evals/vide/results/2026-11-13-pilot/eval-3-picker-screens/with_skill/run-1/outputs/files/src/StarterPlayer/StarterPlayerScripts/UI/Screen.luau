--!strict
--@author: Crusherfire
--@date: 2026-11-13
--[[@description:
	Live facts about the player's screen, as Vide sources: the UI scale, the
	viewport and usable area in UI units, and whether touch is the primary
	input. UI binds to these, so layout follows window resizes, rotation, and
	input changes during a session.

	UI is authored in offsets for a screen 1080 pixels tall. Larger screens
	grow it through Module.uiScale; smaller ones change layout instead.
]]

const GuiService = game:GetService("GuiService")
const RunService = game:GetService("RunService")
const UserInputService = game:GetService("UserInputService")

const Vide = require("@game/ReplicatedStorage/Packages/Vide")

const batch = Vide.batch
const source = Vide.source

const REFERENCE_SHORT_SIDE = 1080
const MINIMUM_SCALE = 1
const MAXIMUM_SCALE = 3
-- TVs are read from a couch, so they get more than their pixels alone give.
const LARGE_DISPLAY_BOOST = 1.25
-- In UI units. Phones held sideways are 360 to 440 tall; tablets start near 600.
const PHONE_SHORT_SIDE = 600
const FALLBACK_VIEWPORT = Vector2.new(1920, 1080)

local Module = {}

local realViewport = source(FALLBACK_VIEWPORT)
local realInset = source(Vector2.zero)
local prefersTouch = source(false)
local isLargeDisplay = source(false)
local viewportConnection: RBXScriptConnection? = nil

local function refresh()
	const camera = workspace.CurrentCamera
	const topLeftInset = GuiService:GetGuiInset()
	batch(function()
		-- ViewportSize reads (1, 1) before the first frame, which would pass
		-- for a tiny phone, so the fallback stays until a real size arrives.
		if camera and camera.ViewportSize.X > 1 and camera.ViewportSize.Y > 1 then
			realViewport(camera.ViewportSize)
		end
		realInset(topLeftInset)
		prefersTouch(UserInputService.PreferredInput == Enum.PreferredInput.Touch)
		isLargeDisplay(GuiService.ViewportDisplaySize == Enum.DisplaySize.Large)
	end)
end

-- Camera scripts can replace CurrentCamera, so the listener follows it.
local function watchCamera()
	if viewportConnection then
		viewportConnection:Disconnect()
	end
	const camera = workspace.CurrentCamera
	if camera then
		viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(refresh)
	end
	refresh()
end

--[[
	How much the whole UI grows on this screen: the short side over 1080,
	never below 1 or above 3. Bind it to a UIScale under every ScreenGui.
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
	The part of the viewport below the Roblox topbar, in UI units.
]]
function Module.usableSize(): Vector2
	const view = Module.viewport()
	return Vector2.new(view.X, view.Y - realInset().Y / Module.uiScale())
end

--[[
	Whether touch is the primary input, which is when Roblox shows its
	thumbstick and jump button.
]]
function Module.isTouch(): boolean
	return prefersTouch()
end

--[[
	Whether the screen is phone-sized, whatever the device.
]]
function Module.isPhone(): boolean
	const view = Module.viewport()
	return math.min(view.X, view.Y) < PHONE_SHORT_SIDE
end

--[[
	Whether UI should use its touch layout: the touch controls are up, or the
	screen is too small for the desktop layout.
]]
function Module.isTouchLayout(): boolean
	return prefersTouch() or Module.isPhone()
end

-- UI Labs loads a fresh copy of this module on every reload, and connections
-- made there would never be cleaned up, so edit mode reads the screen once.
if RunService:IsRunning() then
	watchCamera()
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
	GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(refresh)
	GuiService:GetPropertyChangedSignal("ViewportDisplaySize"):Connect(refresh)
	UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(refresh)
else
	refresh()
end

return Module
