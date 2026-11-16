--!strict
--@author: Crusherfire
--@date: 2026-11-13
--[[@description:
	The facts about the player's screen that UI lays out from: viewport size,
	topbar inset, whether touch controls are up, and the TV size class. Each
	getter reads Vide sources, so bind it to a property or call it inside a
	binding and the UI follows the live screen as the window resizes, a
	tablet rotates, or a keyboard is plugged in.

	UI is authored for a screen 1080 tall, in offsets. Larger screens grow
	it with one UIScale per ScreenGui (gameScreenGui adds it), and smaller
	screens change layout instead of shrinking.
]]

const GuiService = game:GetService("GuiService")
const RunService = game:GetService("RunService")
const UserInputService = game:GetService("UserInputService")

const Vide = require("@game/ReplicatedStorage/Packages/Vide")

const batch = Vide.batch
const source = Vide.source

export type SimulatedScreen = {
	Size: Vector2,
	Inset: Vector2?,
	IsTouch: boolean?,
	IsLargeDisplay: boolean?,
}

const REFERENCE_SHORT_SIDE = 1080
const MINIMUM_SCALE = 1
const MAXIMUM_SCALE = 3
-- A TV is read from a couch.
const LARGE_DISPLAY_BOOST = 1.25
-- Phones held sideways are 360 to 440 tall; tablets start near 600.
const PHONE_SHORT_SIDE = 600
const FALLBACK_VIEWPORT = Vector2.new(1920, 1080)

local Module = {}

local realViewport = source(FALLBACK_VIEWPORT)
local realInset = source(Vector2.zero)
local prefersTouch = source(false)
local isLargeDisplay = source(false)
local isSimulating = false
local viewportConnection: RBXScriptConnection? = nil

local function refresh()
	if isSimulating then
		return
	end

	local camera = workspace.CurrentCamera
	local topLeftInset = GuiService:GetGuiInset()
	-- One batch, so a device switch reruns each binding once, with every fact
	-- already updated.
	batch(function()
		-- ViewportSize can read (1, 1) before the first frame, which would pass
		-- for a tiny phone.
		if camera and camera.ViewportSize.X > 1 and camera.ViewportSize.Y > 1 then
			realViewport(camera.ViewportSize)
		end
		realInset(topLeftInset)
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
	How much the whole UI grows on this screen: the short side over 1080,
	never below 1. Bind it to a UIScale under every ScreenGui the game builds.
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
	The viewport in UI units.
]]
function Module.viewport(): Vector2
	return realViewport() / Module.uiScale()
end

--[[
	The part of the viewport below the Roblox topbar, in UI units.
]]
function Module.usableSize(): Vector2
	local view = Module.viewport()
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
	Whether the screen is phone sized: a short side under 600 UI units. A
	desktop window dragged that small counts too.
]]
function Module.isPhone(): boolean
	local view = Module.viewport()
	return math.min(view.X, view.Y) < PHONE_SHORT_SIDE
end

--[[
	Whether UI should use its touch layout: the touch controls are up, or the
	screen is too small for the desktop layout.
]]
function Module.isTouchLayout(): boolean
	return prefersTouch() or Module.isPhone()
end

--[[
	Replaces the live readings with the given screen, for a story or a spec.
	Pass nil to go back to them.
]]
function Module:Simulate(screen: SimulatedScreen?)
	isSimulating = screen ~= nil
	if not screen then
		refresh()
		return
	end

	batch(function()
		realViewport(screen.Size)
		realInset(screen.Inset or Vector2.zero)
		prefersTouch(screen.IsTouch == true)
		isLargeDisplay(screen.IsLargeDisplay == true)
	end)
end

-- UI Labs loads a fresh copy of this module on every reload, and a connection
-- made in edit mode would keep each copy in memory.
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
