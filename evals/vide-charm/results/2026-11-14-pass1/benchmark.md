# Skill Benchmark: vide-charm

**Model**: claude-opus-5-5
**Date**: 2026-11-14T20:37:23Z
**Evals**: 1, 2, 3, 4 (3 runs each per configuration)

## Summary

| Metric | With Skill | Without Skill | Delta |
|--------|------------|---------------|-------|
| Pass Rate | 100% ± 0% | 100% ± 0% | +0.00 |
| Time | 193.2s ± 93.1s | 123.8s ± 61.6s | +69.5s |
| Tokens | 1281687 ± 727245 | 659594 ± 423878 | +622093 |

## Trials

| Setup | Trials | Statuses | Target skill loaded | Tokens (mean ± sd) | Wall s (mean ± sd) | Cost $ (mean, total) |
|---|---|---|---|---|---|---|
| with_skill | 12 | ok 12 | 12/12 | 1281687 ± 727245 | 193.2 ± 93.1 | 1.1910, 14.2918 |
| without_skill | 12 | ok 12 | 0/12 | 659594 ± 423878 | 123.8 ± 61.6 | 0.7572, 9.0862 |

Tokens count input, output, and cache reads and writes across every model the session used.

## Per trial

| Eval | Setup | Run | Status | Pass rate | Skills loaded | Tokens | Output tokens | Wall s | Cost $ |
|---|---|---|---|---|---|---|---|---|---|
| eval-1-selection-signal | with_skill | 1 | ok | 1 | roblox-dev:vide-charm, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:vide-ui-labs, roblox-dev:code-comments, roblox-dev:game-architecture | 903602 | 9361 | 130.7 | 1.1230 |
| eval-1-selection-signal | with_skill | 2 | ok | 1 | roblox-dev:vide-charm, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:vide-ui-labs, roblox-dev:code-comments, roblox-dev:game-architecture | 1198683 | 10476 | 141.8 | 1.2573 |
| eval-1-selection-signal | with_skill | 3 | ok | 1 | roblox-dev:vide-charm, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:vide-ui-labs, roblox-dev:code-comments, roblox-dev:game-architecture | 943732 | 9534 | 134.2 | 1.1379 |
| eval-1-selection-signal | without_skill | 1 | ok | 1 | none | 473330 | 8009 | 86.5 | 0.6659 |
| eval-1-selection-signal | without_skill | 2 | ok | 1 | none | 434103 | 7981 | 87.3 | 0.6398 |
| eval-1-selection-signal | without_skill | 3 | ok | 1 | none | 419876 | 7992 | 97.2 | 0.6372 |
| eval-2-block-stock | with_skill | 1 | ok | 1 | roblox-dev:vide-charm, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:vide-ui-labs, roblox-dev:code-comments, roblox-dev:game-architecture | 1085469 | 16088 | 198.6 | 1.1019 |
| eval-2-block-stock | with_skill | 2 | ok | 1 | roblox-dev:vide-charm, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:vide-ui-labs, roblox-dev:code-comments, roblox-dev:game-architecture, roblox-dev:vide, roblox-dev:vide-charm, roblox-dev:vide-ui-labs | 1725245 | 24731 | 299.8 | 1.6884 |
| eval-2-block-stock | with_skill | 3 | ok | 1 | roblox-dev:vide-charm, roblox-dev:luau-style-guide, roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:code-comments, roblox-dev:game-architecture | 816900 | 15666 | 183.3 | 0.9632 |
| eval-2-block-stock | without_skill | 1 | ok | 1 | none | 975712 | 11515 | 149.1 | 0.9001 |
| eval-2-block-stock | without_skill | 2 | ok | 1 | none | 410750 | 10304 | 109.1 | 0.6172 |
| eval-2-block-stock | without_skill | 3 | ok | 1 | none | 435005 | 11005 | 118.1 | 0.6582 |
| eval-3-sync-blocks-left | with_skill | 1 | ok | 1 | roblox-dev:vide-charm, roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 2359216 | 32064 | 339.3 | 1.8914 |
| eval-3-sync-blocks-left | with_skill | 2 | ok | 1 | roblox-dev:vide-charm, roblox-dev:luau-style-guide, roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:code-comments, roblox-dev:game-architecture | 1736451 | 25383 | 288.6 | 1.5046 |
| eval-3-sync-blocks-left | with_skill | 3 | ok | 1 | roblox-dev:vide-charm, roblox-dev:luau-style-guide, roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:code-comments, roblox-dev:game-architecture | 2807021 | 29296 | 314.8 | 1.8830 |
| eval-3-sync-blocks-left | without_skill | 1 | ok | 1 | none | 1283038 | 20976 | 216.6 | 1.2500 |
| eval-3-sync-blocks-left | without_skill | 2 | ok | 1 | none | 1280881 | 21829 | 227.6 | 1.2890 |
| eval-3-sync-blocks-left | without_skill | 3 | ok | 1 | none | 1322981 | 19384 | 206 | 1.1882 |
| eval-4-fix-counter | with_skill | 1 | ok | 1 | roblox-dev:vide-charm, roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:luau-style-guide, roblox-dev:code-comments | 666588 | 6733 | 98.9 | 0.5958 |
| eval-4-fix-counter | with_skill | 2 | ok | 1 | roblox-dev:vide-charm, roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:luau-style-guide, roblox-dev:code-comments | 488793 | 6105 | 85 | 0.5241 |
| eval-4-fix-counter | with_skill | 3 | ok | 1 | roblox-dev:vide-charm, roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:luau-style-guide, roblox-dev:code-comments | 648544 | 7740 | 103.9 | 0.6212 |
| eval-4-fix-counter | without_skill | 1 | ok | 1 | none | 250334 | 4525 | 58.8 | 0.3949 |
| eval-4-fix-counter | without_skill | 2 | ok | 1 | none | 333795 | 4892 | 64.8 | 0.4493 |
| eval-4-fix-counter | without_skill | 3 | ok | 1 | none | 295319 | 4667 | 64 | 0.3967 |

## Blind judge

| Eval | Pairs judged | with_skill wins | without_skill wins | Ties | Mean score with_skill | Mean score without_skill |
|---|---|---|---|---|---|---|
| eval-1-selection-signal | 3/3 | 3 | 0 | 0 | 9 | 7.5 |
| eval-2-block-stock | 3/3 | 0 | 3 | 0 | 7.5 | 8.33 |
| eval-3-sync-blocks-left | 3/3 | 2 | 1 | 0 | 8.33 | 8.33 |
| eval-4-fix-counter | 3/3 | 0 | 0 | 3 | 9.17 | 9.17 |
| **All** | 12/12 | 5 | 4 | 3 | 8.5 | 8.33 |

Judge runs: 12, mean 19292 tokens and 25.08 s each, $1.8813 in total.
