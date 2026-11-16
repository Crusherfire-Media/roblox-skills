# Formatting

Examples and reasons for the layout rules in SKILL.md's General whitespace
and if-then-else expressions sections, plus the full rules for wrapping a
statement longer than 100 columns.

## General whitespace

- Code lines stay under 100 columns, with a tab counted as four. Luacheck
  counts a tab as one column and so misjudges line length; StyLua counts
  tabs correctly, which makes it the better enforcer.
- Comments wrap at 80 columns. Prose reads more easily in a narrow measure,
  while code needs the extra width.
- Trim trailing whitespace. Most editors can strip it on save.
- Align nothing vertically. Padding that lines up `=` signs breaks as soon as
  someone renames one variable, and fixing it touches every neighboring line.

  Good:
  ```lua
  local slotCount = 24
  local maxStack = 99
  ```
  Bad:
  ```lua
  local slotCount = 24
  local maxStack  = 99
  ```

- One blank line separates logical groups. A run of blank lines spreads the
  file out without saying anything, and a blank first line inside a block
  hides where the block starts.

  ```lua
  const Inventory = require("./Inventory")

  local function sortByRarity(items)
  	table.sort(items, compareRarity)
  end

  Inventory.load(player)
  Inventory.validate(player)

  sortByRarity(Inventory.get(player))
  ```

- One statement per line, and function bodies on their own lines.

  Good:
  ```lua
  table.sort(offers, function(left, right)
  	local leftCost = left.Price * left.Quantity
  	return leftCost < right.Price * right.Quantity
  end)
  ```
  Bad:
  ```lua
  table.sort(offers, function(left, right) local leftCost = left.Price * left.Quantity return leftCost < right.Price * right.Quantity end)
  ```

  On one line, a stray value in a `return` is easy to miss. These two calls
  differ only in where `retries` sits, and the second hands it back from the
  inner function by accident:
  ```lua
  local ok, data = pcall(function() return store:GetAsync(key) end, retries)
  local ok, data = pcall(function() return store:GetAsync(key), retries end)
  ```
  With the body on its own line, the extra return value stands out:
  ```lua
  local ok, data = pcall(function()
  	return store:GetAsync(key)
  end, retries)
  local ok, data = pcall(function()
  	return store:GetAsync(key), retries
  end)
  ```

  An `if` whose body is a single `return`, `continue`, or `break` gets three
  lines too:

  Good:
  ```lua
  if not plot then
  	return
  end
  ```
  Bad:
  ```lua
  if not plot then return end
  ```
  Guards like this tend to grow a warning or a second condition later. On
  separate lines, that addition changes one line in the diff.

- Spaces go around operators, except where leaving them out shows which
  operation binds first.

  Good: `local damage = base + bonus * 2^tier`
  Bad: `local damage = base+bonus* 2 ^tier`

- A space follows every comma in tables and calls.

  Good:
  ```lua
  local starterItems = {"Pickaxe", "Torch", "Rope"}
  placeBlock(position, rotation, material)
  ```
  Bad:
  ```lua
  local starterItems = {"Pickaxe","Torch" ,"Rope"}
  placeBlock(position,rotation ,material)
  ```

- Opening syntax (`{`, `then`, `do`) stays on the line that opens the block.

  Good:
  ```lua
  local shopConfig = {
  	RestockSeconds = 300,
  }

  if shopConfig.RestockSeconds > 0 then
  	scheduleRestock()
  end
  ```
  Bad:
  ```lua
  local shopConfig =
  {
  	RestockSeconds = 300,
  }

  if shopConfig.RestockSeconds > 0
  then
  	scheduleRestock()
  end
  ```

- A table's opening brace hugs the line that starts it. A brace alone on a
  line splits the statement in the middle and makes the reader hunt for
  where it continues.

  Good:
  ```lua
  local blockRules = {
  	Stone = {
  		Hardness = 3,
  	},
  }

  placeBlock({
  	Material = "Stone",
  })
  ```
  Bad:
  ```lua
  local blockRules =
  {
  	Stone =

  	{
  		Hardness = 3,
  	},
  }

  placeBlock(
  {
  	Material = "Stone",
  })
  ```

  Exception: when one call takes both a multiline table and a function, put
  each argument on its own line. Hugging both leaves the function body with
  no indent level that clearly belongs to it:

  ```lua
  promptPurchase(
  	{
  		ItemId = "Lantern",
  	},
  	function(receipt)
  		grantItem(receipt.ItemId)
  	end
  )

  -- The hugging form, where the body's indent is ambiguous:
  promptPurchase({
  	ItemId = "Lantern",
  }, function(receipt)
  	grantItem(receipt.ItemId)
  end)
  ```

