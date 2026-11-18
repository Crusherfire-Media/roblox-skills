# roblox-skills

Claude Code plugins and a starter project for Roblox game development, from
[Crusherfire Media](https://github.com/Crusherfire-Media). The workflow keeps your game in Git,
syncs it into Studio with Rojo, and gives Claude Code the skills, checks, and Studio access to work
on it.

## What's here

### The `roblox-dev` plugin

In `plugins/roblox-dev`. Skills load as `roblox-dev:<skill>`.

| Skill | What it covers |
|---|---|
| `luau-style-guide` | Luau style and typing, based on Roblox's style guide |
| `code-comments` | Which comments to write and keep, plus a cleanup pass |
| `game-architecture` | Systems run by [Module Loader](https://github.com/ActualFire-Games/module-loader): layout, realms, lifecycle, and requires |
| `rojo-workflow` | How files map into the place, `rojo serve`, syncback, pesde packages, and one worktree per agent |
| `roblox-testing` | Jest Roblox specs, in Studio and in CI |
| `roblox-performance` | Designing systems that scale, and finding and fixing lag |
| `rbx-perf-profiling` | Reading MicroProfiler data through LibMP |
| `game-ui-design` | Player-facing UI for phones, tablets, PCs, consoles, and VR |
| `figma-to-roblox` | Porting a Figma design into Roblox UI |
| `vide` | Vide, the reactive UI library |
| `vide-charm` | Charm state in Vide UI |
| `vide-performance` | Keeping Vide UI fast |
| `vide-ui-labs` | UI Labs stories for Vide components |

**Hooks** (details in `plugins/roblox-dev/hooks/README.md`):

- `skill-gate` holds back a Luau edit until the skills it needs are loaded.
- `after-edit` flags new lines that break Luau conventions.
- `skill-hints` suggests skills from your prompt and the files Claude reads.
- `verify-gate` runs `luau-lsp analyze`, selene, and StyLua on the Luau files Claude edited before
  it finishes a turn.

**Reviewer:** the `reviewer` subagent checks larger Luau changes for Roblox-specific problems
(remotes, data saving, yields, architecture) and returns ranked findings. For general correctness,
use `/code-review`.

The skills work with any Studio MCP. The setup below adds
[Chrrxs/robloxstudio-mcp](https://github.com/Chrrxs/robloxstudio-mcp); Roblox's
[built-in Studio MCP](https://create.roblox.com/docs/studio/mcp) is the option with nothing to
install.

### The `pages` plugin (optional)

In `plugins/pages`. Its `html-kit` skill writes HTML pages, such as a plan for a Roblox system,
with themed components from one shared `kit.js`. A page holds only content, so it costs about as
many tokens as markdown and opens in any browser. A hook holds back a new HTML page until the
skill is loaded. It's [agent-html-kit](https://github.com/leex279/agent-html-kit) (MIT), restyled.

### The starter template

`template/` is a game project ready to sync: Rojo 7.7.1, pesde with Module Loader, Jest Roblox
specs, StyLua, selene, luau-lsp, VS Code settings, a `CLAUDE.md`, and GitHub Actions workflows.
Every pull request runs the lint and type checks. After the optional CI setup in
`template/tools/ci/README.md`, pull requests also run the specs (in a CI place, through Open
Cloud), a merge to `main` publishes to staging, and a GitHub release publishes to production.

### Evals

`evals/` measures each skill against runs without it, with a blind judge. Twelve of the 13 skills
beat the baseline and `game-architecture` comes out even; [`evals/RESULTS.md`](evals/RESULTS.md)
has the numbers.

## One-prompt setup

The setup runs on Windows. First install [VS Code](https://code.visualstudio.com), then
[Git](https://git-scm.com/downloads/win): Git's installer asks for your editor, so VS Code has to be
there first. In Git's installer, pick **Use Visual Studio Code as Git's default editor** and set
**Override the default branch name for new repositories** to `main`. Then install
[Claude Code](https://code.claude.com/docs/en/setup) and
[Roblox Studio](https://create.roblox.com/landing), and sign in to Studio once. You also need a
GitHub account and a Claude plan that includes Claude Code.

Open an empty folder in VS Code, open the Claude Code panel, and paste:

```
Set up this folder as a Roblox game project with the Crusherfire Roblox AI workflow. Download the latest `SETUP.md` from `https://github.com/Crusherfire-Media/roblox-skills/releases/latest/download/SETUP.md` with `curl.exe -L` and follow it step by step. Skip anything that's already installed, and stop and ask me before any step that needs my accounts or keys.
```

Claude follows the [`SETUP.md`](SETUP.md) attached to the latest release. Along the way you click **Yes** on a few
Windows admin prompts, sign in to GitHub, choose a name and visibility for your repo, and restart
VS Code and Studio once. CI setup is a separate, optional step: ask Claude for it when you're
ready.

## Manual install

The plugin, in a terminal:

```
claude plugin marketplace add Crusherfire-Media/roblox-skills#v0.1.6
claude plugin install roblox-dev@crusherfire
claude plugin install pages@crusherfire
```

To upgrade, run this in PowerShell. It runs from `$env:TEMP` because removing the marketplace
inside a project also removes it from that project's `.claude/settings.json`, and it reinstalls
both plugins because the remove uninstalls them:

```powershell
Push-Location $env:TEMP
claude plugin marketplace remove crusherfire
claude plugin marketplace add Crusherfire-Media/roblox-skills#v0.1.6
claude plugin install roblox-dev@crusherfire
claude plugin install pages@crusherfire
Pop-Location
```

Then copy the new template's `.claude/settings.json` into each existing project and commit it.

The Studio MCP, which needs Node.js 22 or later:

```
claude mcp add --scope user robloxstudio -- npx -y @chrrxs/robloxstudio-mcp@latest --auto-install-plugin
```

[Matt Pocock's skills](https://github.com/mattpocock/skills), which the template's settings also
turn on:

```
claude plugin install mattpocock-skills@claude-plugins-official
```

In a Claude Code session that's already open, run `/reload-plugins` to load new plugins. The MCP
server loads in the next conversation you start. Restart Studio after the first MCP run so it loads
the MCP's Studio plugin.

For the template, download
[`roblox-game-template.zip`](https://github.com/Crusherfire-Media/roblox-skills/releases/latest/download/roblox-game-template.zip)
from the latest release. It holds only `template/`, with no history. Unzip it, rename the folder,
install [Rokit](https://github.com/rojo-rbx/rokit#installation) and
[pesde](https://docs.pesde.dev/installation/), and run `rokit install` and `pesde install` in that
folder. The template's `CLAUDE.md` lists the checks. From a terminal with Node.js,
`npx tiged Crusherfire-Media/roblox-skills/template#v0.1.6 my-game` copies the same files.

## Develop

- Run the hook tests with `npm test` (Node.js 22 or later).
- Check the manifests with `claude plugin validate .` and `claude plugin validate plugins/roblox-dev`.
- To release, replace the old tag in `SETUP.md` (its "Release tag" line), in this README (the
  marketplace commands, the upgrade block, and the `tiged` command), and in
  `template/.claude/settings.json` (the marketplace's `ref`). Bump `version` in
  `plugins/<plugin>/.claude-plugin/plugin.json` for every plugin whose files changed since the last
  tag (`git diff --stat <last-tag> -- plugins` lists them): installs are cached by version, so an
  unchanged version keeps the old copy. Commit that to `main`, then publish a
  GitHub release with a new tag on that commit. The Release workflow attaches
  `roblox-game-template.zip` and `SETUP.md` to it (the prompt downloads the latest release's
  `SETUP.md`, so the prompt itself never changes); for a release without the zip, run the workflow by hand with
  its tag.

## Contributing

This repo doesn't accept pull requests. Fork it and make it your own. The MIT license allows it.

## License

[MIT](LICENSE)
