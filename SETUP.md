# Roblox AI workflow setup

Release tag: `v0.1.7`

You are setting up the folder open in VS Code as a Roblox game project for the viewer who pasted
the prompt. Wherever a command says `TAG`, replace it with the release tag above: the template
and the `roblox-dev` plugin both come from that tag.

## How to run this file

- Save this file as `$env:TEMP\roblox-setup\SETUP.md`. If you downloaded it into the project
  folder, move it there. That keeps it out of the game repo, and you re-read it from there after
  the restart.
- Work through the steps in order, and finish each one only when its "Done when" line holds.
- When a step's check passes, say so in one line and go to the next step. Steps without a check run
  every time, and their commands skip what's already done. That way a second run, or the run after
  the restart, changes nothing that's already done.
- Every command is Windows PowerShell 5.1. Run it with your PowerShell tool. When you have only a
  Bash tool,
  save the block as a `.ps1` file in `$env:TEMP\roblox-setup` and run
  `powershell -NoProfile -ExecutionPolicy Bypass -File <file>`.
- Run commands in the project folder unless a step names another one.
- Start every command block with this **PATH prelude**. Tools installed during this run reach your
  PATH only after the restart, and the prelude lets you call them by name before then:

  ```powershell
  $env:Path = "$env:USERPROFILE\.rokit\bin;$env:USERPROFILE\.pesde\bin;$env:USERPROFILE\.local\bin;$env:ProgramFiles\nodejs;$env:ProgramFiles\GitHub CLI;$env:ProgramFiles\Git\cmd;$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin;$env:LOCALAPPDATA\Microsoft\WindowsApps;$env:Path"
  ```

- In PowerShell, call `npx.cmd`: the execution policy can block `npx.ps1`. The saved MCP command in
  step 9 is the one place that keeps plain `npx`.
- **Viewer:** marks something only the viewer can do. Tell them exactly what to click or type, then
  wait until they say it's done. Put commands they type in a plain chat message, where they can
  copy them; a question dialog's text can't be copied.
- **Stop and ask:** marks a decision that needs the viewer's accounts or choices. Ask with your
  question tool (AskUserQuestion) and offer the likely answers, then wait. Use it too for the
  questions a skill asks during setup. When a step needs both a command and a question, send the
  command in a chat message first, then ask.
