--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")

local Places = require("./places")

-- Checks places.json against the place folders, then builds every place into
-- build/<name>.rbxl, the files run-tests and publish upload.
fs.writeDir("build")
for _, name in Places.names() do
	local result = process.exec(
		"rojo",
		{ "build", `places/{name}/default.project.json`, "--output", `build/{name}.rbxl` },
		{ stdio = "inherit" }
	)
	if not result.ok then
		print(`Building place "{name}" failed`)
		process.exit(1)
	end
end
