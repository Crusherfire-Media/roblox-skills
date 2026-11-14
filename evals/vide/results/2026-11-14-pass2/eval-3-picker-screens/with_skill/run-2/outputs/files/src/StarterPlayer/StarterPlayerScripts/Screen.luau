--!strict
--[[
	Live facts about the player's screen, as Vide sources: the viewport size,
	the topbar inset, the primary input, and the scale the whole UI grows by.
	Every screen the game builds reads them from here, so a window resize, a
	rotated tablet, or a newly connected keyboard reflows all UI at once.

	Getters read sources, so pass them to a property as a binding
	(`Visible = Screen.isPhone`) or call them inside one.

	Sizes from `viewport` and `usableSize` are in UI units: the offsets UI is
	authored in, for a screen 1080 pixels tall, before the root `UIScale`.
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
-- A TV is read from a couch, so its UI is drawn a quarter larger.
local LARGE_DISPLAY_BOOST = 1.25
-- Phones held sideways are 360 to 440 tall; tablets start near 600.
local PHONE_SHORT_SIDE = 600
local FALLBACK_VIEWPORT = Vector2.new(1920, 1080)

export type SimulatedScreen = {
	Size: Vector2,
	Inset: Vector2?,
	IsTouch: boolean?,
	IsLargeDisplay: boolean?,
}

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
		-- ViewportSize can read (1, 1) before the first frame, which would
		-- pass for a tiny phone, so the fallback stays until a real size
		-- arrives.
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
	-- Camera scripts can replace CurrentCamera, so the listener follows it.
	local camera = workspace.CurrentCamera
	if camera then
		viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(refresh)
	end
	refresh()
end

--[[
	How much the whole UI grows on this screen: the short side over 1080,
	never below 1 and never above 3. Smaller screens keep a scale of 1 and
	change layout instead. Bind it to a UIScale under every ScreenGui.
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
	Whether the screen is phone sized. This is a size, not a platform: a
	desktop window dragged that small counts too.
]]
function Module.isPhone(): boolean
	local view = Module.viewport()
	return math.min(view.X, view.Y) < PHONE_SHORT_SIDE
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

-- Stories and specs load a fresh copy of this module on every reload, and a
-- connection would keep each copy alive, so edit mode reads the screen once.
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
