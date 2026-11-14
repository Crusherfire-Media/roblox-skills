--!strict
--[[
	The ScreenGui every game screen is built in. It grows everything inside it
	with the screen's UI scale, so children are authored once in offsets for a
	1080p screen, and keeps them clear of Roblox's own buttons.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)

local Screen = require(script.Parent.Screen)

local create = Vide.create

export type ScaledScreenGuiProps = {
	Name: string,
	DisplayOrder: number?,
	Enabled: (boolean | () -> boolean)?,
	Children: { Instance | () -> any },
}

local function scaledScreenGui(props: ScaledScreenGuiProps): ScreenGui
	return create("ScreenGui")({
		Name = props.Name,
		DisplayOrder = props.DisplayOrder or 0,
		Enabled = if props.Enabled == nil then true else props.Enabled,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,

		create("UIScale")({ Scale = Screen.uiScale }),

		props.Children,
	})
end

return scaledScreenGui
