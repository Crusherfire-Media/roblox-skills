# Story check

Mounts every Vide story under a folder the way UI Labs does, and reports:

- errors while loading or mounting,
- stories that yield while mounting,
- every instance a story left in the DataModel outside its own frame. The script removes those
  instances afterward, since they are exactly the edit-mode leaks this check looks for.

Like UI Labs, it loads the story and every module it requires fresh from the script editor's
source, with UI Labs' require rules (`./`, `../`, `@self`, `@game`, and Instance requires), then
turns each control into a Vide source at its default value, runs the story once in `vide.mount`,
and destroys the scope. Then, as UI Labs does on unmount, it calls `step(0)` on every Vide copy it
loaded: each copy connects to `RunService.Heartbeat` when required, and without that step every
check would leave one connection per story running until Studio closes.

It loads modules itself because a plain `require` returns the copy cached by the first require in
that Luau VM, even after the module's source changed. That holds for the command bar and for any
tool that runs Luau in the edit session, so a `require`-based check reports stale results after
an edit.

It finds what a story left behind by comparing the DataModel just before and just after that
story, with no yield in between, so only the story's own code can have added it: a Team Create
collaborator's edit or another plugin's UI never lands in that window. CoreGui and
PluginGuiService are left out, since plugins draw their own UI there, UI Labs and the stories it
has open included. `DescendantAdded` can't do this job: under deferred signals its handlers run
only after the script yields, and by then everything else happening in Studio has come in too.

It does not replace looking at the story in UI Labs; it catches what breaks before anyone looks.
Run it in edit mode, through your Studio tooling's way of running Luau in the edit session, and
set `STORY_ROOT` to the project's stories folder. It returns its report as a string; from the
command bar, `print` the report instead.

```lua
const CoreGui = game:GetService("CoreGui")
const PluginGuiService = game:GetService("PluginGuiService")
const ScriptEditorService = game:GetService("ScriptEditorService")
const STORY_ROOT = game:GetService("ServerScriptService"):FindFirstChild("Stories")

local function createLoader()
    local loaded = {}
    local loading = {}
    local baseEnvironment = getfenv(1)

    local function resolve(from: ModuleScript, path: string): Instance
        local current: Instance? = from.Parent
        for index, part in string.split(path, "/") do
            if index == 1 and part == "@self" then
                current = from
            elseif index == 1 and part == "@game" then
                current = game
            elseif part == ".." then
                current = (current :: Instance).Parent
            elseif part ~= "." then
                current = (current :: Instance):FindFirstChild(part)
            end
            assert(current, `cannot resolve require "{path}" from {from:GetFullName()}`)
        end
        local target = current :: Instance
        if not target:IsA("ModuleScript") then
            target = assert(target:FindFirstChild("init") or target:FindFirstChild("Init"), `no init module in {target:GetFullName()}`)
        end
        return target
    end

    local function load(module: ModuleScript): any
        local entry = loaded[module]
        if entry then
            return entry.Value
        end
        assert(not loading[module], `cyclic require of {module:GetFullName()}`)
        loading[module] = true
        local chunk = assert(loadstring(ScriptEditorService:GetEditorSource(module), "=" .. module:GetFullName()))
        setfenv(chunk, setmetatable({
            script = module,
            _G = {},
            require = function(target: ModuleScript | string)
                if type(target) == "string" then
                    return load(resolve(module, target) :: ModuleScript)
                end
                return load(target)
            end,
        }, { __index = baseEnvironment }))
        local value = chunk()
        loaded[module] = { Value = value }
        loading[module] = nil
        return value
    end

    local function stopVideDrivers()
        for _, entry in loaded do
            local value = entry.Value
            if
                type(value) == "table"
                and type(rawget(value, "mount")) == "function"
                and type(rawget(value, "step")) == "function"
            then
                pcall(value.step, 0)
            end
        end
    end

    return load, stopVideDrivers
end

local function buildControls(vide, controls)
    local sources = {}
    for name, control in controls do
        if type(control) == "table" and control.EntryType == "ControlGroup" then
            sources[name] = buildControls(vide, control.Controls)
        elseif type(control) == "table" and control.EntryType == "Control" then
            sources[name] = vide.source(control.ControlValue)
        else
            sources[name] = vide.source(control)
        end
    end
    return sources
end

local function mountStory(load, storyModule: ModuleScript): string
    local ok, definition = pcall(load, storyModule)
    if not ok then
        return `load error: {string.sub(tostring(definition), 1, 300)}`
    end
    if type(definition) ~= "table" or definition.vide == nil then
        return "skipped: not a Vide story"
    end
    local vide = definition.vide
    local target = Instance.new("Frame")
    local thread = coroutine.create(function()
        local destroy = vide.mount(function()
            return definition.story({
                controls = buildControls(vide, definition.controls or {}),
                target = target,
            })
        end, target)
        destroy()
    end)
    local resumed, err = coroutine.resume(thread)
    target:Destroy()
    if coroutine.status(thread) ~= "dead" then
        return "yielded while mounting"
    end
    if not resumed then
        return `error: {string.sub(tostring(err), 1, 300)}`
    end
    return "ok"
end

local function snapshot(): { [Instance]: true }
    local seen = {}
    for _, service in game:GetChildren() do
        if service == CoreGui or service == PluginGuiService then
            continue
        end
        -- Some services refuse to list their descendants to a plugin.
        local isReadable, descendants = pcall(function()
            return service:GetDescendants()
        end)
        if not isReadable then
            continue
        end
        for _, instance in descendants do
            seen[instance] = true
        end
    end
    return seen
end

local function checkStory(storyModule: ModuleScript): (string, { Instance })
    local load, stopVideDrivers = createLoader()
    local before = snapshot()
    local result = mountStory(load, storyModule)
    stopVideDrivers()
    local leftovers = {}
    for instance in snapshot() do
        if not before[instance] then
            table.insert(leftovers, instance)
        end
    end
    return result, leftovers
end

local report = {}
local removed = 0
for _, module in STORY_ROOT:GetDescendants() do
    if not (module:IsA("ModuleScript") and string.match(module.Name, "%.story$")) then
        continue
    end
    local result, leftovers = checkStory(module)
    for _, instance in leftovers do
        result ..= `\n    left in the DataModel: {instance:GetFullName()}`
    end
    for _, instance in leftovers do
        if instance.Parent ~= nil then
            instance:Destroy()
            removed += 1
        end
    end
    table.insert(report, `{module.Name}: {result}`)
end
table.sort(report)
table.insert(report, `DataModel leftovers removed: {removed}`)
return table.concat(report, "\n")
```

Reading the result:

- `ok` for every story you touched, and `DataModel leftovers removed: 0`, is a pass.
- A `left in the DataModel` line names the leaked instance. Find what created it (usually a
  world effect or require-time setup) and gate or clean it up as the skill describes.
- `yielded while mounting` leaves Vide's scope stack in a bad state for the rest of that run;
  fix the yield, then run the check again.
- A story whose component reads `Players.LocalPlayer`, remotes, or services fails here the same
  way it fails in UI Labs.
- Anything a story creates after a yield or from `task.defer` lands after the second snapshot, so
  the check misses it. Mount that story in UI Labs and look for it in the Explorer.
- Each story costs two passes over the DataModel, a fraction of a second in a large place. To
  check one story, point `STORY_ROOT` at its folder.
- To exercise a story's controls, reuse `createLoader` and `buildControls`: mount the story, set
  a control's source to a new value, and inspect the target frame's descendants. Call the
  loader's second return value, `stopVideDrivers`, once you are done with that loader.
