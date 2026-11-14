--[[
	Screen scaling shared by every ScreenGui. All UI is authored in offsets for a screen 1080
	pixels tall. The UIScale this builds grows it on taller screens, up to 2x on a 4K screen, and
	never shrinks it below 1, so phones get the authored sizes.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Vide = require(ReplicatedStorage.Packages.Vide)

local cleanup = Vide.cleanup
local create = Vide.create
local source = Vide.source

local REFERENCE_HEIGHT = 1080
local MAX_SCALE = 2

local Screen = {}

Screen.ReferenceHeight = REFERENCE_HEIGHT
Screen.MaxScale = MAX_SCALE

--[[
	A UIScale bound to the viewport's short side. Call it inside a Vide scope and put the result
	directly under the ScreenGui.
]]
function Screen.uiScale(): UIScale
	local camera = Workspace.CurrentCamera
	local viewportSize = source(camera.ViewportSize)
	cleanup(camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		viewportSize(camera.ViewportSize)
	end))

	return create("UIScale")({
		Scale = function()
			local size = viewportSize()
			return math.clamp(math.min(size.X, size.Y) / REFERENCE_HEIGHT, 1, MAX_SCALE)
		end,
	})
end

return Screen
