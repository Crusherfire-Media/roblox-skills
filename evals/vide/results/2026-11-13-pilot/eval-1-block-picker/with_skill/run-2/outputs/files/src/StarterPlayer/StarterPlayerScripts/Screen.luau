--[[
	Facts about the player's screen as Vide sources, so UI layout follows the live device: the
	window can resize, a phone can rotate, and the primary input can change while the UI is up.
	Sizes from viewport() are in UI units, the offsets UI is authored in for a 1080 tall screen.
]]

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Vide = require(ReplicatedStorage.Packages.Vide)

local batch = Vide.batch
local source = Vide.source

local REFERENCE_SHORT_SIDE = 1080
local MINIMUM_SCALE = 1
local MAXIMUM_SCALE = 3
local PHONE_SHORT_SIDE = 600
local FALLBACK_VIEWPORT = Vector2.new(1920, 1080)

local Screen = {}

local realViewport = source(FALLBACK_VIEWPORT)
local prefersTouch = source(false)
local viewportConnection: RBXScriptConnection? = nil

local function refresh()
	local camera = Workspace.CurrentCamera
	batch(function()
		-- ViewportSize can read (1, 1) before the first frame, which would pass for a tiny
		-- phone, so the fallback stays until a real size arrives.
		if camera and camera.ViewportSize.X > 1 and camera.ViewportSize.Y > 1 then
			realViewport(camera.ViewportSize)
		end
		prefersTouch(UserInputService.PreferredInput == Enum.PreferredInput.Touch)
	end)
end

local function watchCamera()
	if viewportConnection then
		viewportConnection:Disconnect()
	end
	local camera = Workspace.CurrentCamera
	if camera then
		viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(refresh)
	end
	refresh()
end

--[[
	How much the whole UI grows on this screen. Bind it to a UIScale under every ScreenGui.
	Smaller screens keep a scale of 1 and change layout instead.
]]
function Screen.uiScale(): number
	local view = realViewport()
	return math.clamp(math.min(view.X, view.Y) / REFERENCE_SHORT_SIDE, MINIMUM_SCALE, MAXIMUM_SCALE)
end

--[[
	The viewport in UI units.
]]
function Screen.viewport(): Vector2
	return realViewport() / Screen.uiScale()
end

--[[
	Whether touch is the primary input, which is when Roblox shows its thumbstick and jump
	button.
]]
function Screen.isTouch(): boolean
	return prefersTouch()
end

function Screen.isPhone(): boolean
	local view = Screen.viewport()
	return math.min(view.X, view.Y) < PHONE_SHORT_SIDE
end

--[[
	Whether a HUD should use its touch layout: the touch controls are up, or the screen is too
	small for the desktop layout.
]]
function Screen.isTouchLayout(): boolean
	return prefersTouch() or Screen.isPhone()
end

if RunService:IsRunning() then
	watchCamera()
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
	GuiService:GetPropertyChangedSignal("ViewportDisplaySize"):Connect(refresh)
	UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(refresh)
else
	refresh()
end

return Screen