## Newlines in long expressions

- Before wrapping, see whether the expression splits into named pieces that
  each fit on a line. Sometimes it does not: one longer expression can be
  clearer than three short ones whose connection the reader has to rebuild.
  Decide which case applies before choosing.
- Expand a table once it holds more than two or three entries or any nested
  table, even when it would fit on one line. A short, flat table stays
  inline.
- Every element of a multiline table ends with a comma, the last one
  included, so adding or moving an entry touches only its own line.
- A dictionary with more than a couple of keys goes multiline.

  Good:
  ```lua
  local reward = { Coins = 50 }

  local starterPack = {
  	Coins = 100,
  	Gems = 5,
  }

  -- One key may be expanded as well
  local blockSize = {
  	Studs = 4,
  }
  ```
  Bad:
  ```lua
  local prices = { Sword = 100, Shield = 80, Bow = 120, Arrow = 2, Potion = 25 }
  ```

- Break an array wherever it reads best, within the column limit. One entry
  per line gives the cleanest diffs; several per line works when the
  grouping means something:

  ```lua
  local hotbar = { "Pickaxe", "Axe", "Shovel", "Torch", "Ladder" }

  local hotbar = {
  	"Pickaxe",
  	"Axe",
  	"Shovel",
  	"Torch",
  	"Ladder",
  }

  local hotbar = {
  	"Pickaxe", "Axe", "Shovel",

  	"Torch", "Ladder",
  }
  ```

- For long argument lists or nested tables, expand every inner table on its
  own lines. Later edits then change only the lines they touch:

  ```lua
  local recipes = {
  	{
  		Output = "PlankBlock",
  		Inputs = { Log = 1 },
  	},
  	{
  		Output = "Torch",
  		Inputs = { Stick = 1, Coal = 1 },
  	},
  }

  registerRecipes(
  	{
  		Output = "PlankBlock",
  		Inputs = { Log = 1 },
  	},
  	{
  		Output = "Torch",
  		Inputs = { Stick = 1, Coal = 1 },
  	}
  )
  ```

  When every argument is a table literal, as with UI element constructors
  that take a props table and a children table, the hugging form is
  acceptable, though a formatter may rewrite it later:

  ```lua
  local recipes = {{
  	Output = "PlankBlock",
  	Inputs = { Log = 1 },
  }, {
  	Output = "Torch",
  	Inputs = { Stick = 1, Coal = 1 },
  }}

  registerRecipes({
  	Output = "PlankBlock",
  	Inputs = { Log = 1 },
  }, {
  	Output = "Torch",
  	Inputs = { Stick = 1, Coal = 1 },
  })
  ```

  Once any argument that is not a table literal sits among them, switch to
  the fully expanded form:

  ```lua
  -- Use this...
  registerRecipes(
  	{
  		Output = "PlankBlock",
  		Inputs = { Log = 1 },
  	},
  	craftingStation,
  	{
  		Output = "Torch",
  		Inputs = { Stick = 1, Coal = 1 },
  	}
  )

  -- ...in place of this.
  registerRecipes({
  	Output = "PlankBlock",
  	Inputs = { Log = 1 },
  }, craftingStation, {
  	Output = "Torch",
  	Inputs = { Stick = 1, Coal = 1 },
  })
  ```

- Break a long expression at its natural parts: one term per line in a long
  sum, one parenthesized group per line.
  - Start each continuation line with its operator, so a glance at the left
    edge shows the line continues the one above.
  - When a parenthesized group needs breaking inside itself, pull it into a
    local first. If that does not help, indent its contents one more level,
    the way a nested table is indented.
  - Leave the expression as a whole unwrapped by parentheses. Luau continues
    an expression across lines without them.

  ```lua
  local totalCost = basePrice * quantity
  	+ shippingFee
  	- (couponValue * couponCount)
  ```

- For a long `if` condition, put the condition on its own indented lines and
  `then` alone on the line after, so the condition and the body cannot blur
  together.

  Good:
  ```lua
  if
  	inventory:HasRoomFor(item)
  	and wallet:CanAfford(item.Price)
  	and not shop:IsOnCooldown(player)
  then
  	wallet:Spend(item.Price)
  	inventory:Add(item)
  end
  ```
  Bad (each of these):
  ```lua
  if inventory:HasRoomFor(item) and wallet:CanAfford(item.Price)
  	and not shop:IsOnCooldown(player) then
  	wallet:Spend(item.Price)
  	inventory:Add(item)
  end

  if inventory:HasRoomFor(item) and wallet:CanAfford(item.Price)
  		and not shop:IsOnCooldown(player) then
  	wallet:Spend(item.Price)
  	inventory:Add(item)
  end

  if inventory:HasRoomFor(item) and wallet:CanAfford(item.Price)
  	and not shop:IsOnCooldown(player) then
  		wallet:Spend(item.Price)
  		inventory:Add(item)
  end
  ```

