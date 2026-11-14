local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlockPlacer = require(script.Parent.BlockPlacer)
local DailyReward = require(script.Parent.UI.DailyReward)
local Hud = require(script.Parent.UI.Hud)
local Vide = require(ReplicatedStorage.Packages.Vide)

local create = Vide.create
local mount = Vide.mount
local show = Vide.show
local source = Vide.source

local REWARD_COINS = 50
local TOAST_SECONDS = 1.5
local REWARD_WINDOW_SECONDS = 59

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local coins = source(250)
local toast: Vide.Source<string?> = source(nil :: string?)
local rewardOpen = source(true)
local streakDays = source(6)
local secondsLeft = source(REWARD_WINDOW_SECONDS)

local function showToast(text: string)
	toast(text)
	task.delay(TOAST_SECONDS, function()
		if toast() == text then
			toast(nil)
		end
	end)
end

local function claimReward()
	coins(coins() + REWARD_COINS)
	streakDays(streakDays() + 1)
	rewardOpen(false)
	showToast(`+{REWARD_COINS} coins`)
end

local function openMenu(name: string)
	if name == "Rewards" then
		rewardOpen(true)
	else
		print(`{name} menu is not built yet`)
	end
end

mount(function()
	return create("ScreenGui")({
		Name = "HudGui",
		IgnoreGuiInset = true,

		Hud({
			Coins = coins,
			Toast = toast,
			OpenMenu = openMenu,
		}),

		show(rewardOpen, function()
			return DailyReward({
				StreakDays = streakDays,
				SecondsLeft = secondsLeft,
				Claim = claimReward,
				Close = function()
					rewardOpen(false)
				end,
			})
		end),
	})
end, playerGui)

task.spawn(function()
	while secondsLeft() > 0 do
		task.wait(1)
		secondsLeft(secondsLeft() - 1)
	end
end)

BlockPlacer.start()
