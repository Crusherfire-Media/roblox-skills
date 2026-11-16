--[[
	Coins. Each player's coins show in their leaderstats. Players also earn passive income: every
	INCOME_INTERVAL seconds, one coin for each block they have placed.
]]

local Players = game:GetService("Players")

local PlacementServerService = require(
	"@game/ServerScriptService/Modules/Systems/Gameplay/PlacementSystem/SystemPackage/PlacementServerService"
)

local STARTING_COINS = 50
-- Seconds between passive income payouts.
local INCOME_INTERVAL = 10

local CurrencyServerService = {}

local coinValues: { [Player]: IntValue } = {}

local function onPlayerAdded(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = STARTING_COINS
	coins.Parent = leaderstats

	leaderstats.Parent = player
	coinValues[player] = coins
end

local function payIncome()
	for player, coins in coinValues do
		coins.Value += PlacementServerService:GetBlockCount(player)
	end
end

function CurrencyServerService:GetCoins(player: Player): number
	local coins = coinValues[player]
	return if coins then coins.Value else 0
end

function CurrencyServerService:AddCoins(player: Player, amount: number)
	assert(amount >= 0, "amount must not be negative")
	local coins = coinValues[player]
	if coins then
		coins.Value += amount
	end
end

--[[
	Takes amount coins from the player if they have that many. Returns whether it did.
]]
function CurrencyServerService:TrySpend(player: Player, amount: number): boolean
	assert(amount >= 0, "amount must not be negative")
	local coins = coinValues[player]
	if not coins or coins.Value < amount then
		return false
	end
	coins.Value -= amount
	return true
end

function CurrencyServerService:Init()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		coinValues[player] = nil
	end)
end

function CurrencyServerService:Start()
	task.spawn(function()
		while true do
			task.wait(INCOME_INTERVAL)
			payIncome()
		end
	end)
end

return CurrencyServerService