## if-then-else expressions

- An `if` expression always has an `else`. A plain `isVip and vipBadge`
  with no `or` carries none of the falsy-value risk, so it may stay as it is
  or become `if isVip then vipBadge else nil`.

- Keep the expression small. Conditions get added and removed over time, and
  deleting one from the middle of a long line makes a harder diff to review
  than deleting a whole line.

- When an `if` expression spans lines, begin a line with `then` and another
  with `else`, each one indent deeper than the first line.

  Good:
  ```lua
  local restockDelay = if shop:IsEventActive() or player:HasPass("FastRestock")
  	then 60
  	else 300
  ```
  Bad:
  ```lua
  local restockDelay = if shop:IsEventActive() or player:HasPass("FastRestock") then 60
  	else 300

  local restockDelay = if shop:IsEventActive() or player:HasPass("FastRestock")
  	then 60 else 300

  local restockDelay = if shop:IsEventActive() or player:HasPass("FastRestock") then
  	60 else 300
  ```

- An `if` expression that needs more than three lines becomes an `if`
  statement.

  Bad:
  ```lua
  local spawnCFrame = if plot:IsUnlocked()
  	or player:HasPass("AllPlots")
  	then plot.Origin * CFrame.new(0, BLOCK_SIZE, 0)
  		* plot.Rotation
  	else lobby.Origin * CFrame.new(0, BLOCK_SIZE, 0)
  		* lobby.Rotation
  ```
  Good:
  ```lua
  local spawnCFrame
  if
  	plot:IsUnlocked()
  	or player:HasPass("AllPlots")
  then
  	spawnCFrame = plot.Origin * CFrame.new(0, BLOCK_SIZE, 0)
  		* plot.Rotation
  else
  	spawnCFrame = lobby.Origin * CFrame.new(0, BLOCK_SIZE, 0)
  		* lobby.Rotation
  end
  ```

- Exception: inside a large table constructor or call, an `if` expression may
  stay an expression when a statement would mean repeating many lines of the
  surrounding code. `then` and `else` still begin their own lines.

  Good:
  ```lua
  local shopFrame = createElement("Frame", {
  	Header = if isSaleActive
  		then createElement("TextLabel", {
  			Text = "Sale!",
  		})
  		else createElement("TextLabel", {
  			Text = "Shop",
  		}),
  	Grid = createElement("UIGridLayout"),
  })
  ```
  Bad:
  ```lua
  local shopFrame = createElement("Frame", {
  	Header = if isSaleActive then
  		createElement("TextLabel", {
  			Text = "Sale!",
  		})
  	else
  		createElement("TextLabel", {
  			Text = "Shop",
  		}),
  	Grid = createElement("UIGridLayout"),
  })

  local shopFrame = createElement("Frame", {
  	Header = if isSaleActive then createElement("TextLabel", {
  		Text = "Sale!",
  	}) else createElement("TextLabel", {
  		Text = "Shop",
  	}),
  	Grid = createElement("UIGridLayout"),
  })
  ```

- When the condition alone overflows a line, store it in a well-named local
  first.

  Bad:
  ```lua
  local slotLimit = if player:HasPass("ExtraBackpackSlots")
  	and inventoryUpgrades:IsUnlocked(player, "Satchel")
  	then 48
  	else 24
  ```
  Good:
  ```lua
  local hasLargeBackpack = player:HasPass("ExtraBackpackSlots")
  	and inventoryUpgrades:IsUnlocked(player, "Satchel")
  local slotLimit = if hasLargeBackpack then 48 else 24
  ```

- An `if` expression may use `elseif`, but rarely: past two branches, a
  statement usually reads better. When `elseif` is the right call, start a
  line with `elseif <condition> then`, the same way `then` and `else` start
  theirs. Strict consistency would put that second `then` on a further
  indented line of its own, but the nesting gets too deep, so this layout
  trades a little consistency for shallower code.

  ```lua
  local tierColor = if isEpic then EPIC_COLOR elseif isRare then RARE_COLOR else COMMON_COLOR

  local badge = createElement("Frame", {
  	Icon = if rarity == "Epic"
  		then createElement("ImageLabel", {
  			Image = EPIC_ICON,
  		})
  		elseif rarity == "Rare" then createElement("ImageLabel", {
  			Image = RARE_ICON,
  		})
  		else createElement("ImageLabel", {
  			Image = COMMON_ICON,
  		}),
  	Label = createElement("TextLabel"),
  })
  ```
