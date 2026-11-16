# Skill Benchmark: vide-charm

**Model**: claude-opus-5-5
**Date**: 2026-11-16T16:43:38Z
**Evals**: 1, 2, 3, 4 (3 runs each per configuration)

## Summary

| Metric | With Skill | Without Skill | Delta |
|--------|------------|---------------|-------|
| Pass Rate | 100% ± 0% | 100% ± 0% | +0.00 |
| Time | 169.7s ± 92.5s | 123.8s ± 61.6s | +45.9s |
| Tokens | 1248483 ± 594779 | 659594 ± 423878 | +588889 |

## Trials

| Setup | Trials | Statuses | Target skill loaded | Tokens (mean ± sd) | Wall s (mean ± sd) | Cost $ (mean, total) |
|---|---|---|---|---|---|---|
| with_skill | 12 | ok 12 | 12/12 | 1248483 ± 594779 | 169.7 ± 92.5 | 1.1453, 13.7431 |
| without_skill | 12 | ok 12 | 0/12 | 659594 ± 423878 | 123.8 ± 61.6 | 0.7572, 9.0862 |

Tokens count input, output, and cache reads and writes across every model the session used.

## Per trial

| Eval | Setup | Run | Status | Pass rate | Skills loaded | Tokens | Output tokens | Wall s | Cost $ |
|---|---|---|---|---|---|---|---|---|---|
| eval-1-selection-signal | with_skill | 1 | ok | 1 | roblox-dev:vide-charm, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:vide-ui-labs, roblox-dev:code-comments, roblox-dev:game-architecture | 937092 | 10518 | 107.5 | 0.8423 |
| eval-1-selection-signal | with_skill | 2 | ok | 1 | roblox-dev:vide-charm, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:vide-ui-labs, roblox-dev:code-comments, roblox-dev:game-architecture | 932376 | 11165 | 116.3 | 0.8862 |
| eval-1-selection-signal | with_skill | 3 | ok | 1 | roblox-dev:vide-charm, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:vide-ui-labs, roblox-dev:code-comments, roblox-dev:game-architecture | 1163659 | 10885 | 125.2 | 0.9569 |
| eval-1-selection-signal | without_skill | 1 | ok | 1 | none | 473330 | 8009 | 86.5 | 0.6659 |
| eval-1-selection-signal | without_skill | 2 | ok | 1 | none | 434103 | 7981 | 87.3 | 0.6398 |
| eval-1-selection-signal | without_skill | 3 | ok | 1 | none | 419876 | 7992 | 97.2 | 0.6372 |
| eval-2-block-stock | with_skill | 1 | ok | 1 | roblox-dev:vide-charm, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:vide-ui-labs, roblox-dev:code-comments, roblox-dev:game-architecture | 1327901 | 15730 | 163.3 | 1.1527 |
| eval-2-block-stock | with_skill | 2 | ok | 1 | roblox-dev:vide-charm, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:vide-ui-labs, roblox-dev:code-comments, roblox-dev:game-architecture, roblox-dev:vide-charm, roblox-dev:vide | 1960331 | 25028 | 261.7 | 1.7356 |
| eval-2-block-stock | with_skill | 3 | ok | 1 | roblox-dev:vide-charm, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:vide-ui-labs, roblox-dev:code-comments, roblox-dev:game-architecture | 972914 | 14888 | 148.9 | 0.9662 |
| eval-2-block-stock | without_skill | 1 | ok | 1 | none | 975712 | 11515 | 149.1 | 0.9001 |
| eval-2-block-stock | without_skill | 2 | ok | 1 | none | 410750 | 10304 | 109.1 | 0.6172 |
| eval-2-block-stock | without_skill | 3 | ok | 1 | none | 435005 | 11005 | 118.1 | 0.6582 |
| eval-3-sync-blocks-left | with_skill | 1 | ok | 1 | roblox-dev:vide-charm, roblox-dev:luau-style-guide, roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:code-comments, roblox-dev:game-architecture | 1730239 | 27783 | 265.1 | 1.6723 |
| eval-3-sync-blocks-left | with_skill | 2 | ok | 1 | roblox-dev:vide-charm, roblox-dev:luau-style-guide, roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:code-comments, roblox-dev:game-architecture | 2231816 | 30147 | 293.6 | 1.8419 |
| eval-3-sync-blocks-left | with_skill | 3 | ok | 1 | roblox-dev:vide-charm, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:vide-ui-labs, roblox-dev:code-comments, roblox-dev:game-architecture | 1983261 | 34106 | 328.6 | 1.8577 |
| eval-3-sync-blocks-left | without_skill | 1 | ok | 1 | none | 1283038 | 20976 | 216.6 | 1.2500 |
| eval-3-sync-blocks-left | without_skill | 2 | ok | 1 | none | 1280881 | 21829 | 227.6 | 1.2890 |
| eval-3-sync-blocks-left | without_skill | 3 | ok | 1 | none | 1322981 | 19384 | 206 | 1.1882 |
| eval-4-fix-counter | with_skill | 1 | ok | 1 | roblox-dev:vide-charm, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:vide-ui-labs | 461735 | 6842 | 69 | 0.5659 |
| eval-4-fix-counter | with_skill | 2 | ok | 1 | roblox-dev:vide-charm, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:vide-ui-labs, roblox-dev:code-comments | 624630 | 7156 | 76.9 | 0.6195 |
| eval-4-fix-counter | with_skill | 3 | ok | 1 | roblox-dev:vide-charm, roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:luau-style-guide, roblox-dev:code-comments | 655838 | 7368 | 79.8 | 0.6459 |
| eval-4-fix-counter | without_skill | 1 | ok | 1 | none | 250334 | 4525 | 58.8 | 0.3949 |
| eval-4-fix-counter | without_skill | 2 | ok | 1 | none | 333795 | 4892 | 64.8 | 0.4493 |
| eval-4-fix-counter | without_skill | 3 | ok | 1 | none | 295319 | 4667 | 64 | 0.3967 |

## Blind judge

| Eval | Pairs judged | with_skill wins | without_skill wins | Ties | Mean score with_skill | Mean score without_skill |
|---|---|---|---|---|---|---|
| eval-1-selection-signal | 3/3 | 3 | 0 | 0 | 9 | 7.17 |
| eval-2-block-stock | 3/3 | 0 | 3 | 0 | 7.83 | 8.33 |
| eval-3-sync-blocks-left | 3/3 | 2 | 1 | 0 | 8.5 | 7.67 |
| eval-4-fix-counter | 3/3 | 0 | 1 | 2 | 9 | 9.17 |
| **All** | 12/12 | 5 | 5 | 2 | 8.58 | 8.08 |

Judge runs: 12, mean 18826 tokens and 25.83 s each, $1.8681 in total.
