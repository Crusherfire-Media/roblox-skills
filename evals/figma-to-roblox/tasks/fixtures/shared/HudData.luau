--[[
	Data the HUD shows: the player's coins and their current quest. It holds sample values until
	the server sync is written.
]]

export type Quest = {
	Title: string,
	Description: string,
	Progress: number,
	Goal: number,
}

local HudData = {}

local coins = 12450
local quest: Quest = {
	Title = "Place 10 blocks",
	Description = "Build anywhere on the baseplate. Blocks you remove don't count.",
	Progress = 6,
	Goal = 10,
}
local changed = Instance.new("BindableEvent")

--[[
	Fires with no arguments whenever the coins or the quest change.
]]
HudData.Changed = changed.Event

function HudData.getCoins(): number
	return coins
end

function HudData.getQuest(): Quest
	return table.clone(quest)
end

function HudData.setCoins(amount: number)
	coins = amount
	changed:Fire()
end

function HudData.setQuest(newQuest: Quest)
	quest = table.clone(newQuest)
	changed:Fire()
end

return HudData
