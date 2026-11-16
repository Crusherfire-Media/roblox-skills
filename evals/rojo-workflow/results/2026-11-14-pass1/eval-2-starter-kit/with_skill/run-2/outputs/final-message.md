The two `Unknown require` errors come from an out-of-date `sourcemap.json`, not from the new code. So I've left the requires as they are.

`sourcemap.json` lists `ReplicatedStorage.Shared` as an empty Folder. It was generated before `BlockTypes.luau` was added, so luau-lsp can't find `game/ReplicatedStorage/Shared/BlockTypes`. That module is in the repo, and the require path matches the project mounts.

Regenerating the sourcemap should clear both errors, but I couldn't run it because shell commands still can't be approved in this session:

```
rojo sourcemap default.project.json -o sourcemap.json
luau-lsp analyze --sourcemap=sourcemap.json src
```

If the errors persist after that, the next suspect is luau-lsp's handling of the `@game` alias.

Everything from my earlier summary still applies. StyLua, selene, `rojo build` and a playtest haven't been run, so the code is untested and nothing is committed.