--[[
	Live facts about the player's screen, as Vide sources, for every piece of UI to lay out from.
	The viewport, topbar inset, primary input, and display size class can all change mid-session
	(a window resize, a tablet rotating, a keyboard plugged in), so UI binds to these getters
	instead of reading the engine once.

	Sizes come in UI units: the offsets UI is authored in, for a screen 1080 pixels tall. Each
	getter reads sources, so pass it to a property as a binding or call it inside one.
]]

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Vide = require(ReplicatedStorage.Packages.Vide)

local batch = Vide.batch
local source = Vide.source

export type Band = {
	Left: number,
	Right: number,
}

local REFERENCE_SHORT_SIDE = 1080
local MINIMUM_SCALE = 1
local MAXIMUM_SCALE = 3
-- A TV is read from a couch, so it gets a quarter more than its pixel count asks for.
local LARGE_DISPLAY_BOOST = 1.25
local PHONE_SHORT_SIDE = 600
local FALLBACK_VIEWPORT = Vector2.new(1920, 1080)

-- Roblox's default touch controls, from the default PlayerModule. They are placed in real
-- pixels. The thumbstick starts wherever the left thumb lands in the left part of the screen.
local THUMBSTICK_REGION_WIDTH = 0.4
local SMALL_TOUCH_SHORT_SIDE = 500
local SMALL_JUMP_BUTTON_LEFT_FROM_RIGHT = 95
local LARGE_JUMP_BUTTON_LEFT_FROM_RIGHT = 170
local TOUCH_CONTROL_CLEARANCE = 8

local Module = {}

local realViewport = source(FALLBACK_VIEWPORT)
local realInset = source(Vector2.zero)
local prefersTouch = source(false)
local isLargeDisplay = source(false)
local viewportConnection: RBXScriptConnection? = nil

local function refresh()
	local camera = workspace.CurrentCamera
	local topLeftInset = GuiService:GetGuiInset()
	-- One batch, so a device switch reruns each binding once, with every fact
	-- already updated.
	batch(function()
		-- ViewportSize can read (1, 1) before the first frame, which would pass
		-- for a tiny phone, so the fallback stays until a real size arrives.
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
	How much the whole UI grows on this screen. GameScreenGui binds it to a
	UIScale; screens below 1080 tall keep 1 and change layout instead.
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
	Whether touch is the primary input, which is when Roblox shows its touch
	controls. A tablet with a keyboard connected reports false.
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
	The horizontal strip along the bottom of the screen that Roblox's touch
	controls leave free: right of the thumbstick region and left of the jump
	button. Edges are in UI units. Without touch controls the strip is the whole
	width.
]]
function Module.bottomBand(): Band
	local view = Module.viewport()
	if not prefersTouch() then
		return { Left = 0, Right = view.X }
	end

	local real = realViewport()
	local scale = Module.uiScale()
	local jumpLeftFromRight = if math.min(real.X, real.Y) <= SMALL_TOUCH_SHORT_SIDE
		then SMALL_JUMP_BUTTON_LEFT_FROM_RIGHT
		else LARGE_JUMP_BUTTON_LEFT_FROM_RIGHT
	local left = view.X * THUMBSTICK_REGION_WIDTH + TOUCH_CONTROL_CLEARANCE
	local right = view.X - jumpLeftFromRight / scale - TOUCH_CONTROL_CLEARANCE
	return { Left = left, Right = right }
end

-- Connect only in a running game: a story or spec loads a fresh copy of this
-- module on every reload, and each connection would keep its copy alive.
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
