# Worked examples

One example of each outcome of the cleanup pass, in Luau. The rules carry over to any language.

## Delete: narration on clean code

Every comment goes. The code stays byte-identical.

```lua
local function onPlayerAdded(player: Player)
	-- Create a folder called leaderstats
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	-- Create the Coins value and start it at 0
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = 0
	-- Parent everything to the player
	coins.Parent = leaderstats
	leaderstats.Parent = player
end -- onPlayerAdded
```

## Rewrite: a header block split up and trimmed

The block mixes narration with two real whys. Each why moves next to the line it governs, trimmed; the narration goes.

Before:

```lua
-- This function handles purchases. The client shows its own price, but the
-- server recomputes the price itself because the client can send any value.
-- The price is also rounded so it matches what the shop UI displays. Finally
-- the purchase is logged for analytics.
local function purchase(player: Player, itemId: string)
	local price = PriceCalculator.getPrice(itemId, player)
	price = math.round(price)
```

After:

```lua
local function purchase(player: Player, itemId: string)
	-- Recompute here: the client's price is untrusted
	local price = PriceCalculator.getPrice(itemId, player)
	-- Match the whole-coin price the shop UI displays
	price = math.round(price)
```

## Razor: a real why worded at three times its length

Before (4 lines):

```lua
-- Prefix every analytics event name with "shop_". This groups the shop
-- events together in the dashboard, where they can be filtered by prefix,
-- and it will also let the warehouse export (DATA-212) split them into their
-- own table once that export is built.
local EVENT_PREFIX = "shop_"
```

After (1 line):

```lua
local EVENT_PREFIX = "shop_" -- the dashboard groups events by prefix
```

## Rewrite: a moving target

```lua
-- Before: per the trading design doc, section 3.2
-- Before: see GAME-1234
-- After:  Offers lock for 10 seconds after either side changes them, so a
--         last-second swap can't slip past review (GAME-1234)
```

## Keep: a surprising but essential line

This comment is exactly the kind that must survive. Without it, the next editor "simplifies" the second check away and lets NaN through every range check on remote input.

```lua
-- amount ~= amount catches NaN, which passes every range check
if typeof(amount) ~= "number" or amount ~= amount then
	return
end
```