- When a command fails, find the symptom in [Common problems](#common-problems), apply its fix, and
  run the step again. When nothing there matches, show the viewer the error and stop.
- Keys and tokens go only into the hidden-input script in [CI setup](#ci-setup-optional). Keep them
  out of messages, command lines, and command output.

## 1. Check the prerequisites

Check each item:

- `Get-Command winget` finds winget.
- `Get-Command code` finds VS Code's command. When it's missing: **Viewer:** install VS Code from
  <https://code.visualstudio.com> and reopen this folder in it.
- `Get-Command git` finds Git. When it's missing, install it. A UAC prompt appears.
  **Viewer:** click **Yes** on the UAC prompt.

  ```powershell
  winget install --id Git.Git --exact --source winget --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
  ```

  Keep using PowerShell for the rest of this run, even when a Bash tool appears once Git is
  installed.
- Roblox Studio is installed. This prints a folder path when it is:

  ```powershell
  (Get-ItemProperty -Path 'HKCU:\Software\Roblox\RobloxStudio' -Name ContentFolder -ErrorAction SilentlyContinue).ContentFolder
  ```

  When it prints nothing: **Viewer:** install Studio with **Download Studio** at
  <https://create.roblox.com/landing>, launch it once, and sign in.
- The project folder is empty, holds only `.claude` or `.vscode`, or already holds the template (a
  `places.json`). When it holds anything else: **Stop and ask** whether this is the right
  folder.

Done when every item passes.

## 2. Install the GitHub CLI and Node.js

Node.js runs the Studio MCP server and the plugin's hooks, which need Node 22 or later.

Check: `gh --version` runs, and `node --version` prints `v22` or higher.

Run the line for each tool that's missing. Each install shows a UAC prompt. **Viewer:** click
**Yes** on each.

```powershell
winget install --id GitHub.cli --exact --source winget --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
winget install --id OpenJS.NodeJS.LTS --exact --source winget --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
```

When Node is installed but older than 22: **Stop and ask** before upgrading it, since other projects
may use it. On a yes, run the Node line above with `upgrade` in place of `install`.

Done when the check passes.

## 3. Install Rokit and pesde

Both install for the current user without admin rights. Run these blocks as written: they fetch the
tested releases and verify their hashes.

Check: `Test-Path "$env:USERPROFILE\.rokit\bin\rokit.exe"` is `True`. Otherwise, install Rokit:

```powershell
$ProgressPreference = 'SilentlyContinue'
$dir = Join-Path $env:TEMP ("rokit-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $dir | Out-Null
$zip = Join-Path $dir 'rokit.zip'
Invoke-WebRequest -Uri 'https://github.com/rojo-rbx/rokit/releases/download/v1.2.0/rokit-1.2.0-windows-x86_64.zip' -OutFile $zip -UseBasicParsing
if ((Get-FileHash $zip -Algorithm SHA256).Hash -ne 'F9BA1704014FF67D51E8005F605955C7C26D2429A5312A9419DC477FC310E96D') { throw 'Rokit download hash mismatch' }
Expand-Archive -Path $zip -DestinationPath $dir
& (Join-Path $dir 'rokit.exe') self-install
Remove-Item -Recurse -Force $dir
```

Check: `Test-Path "$env:USERPROFILE\.pesde\bin\pesde.exe"` is `True`. Otherwise, install pesde:

```powershell
$ProgressPreference = 'SilentlyContinue'
$dir = Join-Path $env:TEMP ("pesde-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $dir | Out-Null
$zip = Join-Path $dir 'pesde.zip'
Invoke-WebRequest -Uri 'https://github.com/pesde-pkg/pesde/releases/download/v0.7.4%2Bregistry.0.2.3/pesde-0.7.4-windows-x86_64.zip' -OutFile $zip -UseBasicParsing
if ((Get-FileHash $zip -Algorithm SHA256).Hash -ne 'D0FF842217FD4FF462253E7F82653EB9B9FE9BFCAC3E7AA1EDF97078F127C3C1') { throw 'pesde download hash mismatch' }
Expand-Archive -Path $zip -DestinationPath $dir
& (Join-Path $dir 'pesde.exe') self-install
Remove-Item -Recurse -Force $dir
```

Done when `rokit --version` and `& "$env:USERPROFILE\.pesde\bin\pesde.exe" --version` both print a
version.

## 4. Get the `claude` command

The VS Code extension runs its own private copy of Claude Code, so the `claude` command the next
steps use may be missing.

Check: `claude --version` runs. Otherwise, install the standalone CLI:

```powershell
irm https://claude.ai/install.ps1 | iex
```

Then, every time, check the viewer's PATH. This block adds the CLI's folder when the installer left
it off. It also repairs a PATH that an installer in steps 2 to 4 saved as plain text: in that form,
entries such as `%USERPROFILE%\AppData\Local\Microsoft\WindowsApps` (where winget lives) stop
working after the restart.

```powershell
$k = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $true)
$p = $k.GetValue('Path', '', 'DoNotExpandEnvironmentNames')
$add = "$env:USERPROFILE\.local\bin"
$kind = if ($p) { $k.GetValueKind('Path') } else { 'None' }
if ($p -notlike "*$add*" -or $kind -ne 'ExpandString') {
  if ($p -notlike "*$add*") { $p = "$p;$add" }
  $k.SetValue('Path', $p, 'ExpandString')
  # Setting and clearing a variable tells Windows the environment changed.
  [Environment]::SetEnvironmentVariable('ROBLOX_SETUP_REFRESH', '1', 'User')
  [Environment]::SetEnvironmentVariable('ROBLOX_SETUP_REFRESH', $null, 'User')
}
$k.Close()
```

Done when `claude --version` runs and `(Get-Item HKCU:\Environment).GetValueKind('Path')` prints
`ExpandString`.

## 5. Sign in to GitHub

Check: this prints `success` and a scope list that includes `workflow`:

```powershell
$a = (gh auth status --json hosts | ConvertFrom-Json).hosts.'github.com' | Where-Object active
"$($a.state) $($a.scopes)"
```

When `success` is missing: **Viewer:** open a terminal in VS Code (**Terminal > New Terminal**), run
this, and finish the sign-in in the browser:

```powershell
& "$env:ProgramFiles\GitHub CLI\gh.exe" auth login --hostname github.com --git-protocol https --web --scopes workflow
```

When it prints `success` without `workflow`: **Viewer:** run the same command with
`auth refresh --hostname github.com --scopes workflow` in place of everything after `gh.exe`.
The `workflow` scope lets Git push the template's GitHub Actions workflow files.

Once the check passes, make gh the credential helper Git pushes with:

```powershell
gh auth setup-git
```

**Stop and ask** what the GitHub repo should be called (suggest the folder name, with spaces as
hyphens) and whether it's public or private, unless the viewer already said. When the viewer also
has to sign in, send the sign-in command first and ask right after it, so they can answer while
the browser sign-in runs.

Done when the check passes and you have the repo's name and visibility.

## 6. Copy the template

Check: `places.json` exists in the project folder, and this prints the release tag:

```powershell
(Get-Content .claude\settings.json -Raw | ConvertFrom-Json).extraKnownMarketplaces.crusherfire.source.ref
```

When either check fails, download this release's template:

```powershell
$src = "$env:TEMP\roblox-setup\template-TAG"
if (-not (Test-Path "$src\roblox-game-template")) {
  curl.exe -fsSL -o "$src.zip" https://github.com/Crusherfire-Media/roblox-skills/releases/download/TAG/roblox-game-template.zip
  Expand-Archive -Path "$src.zip" -DestinationPath $src -Force
}
```

When `places.json` is missing, copy all of it:

```powershell
Copy-Item -Path "$src\roblox-game-template\*" -Destination . -Recurse -Force
```

When only the tag check failed, `.claude/settings.json` is from an older release, or a
`claude plugin marketplace remove` run in this folder stripped it. **Stop and ask** whether to
replace it with this release's, since that drops any changes made to it. On a yes:

```powershell
New-Item -ItemType Directory -Force .claude | Out-Null
Copy-Item -Path "$src\roblox-game-template\.claude\settings.json" -Destination .claude\settings.json -Force
```

The template's `pesde.toml` takes the place of `pesde init`, which needs a person typing answers.

Done when `places.json`, `rokit.toml`, and `pesde.toml` exist in the project folder and
the tag check prints the release tag.

## 7. Install the VS Code extensions

The template's `.vscode/extensions.json` lists them.

```powershell
$want = (Get-Content .vscode\extensions.json -Raw | ConvertFrom-Json).recommendations
$have = code --list-extensions
$want | Where-Object { $have -notcontains $_ } | ForEach-Object { code --install-extension $_ }
```

**Viewer:** if VS Code asks whether to trust an extension's publisher, click **Trust**.

Done when `code --list-extensions` lists every ID in `extensions.json`. When one stays missing:
**Viewer:** open the Extensions view, search `@recommended`, and install it there.

## 8. Install the Roblox tools and run the checks

Each of these commands skips what's already done, so run them every time:

```powershell
rokit trust rojo-rbx/rojo lune-org/lune JohnnyMorganz/StyLua Kampfkarren/selene JohnnyMorganz/luau-lsp
rokit install
& "$env:USERPROFILE\.pesde\bin\pesde.exe" install
if (-not (Test-Path globalTypes.None.d.luau)) { curl.exe -fsSL -o globalTypes.None.d.luau https://luau-lsp.pages.dev/type-definitions/globalTypes.None.d.luau }
```

`rokit trust` comes first because Rokit's trust question can't be answered from your shell. When `pesde install`
stops at a question: **Viewer:** run `& "$env:USERPROFILE\.pesde\bin\pesde.exe" install` in the VS
Code terminal and answer it.

Then run the five commands under "A change is done when these all pass" in the project's
`CLAUDE.md`.

Done when all five exit with code 0.

## 9. Install the Studio plugins, the Claude Code plugins, and the Studio MCP server

Run each block every time; each one skips or harmlessly repeats what's done.

The Rojo and MCP plugins for Studio (each overwrites its plugin file with the same version):

```powershell
rojo plugin install
npx.cmd -y @chrrxs/robloxstudio-mcp@latest --install-plugin
```

The marketplaces and plugins, all at user scope. The block runs from `$env:TEMP` because removing a
marketplace inside the project also removes it from the project's `.claude/settings.json`:

```powershell
Push-Location $env:TEMP
$m = claude plugin marketplace list --json | ConvertFrom-Json
if (-not ($m | Where-Object name -eq 'claude-plugins-official')) { claude plugin marketplace add anthropics/claude-plugins-official }
$cf = $m | Where-Object name -eq 'crusherfire'
if ($cf -and $cf.ref -ne 'TAG') { claude plugin marketplace remove crusherfire; $cf = $null }
if (-not $cf) { claude plugin marketplace add 'Crusherfire-Media/roblox-skills#TAG' }
$installed = (claude plugin list --json | ConvertFrom-Json) | Where-Object scope -eq 'user' | ForEach-Object { $_.id }
foreach ($id in 'roblox-dev@crusherfire', 'pages@crusherfire', 'mattpocock-skills@claude-plugins-official') { if ($installed -notcontains $id) { claude plugin install $id } }
Pop-Location
```

The `#TAG` pins the marketplace, and with it `roblox-dev`, to this release. When the block removes
an older `crusherfire` marketplace, tell the viewer it was replaced with this release's.

The Studio MCP server, at user scope so it works in every folder. Run this command exactly as
written, with plain `npx`: Claude Code saves it and runs it later. An "already exists" error means
it's done:

```powershell
claude mcp add --scope user robloxstudio -- npx -y @chrrxs/robloxstudio-mcp@latest --auto-install-plugin
```

Done when `claude plugin list --json` shows `roblox-dev@crusherfire`, `pages@crusherfire`, and
`mattpocock-skills@claude-plugins-official` at user scope, `claude plugin marketplace list --json`
shows `crusherfire` with `ref` set to the release tag, and the MCP add succeeded or said it already
exists.

## 10. Create the GitHub repo

Set the Git identity from the viewer's GitHub account. The block fills in only a missing
`user.name` or `user.email`, so note which ones are missing before you run it:

```powershell
if (-not (git config --global --get user.name) -or -not (git config --global --get user.email)) {
  $u = gh api user | ConvertFrom-Json
  if (-not (git config --global --get user.name)) { git config --global user.name $(if ($u.name) { $u.name } else { $u.login }) }
  if (-not (git config --global --get user.email)) { git config --global user.email "$($u.id)+$($u.login)@users.noreply.github.com" }
}
```

When either was missing, tell the viewer: commits use their GitHub name and private GitHub noreply
address, and `git config --global user.name` or `user.email` changes them.

Make `main` the default branch name for new repos when nothing sets one, since a viewer who kept
the Git installer's defaults may get `master`. This repo gets `main` either way, from
`git init -b main` below:

```powershell
if (-not (git config --global --get init.defaultBranch)) { git config --global init.defaultBranch main }
```

Then commit and push, replacing `<name>` and `<public-or-private>` with the answers from step 5:

```powershell
if (-not (Test-Path .git)) { git init -b main }
git rev-parse --verify --quiet HEAD | Out-Null
if ($LASTEXITCODE -ne 0) { git add -A; git commit -m "Start from the roblox-skills template (TAG)" }
if (-not (git remote)) { gh repo create <name> --<public-or-private> --source . --push } else { git push -u origin main }
```

Done when `git status -sb` starts with `## main...origin/main` and shows nothing ahead.

## 11. Restart VS Code and Studio, once

A new Claude Code session loads the plugins and the Studio MCP server, a fresh VS Code start loads
the new PATH, and Studio loads plugins only at startup.

Check: this session lists `roblox-dev:` skills, has the `robloxstudio` MCP server's tools, and
finds `rokit` with `Get-Command rokit` in a block without the prelude.

Otherwise, give the viewer these steps and stop until they're back:

1. Quit VS Code completely with **File > Exit**, closing every window.
2. Close every Roblox Studio window.
3. Reopen VS Code on this folder. In the Claude Code panel, click **Session history**, pick this
   conversation, and type `continue`. In a terminal, `claude --continue` does the same. If Claude
   Code asks whether to trust this folder or install the plugins its settings name, accept.
4. Open a terminal in VS Code (**Terminal > New Terminal**), run `claude`, accept the prompt to
   trust this folder, then type `/exit`. The `claude` command keeps its own list of trusted
   folders, and until it trusts this one it ignores the project's allowed commands.
5. Open Roblox Studio and start a new **Baseplate**.

When the viewer resumes, re-read `$env:TEMP\roblox-setup\SETUP.md` and start again at step 1.

Done when the check passes.

## 12. Finish in the new session

Run all three checks first, and when more than one needs the viewer, ask for those actions in one
message.

1. Check: the project's `CLAUDE.md` has an `## Agent skills` section. Otherwise: **Viewer:** type
   `/mattpocock-skills:setup-matt-pocock-skills` in the chat. The skill then runs in your session:
   ask its questions with your question tool, with these as the recommended answers: GitHub as the issue tracker (the repo
   is on GitHub) and the default labels, then show the draft for the viewer to confirm. It writes
   the `## Agent skills` section and a few files under `docs/agents/`, and creates the labels in
   the repo. Once the section is there,
   commit what it wrote and push:
   `git add -A; git commit -m "Configure Matt Pocock's skills"; git push`.
2. Check: the `robloxstudio` MCP server reports a connected Studio place. When it reports none:
   **Viewer:** in Studio's **Plugins** tab, open the MCP plugin and confirm it shows **Connected**.
3. Check through the MCP server: `ServerScriptService` holds the `Start` script. Otherwise:
   **Viewer:** in the VS Code terminal, run `rojo serve places/main/default.project.json`. Then,
   in the Baseplate, open **Plugins > Rojo** and click **Connect**.

Done when all three checks pass. Tell the viewer the setup is finished, list anything that still
needs them, and mention that CI setup is optional: they can ask for it any time.

## CI setup (optional)

Run this section when the viewer asks for it, once step 12 is done. Pull requests already run the
lint and type checks; this adds the specs in a CI experience, publishing to staging on each merge to
`main`, and publishing to production on each GitHub release. `tools/ci/README.md` explains each
part; walk the viewer through its Setup section like this:

1. **Viewer:** create three experiences in the Creator Dashboard: CI, staging, and production. A new
   game has one place, `main`, which is each experience's start place, so nothing more is needed.
   With more folders in `places/`, each experience needs a place for each.
2. **Viewer:** create an Open Cloud API key under **API Keys** in the Creator Dashboard, with exactly
   these permissions:
   - **universe-places**: **Write**, on the CI, staging, and production experiences.
   - **luau-execution-sessions**: **Write**, on the CI experience only.

   Don't add **assets**: it can't be restricted to experiences, so its Write reaches every asset
   the account can access. Keep **Restrict by Experience** on, leave **Restrict IP addresses**
   off, and set an expiration date. A key acts as the account that created it, so Roblox
   recommends a dedicated account for CI; `tools/ci/README.md` says what that account needs.
3. **Viewer:** store the key by running this in the VS Code terminal at the project root, and paste
   the key only into its hidden prompt:

   ```powershell
   powershell -ExecutionPolicy Bypass -File tools/set-api-key.ps1
   ```

   Check: `gh secret list` shows `ROBLOX_API_KEY`.
4. Ask the viewer for the Creator Dashboard URL of each place in each experience
   (`.../experiences/<universe id>/places/<place id>/...`), which holds both IDs. IDs aren't
   secret, so they can go in the chat. Put them in `places.json`, replacing each `null`:

   ```json
   {
     "universes": { "ci": <CI universe id>, "staging": <id>, "production": <id> },
     "places": {
       "main": { "ci": <CI place id>, "staging": <id>, "production": <id> }
     }
   }
   ```

   Check: `lune run tools/ci/build` builds every place without a `places.json:` error. Then commit
   and push: `git add places.json; git commit -m "Set up CI places"; git push`.

5. Tell the viewer how to retire the key, for example after trying CI with their own account: delete
   the secret with `gh secret delete ROBLOX_API_KEY` **and** revoke the key in the Creator Dashboard.
   Deleting the secret alone leaves the key working.

Done when `gh secret list` shows `ROBLOX_API_KEY` and the pushed `places.json` has no `null` left.

## Common problems

| Symptom | Fix |
|---|---|
| `winget` "is not recognized" | Check that the block starts with the PATH prelude, which adds winget's folder. If it does, run `Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe`, then retry. |
| A winget install fails right after the UAC prompt | The prompt was declined or timed out. Run the install again and have the viewer click **Yes**. |
| A tool "is not recognized" before the restart | Start the block with the PATH prelude. |
| A tool "is not recognized" after the restart | Run step 4's PATH block: an installer may have saved the PATH in a form that drops entries such as winget's. Then **Viewer:** close every VS Code window and terminal and reopen. If that fails, sign out of Windows and back in, or restart Windows. |
| "running scripts is disabled on this system" | Use `npx.cmd` or `npm.cmd`. For the viewer's own terminal, `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser` fixes it; **Stop and ask** first, since it changes a security setting. |
| Rokit: "has not been marked as trusted" | Run `rokit trust <tool>` with the tool the error names, then `rokit install`. |
| Rokit: "Failed to find tool ... in any project manifest" | Run the command in the project folder. For `pesde`, a Rokit copy is in the way: call `& "$env:USERPROFILE\.pesde\bin\pesde.exe"`. |
| Rokit: "os error 2" or "os error 3" | Run `rokit install`. |
| Rokit or pesde: "GitHub API" or "403" while downloading | GitHub's rate limit for anonymous downloads. Wait a few minutes and retry. |
| `rojo plugin install`: "Couldn't find registry keys" | Studio isn't installed or hasn't run yet. **Viewer:** launch Studio once and sign in. |
| A JSON file fails with "Unexpected token on line 1 column 1" | It was saved with a byte order mark. Re-save it as UTF-8 without one; Windows PowerShell's `Set-Content -Encoding utf8` adds one. |
| "Author identity unknown" on commit | Run the identity block in step 10. |
| Push rejected: "without `workflow` scope" | **Viewer:** run the `auth refresh` command from step 5, then push again. |
| `gh repo create`: the name already exists | **Stop and ask** for another name. |
| "Unable to create ... index.lock: File exists" | Retry once the other Git command finishes. When none is running, delete `.git\index.lock`. |
| `stylua --check` reports a diff in every file | Files were checked out with CRLF line endings. Confirm `.gitattributes` holds `* text=auto eol=lf`, run `stylua src tools`, and commit. |
| selene flags `game`, `workspace`, and other Roblox globals | `selene.toml` needs `std = "roblox"`. The template's has it, so run selene from the project root. |
| `claude plugin marketplace add`: "source doesn't match its extraKnownMarketplaces entry" | An older `crusherfire` marketplace is registered. Run `Push-Location $env:TEMP; claude plugin marketplace remove crusherfire; Pop-Location`, then step 9 again. Running the remove inside the project also strips it from `.claude/settings.json`. |
| `.claude/settings.json` lost its `crusherfire` marketplace and plugins | A `claude plugin marketplace remove` ran in the project folder. Run `git checkout -- .claude/settings.json` when the change isn't committed; otherwise restore the file as in step 6. |
| `claude` prints "Ignoring N permissions.allow entries ... this workspace has not been trusted" | The CLI hasn't recorded trust for this folder; the VS Code extension's trust can be saved under a lowercase drive letter that the CLI doesn't match. **Viewer:** run `claude` once in a VS Code terminal in the project folder and accept the trust prompt. |
| A marketplace add or plugin install fails while cloning over SSH | Put `$env:CLAUDE_CODE_PLUGIN_PREFER_HTTPS = '1'` at the start of the block and retry. |
| `claude plugin list` shows a plugin twice, or the `crusherfire` plugins only once | Both are fine. Step 9 installs them at user scope, and the template's `.claude/settings.json` adds a project row; a later marketplace remove drops the project row, and the settings still turn the plugins on. |
| `roblox-dev:` skills are missing after the restart | Check that `claude plugin list` shows the plugin enabled. **Viewer:** type `/reload-plugins`, or start a new conversation. |
| The `robloxstudio` MCP server is missing after the restart | Run `claude mcp list`. When it's listed, the session started before it was added: **Viewer:** start a new conversation. When the saved command contains `cmd` or `C:/`, run `claude mcp remove robloxstudio` and add it again as in step 9. |
| The Studio MCP plugin never shows **Connected**, or reports a version mismatch | **Viewer:** quit every Claude Code session and every Studio window, then reopen both. If the plugin is missing, run `npx.cmd -y @chrrxs/robloxstudio-mcp@latest --install-plugin` first. |
| Rojo plugin: "different protocol version" | Run `rojo --version` in the project folder and expect 7.7.x, then `rojo plugin install` and restart Studio. When Studio also has the Creator Store Rojo plugin, uninstall that copy. |
| `rojo serve`: port 34872 already in use | Another `rojo serve` is running. Close it, or add `--port 34873` to the command and enter that port in the Rojo plugin. |
| `rojo serve` crashes after a folder is deleted or a folder module becomes a file | A known Rojo 7.7.x bug. Run `rojo serve` again and click **Connect**. |
| luau-lsp shows no Roblox types or requires in the editor | Open VS Code on the project root, restart VS Code so Rojo is on its PATH, then run **Luau: Regenerate Sourcemap**. |
| A CI run fails | Find it under "When a run fails" in `tools/ci/README.md`. |
