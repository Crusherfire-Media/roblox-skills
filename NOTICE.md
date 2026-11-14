# Third-party notices

This repository is licensed under the MIT License (see `LICENSE`), Copyright (c) 2026 Crusherfire Media. Some files include material from the third-party projects listed below. That material stays under its original license, reproduced here as each license requires.

## Material included in this repository

### LibMP documentation

- **Source:** [Roblox/libmp](https://github.com/Roblox/libmp), `docs/` folder
- **Copyright:** Copyright (c) 2026 Roblox Corporation
- **License:** MIT (full text below)
- **Used in:** `plugins/roblox-dev/skills/rbx-perf-profiling/`
  - `references/libmp-guide.md`: upstream `docs/SKILL.md`, with its one Studio MCP tool name replaced by a plain description
  - `references/api-reference.md`: upstream `docs/api-reference.md`, unmodified
  - `references/ALL-SCOPES.md`: upstream `docs/ALL-SCOPES.md`, unmodified
  - `SKILL.md`: the frontmatter description (copied) and the "Essentials from the upstream guide" section (condensed from the guide)

```
MIT License

Copyright (c) 2026 Roblox Corporation

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### Module Loader

- **Source:** [ActualFire-Games/module-loader](https://github.com/ActualFire-Games/module-loader), source comments in `src/init.luau`
- **Copyright:** Copyright (c) 2025 ActualFire Games LLC
- **License:** MIT (full text below)
- **Used in:** `plugins/roblox-dev/skills/game-architecture/references/module-loader.md`, which closely adapts the loader's own documentation comments

```
MIT License

Copyright (c) 2025 ActualFire Games LLC

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### Roblox Creator Documentation

- **Source:** [Roblox/creator-docs](https://github.com/Roblox/creator-docs), published at https://create.roblox.com/docs
- **Copyright:** Roblox Corporation
- **License:** prose is under [Creative Commons Attribution 4.0 International (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/); code samples are under the MIT License
- **Used in:** `plugins/roblox-dev/skills/game-ui-design/references/` (`audience-and-devices.md`, `onboarding-and-progression.md`, `platform.md`). It quotes short passages, unmodified, each linked to its source page.

## Referenced projects

The skills below describe these projects in their own words and quote only API names, error messages, and the occasional single line. No license notice is required. They're listed for credit and so readers can find the originals.

| Project | Copyright | License | Used by |
|---|---|---|---|
| [Roblox Lua Style Guide](https://roblox.github.io/lua-style-guide/) | Roblox Corporation | No license published; rules are summarized in our own words with our own examples | `luau-style-guide` |
| [Vide](https://github.com/centau/vide) | Copyright (c) 2022 centau | MIT | `vide`, `vide-charm`, `vide-performance`, `vide-ui-labs` |
| [Charm, vide-charm, CharmSync](https://github.com/littensy/charm) | Copyright 2024-present Littensy | MIT | `vide-charm` |
| [UI Labs](https://github.com/PepeElToro41/ui-labs) plugin | PepeElToro41 | GPL-3.0 | `vide-ui-labs` |
| [UI Labs utilities](https://github.com/PepeElToro41/ui-labs-utils) | Copyright (c) 2023-present (holder not named in the file) | MIT | `vide-ui-labs` |
| [Jest Lua](https://github.com/jsdotlua/jest-lua) / [Jest Roblox](https://github.com/Roblox/jest-roblox) | Copyright (c) 2017-2023 Roblox Corporation | MIT | `roblox-testing` |
| [LibMP](https://github.com/Roblox/libmp) API (called by scripts) | Copyright (c) 2026 Roblox Corporation | MIT | `roblox-performance` |
| [Rojo](https://github.com/rojo-rbx/rojo) | Rojo contributors (MPL-2.0 text names no holder); docs site: Copyright (c) 2021 Lucien Greathouse | MPL-2.0 (docs site [rojo.space](https://github.com/rojo-rbx/rojo.space): MIT) | `rojo-workflow` |
| [pesde](https://github.com/pesde-pkg/pesde) | Copyright (c) 2024 daimond113 | MIT | `rojo-workflow` |
