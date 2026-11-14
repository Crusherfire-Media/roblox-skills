# roblox-skills

Claude Code plugins for Roblox game development from [Crusherfire Media](https://github.com/Crusherfire-Media).

> **Work in progress.** The skills, hooks, starter template, and one-prompt setup are still being built. The install steps below work, but the plugin is empty until the first release.

## What's here

- **`plugins/roblox-dev`:** skills for Luau style, code comments, Rojo, testing, performance, and Vide UI, plus hooks that load the right skills before Claude edits Luau files.
- **`template/`:** a starter Roblox game project (Rojo, pesde, StyLua, selene, luau-lsp, and CI workflows).

## Install

In a terminal:

```
claude plugin marketplace add Crusherfire-Media/roblox-skills
claude plugin install roblox-dev@crusherfire
```

Then run `/reload-plugins` in Claude Code.

## Develop

- Run the hook tests with `npm test` (Node.js 22 or later).
- Check the manifests with `claude plugin validate .` and `claude plugin validate plugins/roblox-dev`.
- Bump `version` in `plugins/roblox-dev/.claude-plugin/plugin.json` when you publish, so installs pick up the change.

## License

[MIT](LICENSE)
