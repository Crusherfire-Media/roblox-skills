--!strict
--@author: Crusherfire
--@date: 2026-11-13
--[[@description:
	The ScreenGui every game screen is built in. It grows its contents with
	the screen's UI scale and keeps them clear of Roblox's own buttons, so a
	screen's components are authored once, for 1080p, in offsets.
]]

const Vide = require("@game/ReplicatedStorage/Packages/Vide")

const Screen = require("./Screen")

const create = Vide.create

export type ScreenGuiProps = {
	Name: string,
	DisplayOrder: number?,
	Children: { any },
}

local function screenGui(props: ScreenGuiProps): ScreenGui
	return create("ScreenGui")({
		Name = props.Name,
		DisplayOrder = props.DisplayOrder or 0,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,

		create("UIScale")({ Scale = Screen.uiScale }),
		props.Children,
	})
end

return screenGui
