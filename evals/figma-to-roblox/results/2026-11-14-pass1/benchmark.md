# Skill Benchmark: figma-to-roblox

**Model**: claude-opus-5-5
**Date**: 2026-11-14T18:53:56Z
**Evals**: 1, 2, 3, 4 (3 runs each per configuration)

## Summary

| Metric | With Skill | Without Skill | Delta |
|--------|------------|---------------|-------|
| Pass Rate | 95% ± 7% | 84% ± 11% | +0.11 |
| Time | 535.0s ± 344.6s | 274.8s ± 142.4s | +260.3s |
| Tokens | 3574443 ± 3447519 | 948685 ± 914368 | +2625758 |

## Trials

| Setup | Trials | Statuses | Target skill loaded | Tokens (mean ± sd) | Wall s (mean ± sd) | Cost $ (mean, total) |
|---|---|---|---|---|---|---|
| with_skill | 12 | ok 12 | 12/12 | 3574443 ± 3447519 | 535.0 ± 344.6 | 2.7590, 33.1085 |
| without_skill | 12 | ok 12 | 0/12 | 948685 ± 914368 | 274.8 ± 142.4 | 1.2009, 14.4103 |

Tokens count input, output, and cache reads and writes across every model the session used.

## Per trial

| Eval | Setup | Run | Status | Pass rate | Skills loaded | Tokens | Output tokens | Wall s | Cost $ |
|---|---|---|---|---|---|---|---|---|---|
| eval-1-port-inventory-panel | with_skill | 1 | ok | 0.875 | roblox-dev:figma-to-roblox, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:vide-ui-labs, roblox-dev:code-comments, roblox-dev:game-architecture, roblox-dev:vide, roblox-dev:vide-ui-labs | 9925253 | 86948 | 1005.4 | 5.7112 |
| eval-1-port-inventory-panel | with_skill | 2 | ok | 1 | roblox-dev:figma-to-roblox, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:vide-ui-labs, roblox-dev:code-comments, roblox-dev:game-architecture, roblox-dev:vide, roblox-dev:vide-ui-labs | 6466073 | 85817 | 928 | 4.8318 |
| eval-1-port-inventory-panel | with_skill | 3 | ok | 1 | roblox-dev:figma-to-roblox, roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture, roblox-dev:vide, roblox-dev:vide-ui-labs | 9818249 | 115574 | 1258.7 | 6.5146 |
| eval-1-port-inventory-panel | without_skill | 1 | ok | 0.75 | none | 3250321 | 54908 | 607 | 2.6910 |
| eval-1-port-inventory-panel | without_skill | 2 | ok | 0.75 | none | 1624207 | 36668 | 395.8 | 1.7830 |
| eval-1-port-inventory-panel | without_skill | 3 | ok | 0.875 | none | 2102800 | 44327 | 483.5 | 2.1191 |
| eval-2-export-plan | with_skill | 1 | ok | 1 | roblox-dev:figma-to-roblox | 422821 | 25717 | 275.2 | 1.1428 |
| eval-2-export-plan | with_skill | 2 | ok | 1 | roblox-dev:figma-to-roblox | 428158 | 23862 | 257 | 1.1182 |
| eval-2-export-plan | with_skill | 3 | ok | 1 | roblox-dev:figma-to-roblox | 300108 | 23039 | 238.5 | 1.0304 |
| eval-2-export-plan | without_skill | 1 | ok | 1 | none | 276834 | 23075 | 231.4 | 0.9943 |
| eval-2-export-plan | without_skill | 2 | ok | 1 | none | 303301 | 21414 | 221.8 | 0.9519 |
| eval-2-export-plan | without_skill | 3 | ok | 1 | none | 322228 | 23360 | 238.8 | 1.0209 |
| eval-3-reskin-hotbar | with_skill | 1 | ok | 1 | roblox-dev:figma-to-roblox, roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 1561483 | 26903 | 304.3 | 1.6027 |
| eval-3-reskin-hotbar | with_skill | 2 | ok | 0.8571 | roblox-dev:figma-to-roblox, roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 2443120 | 31853 | 381.7 | 1.9627 |
| eval-3-reskin-hotbar | with_skill | 3 | ok | 1 | roblox-dev:figma-to-roblox, roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 1834072 | 30936 | 357.9 | 1.7682 |
| eval-3-reskin-hotbar | without_skill | 1 | ok | 0.8571 | none | 662203 | 14776 | 169.6 | 0.8193 |
| eval-3-reskin-hotbar | without_skill | 2 | ok | 0.8571 | none | 596277 | 14895 | 169.7 | 0.7972 |
| eval-3-reskin-hotbar | without_skill | 3 | ok | 0.7143 | none | 680519 | 16292 | 177.6 | 0.8758 |
| eval-4-hud-4k | with_skill | 1 | ok | 0.875 | roblox-dev:figma-to-roblox, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:vide-ui-labs, roblox-dev:code-comments, roblox-dev:game-architecture | 2999459 | 34229 | 417.1 | 2.2459 |
| eval-4-hud-4k | with_skill | 2 | ok | 0.875 | roblox-dev:figma-to-roblox, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:vide-ui-labs, roblox-dev:code-comments, roblox-dev:game-architecture | 1984888 | 29384 | 341.5 | 1.7973 |
| eval-4-hud-4k | with_skill | 3 | ok | 0.875 | roblox-dev:figma-to-roblox, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:vide-ui-labs, roblox-dev:code-comments, roblox-dev:game-architecture, roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:figma-to-roblox | 4709627 | 55265 | 655.2 | 3.3826 |
| eval-4-hud-4k | without_skill | 1 | ok | 0.75 | none | 651414 | 20232 | 215.5 | 0.8437 |
| eval-4-hud-4k | without_skill | 2 | ok | 0.75 | none | 474726 | 17365 | 190.4 | 0.7699 |
| eval-4-hud-4k | without_skill | 3 | ok | 0.75 | none | 439390 | 18356 | 195.9 | 0.7443 |

## Blind judge

| Eval | Pairs judged | with_skill wins | without_skill wins | Ties | Mean score with_skill | Mean score without_skill |
|---|---|---|---|---|---|---|
| eval-1-port-inventory-panel | 3/3 | 3 | 0 | 0 | 8.33 | 5.17 |
| eval-2-export-plan | 3/3 | 3 | 0 | 0 | 9 | 6.5 |
| eval-3-reskin-hotbar | 3/3 | 3 | 0 | 0 | 8.17 | 7.17 |
| eval-4-hud-4k | 3/3 | 3 | 0 | 0 | 8.33 | 6 |
| **All** | 12/12 | 12 | 0 | 0 | 8.46 | 6.21 |

Judge runs: 12, mean 39267 tokens and 34.48 s each, $3.6426 in total.
