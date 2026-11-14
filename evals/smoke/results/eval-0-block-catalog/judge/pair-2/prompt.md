You are judging two attempts at the same task in a Roblox game project. The project is a Rojo
repo: Luau files under `src/` become scripts in the place, and Vide (a reactive UI library) is
installed as `ReplicatedStorage.Packages.Vide`. Each attempt started from the same files. You see
each attempt as a git diff of what it changed, plus the results of automatic checks (luau-lsp type
analysis, selene lint, StyLua formatting) on its changed Luau files.

The attempts are labeled A and B in random order. Judge only what is in front of you: don't guess
how either attempt was produced.

## Task given to both attempts

<task>
Add the block type catalog for the block placement system: one module that lists the five block types players can place (brick, dirt, grass, window, wood) with the color, material, and transparency each one uses. Server and client code will both read it. Only the catalog for now; the placement system and the UI come later.
</task>

## Rubric

Score each criterion from 1 to 5 for each attempt (1 poor, 3 acceptable, 5 excellent):

1. Lists all five block types, each with a color, a material, and a transparency
2. Sits where both server and client code can require it
3. Typed, idiomatic Luau that is easy to extend with a new block type
4. Stays in scope: no placement system or UI

## Attempt A

<attempt_a_checks>
- [pass] The trial finished without an error or timeout
- [pass] luau-lsp analyze reports no errors in the changed Luau files
- [pass] selene reports no errors in the changed Luau files
- [pass] stylua --check passes on the changed Luau files
- [pass] A Luau file under src lists the Window and Wood block types
- [pass] The catalog is frozen with table.freeze
- [fail] The catalog is at src/ReplicatedStorage/Shared/BlockCatalog.luau
  missing
</attempt_a_checks>

<attempt_a_diff>
diff --git a/src/ReplicatedStorage/Shared/BlockTypes.luau b/src/ReplicatedStorage/Shared/BlockTypes.luau
new file mode 100644
index 0000000..67f19ff
--- /dev/null
+++ b/src/ReplicatedStorage/Shared/BlockTypes.luau
@@ -0,0 +1,78 @@
+--!strict
+-- Catalog of the block types players can place. Shared by server and client.
+-- Every table here is frozen; treat the catalog as read-only.
+
+export type BlockTypeId = "Brick" | "Dirt" | "Grass" | "Window" | "Wood"
+
+export type BlockType = {
+	id: BlockTypeId,
+	displayName: string,
+	color: Color3,
+	material: Enum.Material,
+	transparency: number,
+}
+
+local function define(blockType: BlockType): BlockType
+	return table.freeze(blockType)
+end
+
+-- Display order (for the build UI later).
+local list: { BlockType } = table.freeze({
+	define({
+		id = "Brick",
+		displayName = "Brick",
+		color = Color3.fromRGB(151, 61, 46),
+		material = Enum.Material.Brick,
+		transparency = 0,
+	}),
+	define({
+		id = "Dirt",
+		displayName = "Dirt",
+		color = Color3.fromRGB(110, 78, 52),
+		material = Enum.Material.Ground,
+		transparency = 0,
+	}),
+	define({
+		id = "Grass",
+		displayName = "Grass",
+		color = Color3.fromRGB(76, 145, 64),
+		material = Enum.Material.Grass,
+		transparency = 0,
+	}),
+	define({
+		id = "Window",
+		displayName = "Window",
+		color = Color3.fromRGB(175, 215, 235),
+		material = Enum.Material.Glass,
+		transparency = 0.5,
+	}),
+	define({
+		id = "Wood",
+		displayName = "Wood",
+		color = Color3.fromRGB(160, 112, 70),
+		material = Enum.Material.WoodPlanks,
+		transparency = 0,
+	}),
+})
+
+local byId: { [string]: BlockType } = {}
+for _, blockType in list do
+	byId[blockType.id] = blockType
+end
+table.freeze(byId)
+
+local BlockTypes = {
+	list = list,
+	byId = byId,
+}
+
+-- Looks up a block type by id. Returns nil for unknown ids, so the server can
+-- use it to validate ids sent by clients.
+function BlockTypes.get(id: unknown): BlockType?
+	if typeof(id) ~= "string" then
+		return nil
+	end
+	return byId[id]
+end
+
+return table.freeze(BlockTypes)

</attempt_a_diff>

## Attempt B

<attempt_b_checks>
- [pass] The trial finished without an error or timeout
- [pass] luau-lsp analyze reports no errors in the changed Luau files
- [pass] selene reports no errors in the changed Luau files
- [pass] stylua --check passes on the changed Luau files
- [pass] A Luau file under src lists the Window and Wood block types
- [pass] The catalog is frozen with table.freeze
- [pass] The catalog is at src/ReplicatedStorage/Shared/BlockCatalog.luau
</attempt_b_checks>

<attempt_b_diff>
diff --git a/src/ReplicatedStorage/Shared/BlockCatalog.luau b/src/ReplicatedStorage/Shared/BlockCatalog.luau
new file mode 100644
index 0000000..0177150
--- /dev/null
+++ b/src/ReplicatedStorage/Shared/BlockCatalog.luau
@@ -0,0 +1,44 @@
+--!strict
+-- Catalog of block types players can place. Shared by server and client.
+
+export type BlockType = {
+	Name: string,
+	Color: Color3,
+	Material: Enum.Material,
+	Transparency: number,
+}
+
+local BlockCatalog: { [string]: BlockType } = {
+	Brick = table.freeze({
+		Name = "Brick",
+		Color = Color3.fromRGB(151, 0, 0),
+		Material = Enum.Material.Brick,
+		Transparency = 0,
+	}),
+	Dirt = table.freeze({
+		Name = "Dirt",
+		Color = Color3.fromRGB(110, 80, 50),
+		Material = Enum.Material.Ground,
+		Transparency = 0,
+	}),
+	Grass = table.freeze({
+		Name = "Grass",
+		Color = Color3.fromRGB(75, 151, 75),
+		Material = Enum.Material.Grass,
+		Transparency = 0,
+	}),
+	Window = table.freeze({
+		Name = "Window",
+		Color = Color3.fromRGB(200, 230, 255),
+		Material = Enum.Material.Glass,
+		Transparency = 0.5,
+	}),
+	Wood = table.freeze({
+		Name = "Wood",
+		Color = Color3.fromRGB(160, 110, 60),
+		Material = Enum.Material.WoodPlanks,
+		Transparency = 0,
+	}),
+}
+
+return table.freeze(BlockCatalog)

</attempt_b_diff>

## How to answer

1. For each attempt, score every rubric criterion with a one-sentence note that cites the code.
2. Give each attempt an overall score from 1 to 10 that reflects how well it does the task: correct,
   working Luau that a Roblox developer would merge counts most. Treat a check failure as a real
   defect only when the cited error is in the attempt's own code.
3. List each attempt's main strengths and weaknesses.
4. Pick the winner. Be decisive; answer TIE only when the attempts are genuinely equivalent. If both
   fail, pick the one that fails less badly.
