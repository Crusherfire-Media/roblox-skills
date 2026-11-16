--!strict
--@author: Crusherfire
--@date: 2026-11-13
--[[@description:
	Builds a ScreenGui for the game's own UI, with the UIScale that grows it
	on screens taller than 1080. Build every game screen with this, so none
	misses the scale. Keep GUIs that place things in real pixels (from
	WorldToViewportPoint or AbsolutePosition) out of it.
]]

const Vide = require("@game/ReplicatedStorage/Packages/Vide")

const Screen = require("./Screen")

const create = Vide.create

export type GameScreenGuiProps = {
	Name: string,
	DisplayOrder: number?,
	-- Anything a Vide create table accepts as children: instances, arrays,
	-- or children bindings.
	Children: { any },
}

local function gameScreenGui(props: GameScreenGuiProps): ScreenGui
	return create("ScreenGui")({
		Name = props.Name,
		DisplayOrder = props.DisplayOrder or 0,

		create("UIScale")({ Scale = Screen.uiScale }),
		props.Children,
	})
end

return gameScreenGui
