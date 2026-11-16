# Skill Benchmark: roblox-lua-style-guide

**Model**: claude-opus-5-5
**Date**: 2026-11-14T16:24:25Z
**Evals**: 1, 2, 3, 4 (3 runs each per configuration)

## Summary

| Metric | With Skill | Without Skill | Delta |
|--------|------------|---------------|-------|
| Pass Rate | 97% ± 4% | 78% ± 17% | +0.18 |
| Time | 183.4s ± 47.7s | 116.6s ± 25.4s | +66.8s |
| Tokens | 712416 ± 463996 | 299194 ± 109518 | +413222 |

## Trials

| Setup | Trials | Statuses | Target skill loaded | Tokens (mean ± sd) | Wall s (mean ± sd) | Cost $ (mean, total) |
|---|---|---|---|---|---|---|
| with_skill | 12 | ok 12 | 12/12 | 712416 ± 463996 | 183.4 ± 47.7 | 0.8096, 9.7147 |
| without_skill | 12 | ok 12 | 0/12 | 299194 ± 109518 | 116.6 ± 25.4 | 0.4666, 5.5995 |

Tokens count input, output, and cache reads and writes across every model the session used.

## Per trial

| Eval | Setup | Run | Status | Pass rate | Skills loaded | Tokens | Output tokens | Wall s | Cost $ |
|---|---|---|---|---|---|---|---|---|---|
| eval-1-block-inventory | with_skill | 1 | ok | 1 | roblox-dev:roblox-lua-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 1113767 | 14415 | 217.7 | 0.9445 |
| eval-1-block-inventory | with_skill | 2 | ok | 0.9091 | roblox-dev:roblox-lua-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 1716130 | 16788 | 237.9 | 1.2519 |
| eval-1-block-inventory | with_skill | 3 | ok | 0.9091 | roblox-dev:roblox-lua-style-guide, roblox-dev:game-architecture, roblox-dev:code-comments | 567476 | 9376 | 143.1 | 0.5958 |
| eval-1-block-inventory | without_skill | 1 | ok | 0.5455 | none | 451247 | 8148 | 106.7 | 0.4660 |
| eval-1-block-inventory | without_skill | 2 | ok | 0.5455 | none | 259666 | 5950 | 75.5 | 0.3557 |
| eval-1-block-inventory | without_skill | 3 | ok | 0.5455 | none | 508612 | 9206 | 112.7 | 0.5372 |
| eval-2-refactor-plot-stats | with_skill | 1 | ok | 0.9286 | roblox-dev:roblox-lua-style-guide, roblox-dev:code-comments | 497030 | 18650 | 205.2 | 0.7871 |
| eval-2-refactor-plot-stats | with_skill | 2 | ok | 0.9286 | roblox-dev:roblox-lua-style-guide, roblox-dev:code-comments | 904467 | 22370 | 265.6 | 1.0025 |
| eval-2-refactor-plot-stats | with_skill | 3 | ok | 0.9286 | roblox-dev:roblox-lua-style-guide, roblox-dev:code-comments | 376266 | 17120 | 179.2 | 0.7152 |
| eval-2-refactor-plot-stats | without_skill | 1 | ok | 0.8571 | none | 297021 | 16278 | 167.2 | 0.6062 |
| eval-2-refactor-plot-stats | without_skill | 2 | ok | 0.8571 | none | 255232 | 11557 | 128.7 | 0.4387 |
| eval-2-refactor-plot-stats | without_skill | 3 | ok | 0.7857 | none | 252977 | 14016 | 146.8 | 0.5200 |
| eval-3-review-block-shop | with_skill | 1 | ok | 1 | roblox-dev:roblox-lua-style-guide | 278626 | 11645 | 129.3 | 0.5860 |
| eval-3-review-block-shop | with_skill | 2 | ok | 1 | roblox-dev:roblox-lua-style-guide | 206120 | 9374 | 108.4 | 0.4484 |
| eval-3-review-block-shop | with_skill | 3 | ok | 1 | roblox-dev:roblox-lua-style-guide | 420106 | 11399 | 139.2 | 0.6252 |
| eval-3-review-block-shop | without_skill | 1 | ok | 1 | none | 263199 | 11670 | 130.4 | 0.4861 |
| eval-3-review-block-shop | without_skill | 2 | ok | 1 | none | 105609 | 10923 | 116 | 0.3932 |
| eval-3-review-block-shop | without_skill | 3 | ok | 1 | none | 209338 | 11571 | 127.8 | 0.4714 |
| eval-4-ghost-preview | with_skill | 1 | ok | 1 | roblox-dev:roblox-lua-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 539907 | 15696 | 166.2 | 0.8087 |
| eval-4-ghost-preview | with_skill | 2 | ok | 1 | roblox-dev:roblox-lua-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 1348967 | 17145 | 217 | 1.0752 |
| eval-4-ghost-preview | with_skill | 3 | ok | 1 | roblox-dev:roblox-lua-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 580127 | 17916 | 191.9 | 0.8741 |
| eval-4-ghost-preview | without_skill | 1 | ok | 0.75 | none | 272791 | 8231 | 98.1 | 0.4254 |
| eval-4-ghost-preview | without_skill | 2 | ok | 0.75 | none | 407439 | 8055 | 96.1 | 0.4929 |
| eval-4-ghost-preview | without_skill | 3 | ok | 0.75 | none | 307200 | 7346 | 92.7 | 0.4066 |

## Blind judge

| Eval | Pairs judged | with_skill wins | without_skill wins | Ties | Mean score with_skill | Mean score without_skill |
|---|---|---|---|---|---|---|
| eval-1-block-inventory | 3/3 | 3 | 0 | 0 | 8.83 | 5.67 |
| eval-2-refactor-plot-stats | 3/3 | 3 | 0 | 0 | 7.83 | 7 |
| eval-3-review-block-shop | 3/3 | 3 | 0 | 0 | 9.17 | 7.17 |
| eval-4-ghost-preview | 3/3 | 3 | 0 | 0 | 8.67 | 7.33 |
| **All** | 12/12 | 12 | 0 | 0 | 8.63 | 6.79 |

Judge runs: 12, mean 25456 tokens and 33.24 s each, $1.9777 in total.
