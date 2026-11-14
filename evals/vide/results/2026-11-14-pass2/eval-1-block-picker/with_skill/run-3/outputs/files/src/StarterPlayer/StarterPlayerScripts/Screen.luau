--!strict
--[[
	Facts about the player's screen, as Vide sources. Each getter reads them,
	so pass it to a property as a binding or call it inside one.
]]

const RunService = game:GetService("RunService")
const UserInputService = game:GetService("UserInputService")

const Vide = require("@game/ReplicatedStorage/Packages/Vide")

const batch = Vide.batch
const source = Vide.source

const REFERENCE_SHORT_SIDE = 1080
const MINIMUM_SCALE = 1
const MAXIMUM_SCALE = 3
const PHONE_SHORT_SIDE = 600
const FALLBACK_VIEWPORT = Vector2.new(1920, 1080)

local Module = {}

local realViewport = source(FALLBACK_VIEWPORT)
local preferredInput = source(Enum.PreferredInput.KeyboardAndMouse)
local viewportConnection: RBXScriptConnection? = nil

local function refresh()
	const camera = workspace.CurrentCamera
	batch(function()
		-- ViewportSize can read (1, 1) before the first frame, which would pass
		-- for a tiny phone.
		if camera and camera.ViewportSize.X > 1 and camera.ViewportSize.Y > 1 then
			realViewport(camera.ViewportSize)
		end
		preferredInput(UserInputService.PreferredInput)
	end)
end

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
	How much the whole UI grows on this screen. Bind it to a UIScale under every
	ScreenGui the game builds.
]]
function Module.uiScale(): number
	const view = realViewport()
	return math.clamp(math.min(view.X, view.Y) / REFERENCE_SHORT_SIDE, MINIMUM_SCALE, MAXIMUM_SCALE)
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
	return preferredInput() == Enum.PreferredInput.Touch
end

function Module.isKeyboardAndMouse(): boolean
	return preferredInput() == Enum.PreferredInput.KeyboardAndMouse
end

function Module.isPhone(): boolean
	const view = Module.viewport()
	return math.min(view.X, view.Y) < PHONE_SHORT_SIDE
end

-- In edit mode a connection would keep every reloaded copy of this module
-- in memory.
if RunService:IsRunning() then
	watchCamera()
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
	UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(refresh)
else
	refresh()
end

return Module
