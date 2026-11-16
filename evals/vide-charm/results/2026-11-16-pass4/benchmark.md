# Skill Benchmark: vide-charm

**Model**: claude-opus-5-5
**Date**: 2026-11-16T17:43:33Z
**Evals**: 1, 2, 3, 4 (3 runs each per configuration)

## Summary

| Metric | With Skill | Without Skill | Delta |
|--------|------------|---------------|-------|
| Pass Rate | 100% ± 0% | 100% ± 0% | +0.00 |
| Time | 211.9s ± 163.6s | 123.8s ± 61.6s | +88.1s |
| Tokens | 1584665 ± 1073824 | 659594 ± 423878 | +925071 |

## Trials

| Setup | Trials | Statuses | Target skill loaded | Tokens (mean ± sd) | Wall s (mean ± sd) | Cost $ (mean, total) |
|---|---|---|---|---|---|---|
| with_skill | 12 | ok 12 | 12/12 | 1584665 ± 1073824 | 211.9 ± 163.6 | 1.3426, 16.1113 |
| without_skill | 12 | ok 12 | 0/12 | 659594 ± 423878 | 123.8 ± 61.6 | 0.7572, 9.0862 |

Tokens count input, output, and cache reads and writes across every model the session used.

## Per trial

| Eval | Setup | Run | Status | Pass rate | Skills loaded | Tokens | Output tokens | Wall s | Cost $ |
|---|---|---|---|---|---|---|---|---|---|
| eval-1-selection-signal | with_skill | 1 | ok | 1 | roblox-dev:vide-charm, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:vide-ui-labs, roblox-dev:code-comments, roblox-dev:game-architecture | 996290 | 10537 | 113.2 | 0.8957 |
| eval-1-selection-signal | with_skill | 2 | ok | 1 | roblox-dev:vide-charm, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:vide-ui-labs, roblox-dev:code-comments, roblox-dev:game-architecture | 1063873 | 11762 | 131 | 0.9272 |
| eval-1-selection-signal | with_skill | 3 | ok | 1 | roblox-dev:vide-charm, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:vide-ui-labs, roblox-dev:code-comments, roblox-dev:game-architecture | 1017178 | 11179 | 118.7 | 0.9286 |
| eval-1-selection-signal | without_skill | 1 | ok | 1 | none | 473330 | 8009 | 86.5 | 0.6659 |
| eval-1-selection-signal | without_skill | 2 | ok | 1 | none | 434103 | 7981 | 87.3 | 0.6398 |
| eval-1-selection-signal | without_skill | 3 | ok | 1 | none | 419876 | 7992 | 97.2 | 0.6372 |
| eval-2-block-stock | with_skill | 1 | ok | 1 | roblox-dev:vide-charm, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:vide-ui-labs, roblox-dev:code-comments, roblox-dev:game-architecture | 1309533 | 15651 | 161.7 | 1.1640 |
| eval-2-block-stock | with_skill | 2 | ok | 1 | roblox-dev:vide-charm, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:vide-ui-labs, roblox-dev:code-comments, roblox-dev:game-architecture | 1496604 | 20250 | 203.5 | 1.2940 |
| eval-2-block-stock | with_skill | 3 | ok | 1 | roblox-dev:vide-charm, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:vide-ui-labs, roblox-dev:code-comments, roblox-dev:game-architecture | 1407281 | 15320 | 159.5 | 1.2011 |
| eval-2-block-stock | without_skill | 1 | ok | 1 | none | 975712 | 11515 | 149.1 | 0.9001 |
| eval-2-block-stock | without_skill | 2 | ok | 1 | none | 410750 | 10304 | 109.1 | 0.6172 |
| eval-2-block-stock | without_skill | 3 | ok | 1 | none | 435005 | 11005 | 118.1 | 0.6582 |
| eval-3-sync-blocks-left | with_skill | 1 | ok | 1 | roblox-dev:vide-charm, roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture, roblox-dev:vide-charm, roblox-dev:vide-ui-labs, roblox-dev:vide | 3643452 | 50065 | 537.7 | 2.8884 |
| eval-3-sync-blocks-left | with_skill | 2 | ok | 1 | roblox-dev:vide-charm, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:vide-ui-labs, roblox-dev:code-comments, roblox-dev:game-architecture, roblox-dev:vide-charm | 3474171 | 40655 | 460.3 | 2.5552 |
| eval-3-sync-blocks-left | with_skill | 3 | ok | 1 | roblox-dev:vide-charm, roblox-dev:luau-style-guide, roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:code-comments, roblox-dev:game-architecture, roblox-dev:vide-charm | 2669565 | 38184 | 419.9 | 2.2849 |
| eval-3-sync-blocks-left | without_skill | 1 | ok | 1 | none | 1283038 | 20976 | 216.6 | 1.2500 |
| eval-3-sync-blocks-left | without_skill | 2 | ok | 1 | none | 1280881 | 21829 | 227.6 | 1.2890 |
| eval-3-sync-blocks-left | without_skill | 3 | ok | 1 | none | 1322981 | 19384 | 206 | 1.1882 |
| eval-4-fix-counter | with_skill | 1 | ok | 1 | roblox-dev:vide-charm, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:vide-ui-labs, roblox-dev:vide-performance, roblox-dev:code-comments | 646452 | 8755 | 91.5 | 0.7209 |
| eval-4-fix-counter | with_skill | 2 | ok | 1 | roblox-dev:vide-charm, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:vide-ui-labs, roblox-dev:code-comments | 663852 | 7435 | 76.8 | 0.6517 |
| eval-4-fix-counter | with_skill | 3 | ok | 1 | roblox-dev:vide-charm, roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:luau-style-guide, roblox-dev:code-comments | 627728 | 6429 | 69 | 0.5997 |
| eval-4-fix-counter | without_skill | 1 | ok | 1 | none | 250334 | 4525 | 58.8 | 0.3949 |
| eval-4-fix-counter | without_skill | 2 | ok | 1 | none | 333795 | 4892 | 64.8 | 0.4493 |
| eval-4-fix-counter | without_skill | 3 | ok | 1 | none | 295319 | 4667 | 64 | 0.3967 |

## Blind judge

| Eval | Pairs judged | with_skill wins | without_skill wins | Ties | Mean score with_skill | Mean score without_skill |
|---|---|---|---|---|---|---|
| eval-1-selection-signal | 3/3 | 3 | 0 | 0 | 9.33 | 7.5 |
| eval-2-block-stock | 3/3 | 2 | 1 | 0 | 8.5 | 8.5 |
| eval-3-sync-blocks-left | 3/3 | 3 | 0 | 0 | 8.5 | 7.17 |
| eval-4-fix-counter | 3/3 | 2 | 0 | 1 | 9 | 8.83 |
| **All** | 12/12 | 10 | 1 | 1 | 8.83 | 8 |

Judge runs: 12, mean 17421 tokens and 24.29 s each, $1.772 in total.
