-- Sells blocks for coins and places the blocks a player has bought.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlockTypes = require("@game/ReplicatedStorage/Shared/BlockTypes")
local PlacementRules = require("@game/ReplicatedStorage/Shared/PlacementRules")

local MAX_PURCHASE = 50
local DEFAULT_SHOW_RECEIPTS = true
local DEFAULT_AUTO_ANCHOR = true

local PRICES: { [string]: number } = {
	Brick = 5,
	Dirt = 2,
	Grass = 3,
	Window = 8,
	Wood = 4,
}

local coinStore = DataStoreService:GetDataStore("Coins")

local function makeRemote(name: string): RemoteEvent
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = ReplicatedStorage
	return remote
end

local buyRemote = makeRemote("BuyBlocks")
local placeRemote = makeRemote("PlaceBlock")
local removeRemote = makeRemote("RemoveBlock")
local receiptRemote = makeRemote("PurchaseReceipt")

local placedFolder = Instance.new("Folder")
placedFolder.Name = "PlacedBlocks"
placedFolder.Parent = workspace

local stock: { [Player]: { [string]: number } } = {}

local function getCoins(plr: Player): number
	return coinStore:GetAsync("coins_" .. plr.UserId) or 0
end

local function setCoins(plr: Player, amt: number)
	coinStore:SetAsync("coins_" .. plr.UserId, amt)
end

local function getOwnerName(part: Instance)
	local ownerId = part:GetAttribute("OwnerId")
	for _, p in Players:GetPlayers() do
		if p.UserId == ownerId then
			return p.Name
		end
	end
end

local function placeBlock(
	plr: Player,
	pos: Vector3,
	bt: string,
	anchored: boolean,
	log: boolean
): Part
	local style = BlockTypes.Styles[bt :: BlockTypes.BlockType]
	local part = Instance.new("Part")
	part.Name = bt
	part.Size = Vector3.one * BlockTypes.BlockSize
	part.Position = pos
	part.Anchored = anchored
	part.Color = style.Color
	part.Material = style.Material
	part.Transparency = style.Transparency
	part:SetAttribute("OwnerId", plr.UserId)
	part.Parent = placedFolder

	if log then
		print(`{plr.Name} placed {bt} at {pos}`)
	end
	return part
end

buyRemote.OnServerEvent:Connect(function(plr: Player, bt: string, amt: number)
	if amt < 1 or amt > MAX_PURCHASE then
		return
	end

	local price = PRICES[bt] * amt
	local coins = getCoins(plr)
	if coins < price then
		return
	end
	setCoins(plr, coins - price)

	local playerStock = stock[plr]
	playerStock[bt] = (playerStock[bt] or 0) + amt

	local showReceipts = plr:GetAttribute("ShowReceipts") or DEFAULT_SHOW_RECEIPTS
	if showReceipts then
		receiptRemote:FireClient(plr, bt, amt, coins - price)
	end
end)

placeRemote.OnServerEvent:Connect(function(plr: Player, bt: string, pos: Vector3)
	local playerStock = stock[plr]
	if (playerStock[bt] or 0) < 1 then
		return
	end

	local center = PlacementRules.snap(pos)
	local ok, reason = PlacementRules.check(center, plr.Character, placedFolder)
	if not ok then
		warn(`{plr.Name} can't place there: {reason}`)
		return
	end

	local autoAnchor = plr:GetAttribute("AutoAnchor")
	if autoAnchor == nil then
		autoAnchor = DEFAULT_AUTO_ANCHOR
	end

	playerStock[bt] -= 1
	placeBlock(plr, center, bt, autoAnchor, true)
end)

removeRemote.OnServerEvent:Connect(function(plr: Player, part: Instance)
	if part.Parent ~= placedFolder then
		return
	end

	-- Anyone can clear away a block whose owner has left.
	local ownerName = tostring(getOwnerName(part))
	if ownerName ~= "nil" and ownerName ~= plr.Name then
		return
	end

	part:Destroy()
	stock[plr][part.Name] = (stock[plr][part.Name] or 0) + 1
end)

Players.PlayerAdded:Connect(function(plr: Player)
	stock[plr] = {}
end)

Players.PlayerRemoving:Connect(function(plr: Player)
	stock[plr] = nil
end)
