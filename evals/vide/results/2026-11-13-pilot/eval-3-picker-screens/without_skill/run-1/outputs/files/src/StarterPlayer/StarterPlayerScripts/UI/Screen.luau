--[[
	A ScreenGui for one UI screen, set up so its contents are laid out in design units (see
	Responsive) and scaled to suit the current device.

	Children go inside a full-screen "Root" frame carrying a UIScale. Root is sized at 1 / scale
	of the screen so that, once scaled, it exactly covers the safe area: scale-based positions
	(like `UDim2.fromScale(0.5, 0)`) still mean "middle of the screen", and offsets are design
	units. Root doesn't take input, so taps and clicks on empty space still reach the world.

	The ScreenGui stays inside the safe area (clear of the topbar and any notch) and survives the
	character respawning, since screens are mounted once from PlayerScripts.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Responsive = require(script.Parent.Responsive)
local Vide = require(ReplicatedStorage.Packages.Vide)

local create = Vide.create

export type ScreenProps = {
	Name: string,
	DisplayOrder: number?,
	Children: { any },
}

local function screen(props: ScreenProps): ScreenGui
	return create("ScreenGui")({
		Name = props.Name,
		DisplayOrder = props.DisplayOrder or 0,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,

		create("Frame")({
			Name = "Root",
			BackgroundTransparency = 1,
			Size = function()
				local scale = Responsive.scale()
				return UDim2.fromScale(1 / scale, 1 / scale)
			end,

			create("UIScale")({ Scale = Responsive.scale }),

			props.Children,
		}),
	})
end

return screen
