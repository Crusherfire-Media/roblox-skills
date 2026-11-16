# Skill Benchmark: vide-ui-labs

**Model**: claude-opus-5-5
**Date**: 2026-11-16T15:45:28Z
**Evals**: 1, 2, 3, 4 (3 runs each per configuration)

## Summary

| Metric | With Skill | Without Skill | Delta |
|--------|------------|---------------|-------|
| Pass Rate | 100% ± 0% | 96% ± 7% | +0.04 |
| Time | 140.1s ± 48.0s | 78.9s ± 11.2s | +61.2s |
| Tokens | 1076856 ± 592164 | 389621 ± 85111 | +687235 |

## Trials

| Setup | Trials | Statuses | Target skill loaded | Tokens (mean ± sd) | Wall s (mean ± sd) | Cost $ (mean, total) |
|---|---|---|---|---|---|---|
| with_skill | 12 | ok 12 | 12/12 | 1076856 ± 592164 | 140.1 ± 48.0 | 0.9455, 11.3462 |
| without_skill | 12 | ok 12 | 0/12 | 389621 ± 85111 | 78.9 ± 11.2 | 0.4610, 5.5318 |

Tokens count input, output, and cache reads and writes across every model the session used.

## Per trial

| Eval | Setup | Run | Status | Pass rate | Skills loaded | Tokens | Output tokens | Wall s | Cost $ |
|---|---|---|---|---|---|---|---|---|---|
| eval-1-picker-story | with_skill | 1 | ok | 1 | roblox-dev:vide-ui-labs, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 855619 | 9051 | 111.1 | 0.8317 |
| eval-1-picker-story | with_skill | 2 | ok | 1 | roblox-dev:vide-ui-labs, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 706550 | 7271 | 92 | 0.7120 |
| eval-1-picker-story | with_skill | 3 | ok | 1 | roblox-dev:vide-ui-labs, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 633806 | 7713 | 104.9 | 0.7009 |
| eval-1-picker-story | without_skill | 1 | ok | 0.8333 | none | 481138 | 7640 | 81.5 | 0.4985 |
| eval-1-picker-story | without_skill | 2 | ok | 1 | none | 360683 | 5818 | 62.9 | 0.4145 |
| eval-1-picker-story | without_skill | 3 | ok | 1 | none | 332407 | 6159 | 71.9 | 0.3982 |
| eval-2-fix-story | with_skill | 1 | ok | 1 | roblox-dev:vide-ui-labs, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:code-comments | 1503193 | 14060 | 168.5 | 1.0290 |
| eval-2-fix-story | with_skill | 2 | ok | 1 | roblox-dev:vide-ui-labs, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:vide-performance, roblox-dev:code-comments | 1407327 | 14612 | 157.2 | 1.1771 |
| eval-2-fix-story | with_skill | 3 | ok | 1 | roblox-dev:vide-ui-labs, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:code-comments | 1323333 | 17556 | 195.3 | 1.1622 |
| eval-2-fix-story | without_skill | 1 | ok | 1 | none | 288883 | 7963 | 76.9 | 0.4053 |
| eval-2-fix-story | without_skill | 2 | ok | 0.8571 | none | 398988 | 8661 | 84.8 | 0.4911 |
| eval-2-fix-story | without_skill | 3 | ok | 1 | none | 456714 | 8850 | 83.8 | 0.4900 |
| eval-3-group-controls | with_skill | 1 | ok | 1 | roblox-dev:vide-ui-labs, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:code-comments | 431769 | 8609 | 82 | 0.5696 |
| eval-3-group-controls | with_skill | 2 | ok | 1 | roblox-dev:vide-ui-labs, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:code-comments | 648286 | 8917 | 93.3 | 0.6567 |
| eval-3-group-controls | with_skill | 3 | ok | 1 | roblox-dev:vide-ui-labs, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:code-comments | 584389 | 10490 | 107.8 | 0.6446 |
| eval-3-group-controls | without_skill | 1 | ok | 0.8333 | none | 334116 | 6747 | 69.4 | 0.3953 |
| eval-3-group-controls | without_skill | 2 | ok | 1 | none | 387402 | 6570 | 76.9 | 0.4287 |
| eval-3-group-controls | without_skill | 3 | ok | 1 | none | 220164 | 5952 | 61.6 | 0.3007 |
| eval-4-hud-story | with_skill | 1 | ok | 1 | roblox-dev:vide-ui-labs, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 1991984 | 18869 | 210.5 | 1.5483 |
| eval-4-hud-story | with_skill | 2 | ok | 1 | roblox-dev:vide-ui-labs, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 640002 | 13025 | 146.2 | 0.8648 |
| eval-4-hud-story | with_skill | 3 | ok | 1 | roblox-dev:vide-ui-labs, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 2196017 | 18198 | 212.4 | 1.4493 |
| eval-4-hud-story | without_skill | 1 | ok | 1 | none | 488058 | 9361 | 89.4 | 0.5821 |
| eval-4-hud-story | without_skill | 2 | ok | 1 | none | 457712 | 9577 | 89.2 | 0.5579 |
| eval-4-hud-story | without_skill | 3 | ok | 1 | none | 469189 | 9924 | 98.6 | 0.5695 |

## Blind judge

| Eval | Pairs judged | with_skill wins | without_skill wins | Ties | Mean score with_skill | Mean score without_skill |
|---|---|---|---|---|---|---|
| eval-1-picker-story | 3/3 | 0 | 3 | 0 | 7.33 | 8 |
| eval-2-fix-story | 3/3 | 3 | 0 | 0 | 8.83 | 7.83 |
| eval-3-group-controls | 3/3 | 2 | 1 | 0 | 9.33 | 8.83 |
| eval-4-hud-story | 3/3 | 2 | 1 | 0 | 7.33 | 6.5 |
| **All** | 12/12 | 7 | 5 | 0 | 8.21 | 7.79 |

Judge runs: 12, mean 14813 tokens and 23.77 s each, $1.6159 in total.
