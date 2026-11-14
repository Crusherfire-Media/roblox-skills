--!strict
--[[
	Live facts about the player's screen, as Vide sources, shared by every
	screen of UI. Sizes are in UI units: the offsets UI is authored in, for a
	screen 1080 pixels tall. Build ScreenGuis with scaledScreenGui so those
	units grow on larger screens.
]]

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Vide = require(ReplicatedStorage.Packages.Vide)

local batch = Vide.batch
local source = Vide.source

local REFERENCE_SHORT_SIDE = 1080
local MINIMUM_SCALE = 1
local MAXIMUM_SCALE = 3
local LARGE_DISPLAY_BOOST = 1.25
local PHONE_SHORT_SIDE = 600
local FALLBACK_VIEWPORT = Vector2.new(1920, 1080)

-- Where the default PlayerModule puts its touch controls, in real pixels: the
-- dynamic thumbstick can start anywhere in the left 40 percent, and the jump
-- button's left edge sits this far from the right edge.
local THUMBSTICK_WIDTH_SHARE = 0.4
local SMALL_TOUCH_SHORT_SIDE = 500
local SMALL_JUMP_LEFT_FROM_RIGHT = 95
local LARGE_JUMP_LEFT_FROM_RIGHT = 170

export type Span = {
	Left: number,
	Right: number,
}

local Screen = {}

local realViewport = source(FALLBACK_VIEWPORT)
local realInset = source(Vector2.zero)
local prefersTouch = source(false)
local isLargeDisplay = source(false)
local viewportConnection: RBXScriptConnection? = nil

local function refresh()
	local camera = workspace.CurrentCamera
	local topLeftInset = GuiService:GetGuiInset()
	batch(function()
		-- ViewportSize reads (1, 1) before the first frame, which would pass
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
	How much the whole UI grows: the short side over 1080, kept between 1 and
	3, with a quarter more on a TV. Smaller screens change layout instead.
]]
function Screen.uiScale(): number
	local view = realViewport()
	local boost = if isLargeDisplay() then LARGE_DISPLAY_BOOST else 1
	return math.clamp(
		math.min(view.X, view.Y) / REFERENCE_SHORT_SIDE * boost,
		MINIMUM_SCALE,
		MAXIMUM_SCALE
	)
end

function Screen.viewport(): Vector2
	return realViewport() / Screen.uiScale()
end

--[[
	The viewport below the Roblox topbar.
]]
function Screen.usableSize(): Vector2
	local view = Screen.viewport()
	return Vector2.new(view.X, view.Y - realInset().Y / Screen.uiScale())
end

--[[
	Whether touch is the primary input, which is when Roblox shows its
	thumbstick and jump button.
]]
function Screen.isTouch(): boolean
	return prefersTouch()
end

--[[
	A short side under 600 UI units, which includes a desktop window dragged
	that small.
]]
function Screen.isPhone(): boolean
	local view = Screen.viewport()
	return math.min(view.X, view.Y) < PHONE_SHORT_SIDE
end

--[[
	Whether UI should use its touch layout: the touch controls are up, or the
	screen is too small for the desktop layout.
]]
function Screen.isTouchLayout(): boolean
	return prefersTouch() or Screen.isPhone()
end

--[[
	The stretch along the bottom edge that the touch controls leave free,
	measured from the left edge. Without touch controls it is the whole width.
]]
function Screen.bottomTouchSpan(): Span
	local view = realViewport()
	local scale = Screen.uiScale()
	if not prefersTouch() then
		return { Left = 0, Right = view.X / scale }
	end

	local isSmallTouchArea = math.min(view.X, view.Y) <= SMALL_TOUCH_SHORT_SIDE
	local jumpLeftFromRight = if isSmallTouchArea
		then SMALL_JUMP_LEFT_FROM_RIGHT
		else LARGE_JUMP_LEFT_FROM_RIGHT
	return {
		Left = view.X * THUMBSTICK_WIDTH_SHARE / scale,
		Right = (view.X - jumpLeftFromRight) / scale,
	}
end

--[[
	The scale that fits a panel's design size into the room it has. Never
	above 1, and never below minimumScale, past which its text or buttons get
	too small to use.
]]
function Screen.fitScale(designSize: Vector2, room: Vector2, minimumScale: number): number
	local fit = math.min(room.X / designSize.X, room.Y / designSize.Y)
	return math.clamp(fit, minimumScale, 1)
end

-- UI Labs loads a fresh copy of this module on every reload, and an engine
-- connection would keep each copy in memory, so edit mode reads once.
if RunService:IsRunning() then
	watchCamera()
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
	GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(refresh)
	GuiService:GetPropertyChangedSignal("ViewportDisplaySize"):Connect(refresh)
	UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(refresh)
else
	refresh()
end

return Screen
