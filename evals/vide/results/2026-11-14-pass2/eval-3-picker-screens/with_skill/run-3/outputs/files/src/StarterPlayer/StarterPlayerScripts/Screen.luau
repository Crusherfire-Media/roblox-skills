--!strict
--[[
	Facts about the player's screen, as Vide sources, so UI follows the device
	live: a window resize, a phone or tablet rotating, a keyboard or gamepad
	being connected. UI reads the screen here and nowhere else.

	Sizes are authored once for a screen 1080 pixels tall. Larger screens grow
	the whole UI with uiScale; smaller screens keep a scale of 1 and change
	layout instead.
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
local PHONE_SHORT_SIDE = 600
local FALLBACK_VIEWPORT = Vector2.new(1920, 1080)

local Module = {}

local realViewport = source(FALLBACK_VIEWPORT)
local realInset = source(Vector2.zero)
local preferredInput = source(Enum.PreferredInput.KeyboardAndMouse)
local isLargeDisplay = source(false)
local viewportConnection: RBXScriptConnection? = nil

local function refresh()
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
		preferredInput(UserInputService.PreferredInput)
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
	How much the whole UI grows on this screen: the short side over 1080, never
	below 1 or above 3, with a quarter more on a TV. Only GameScreenGui binds
	it; components never use it for their own sizes.
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
	Roblox's pick of the player's primary input.
]]
function Module.preferredInput(): Enum.PreferredInput
	return preferredInput()
end

--[[
	Whether touch is the primary input, which is when Roblox shows its
	thumbstick and jump button.
]]
function Module.isTouch(): boolean
	return preferredInput() == Enum.PreferredInput.Touch
end

--[[
	A phone is a size, not a platform: a desktop window dragged that small
	cannot fit a desktop layout either.
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
	return Module.isTouch() or Module.isPhone()
end

-- UI Labs loads a fresh copy of this module on every reload, and a connection
-- would keep each copy alive, so edit mode reads the screen once.
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
