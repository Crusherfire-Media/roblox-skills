# Skill Benchmark: vide-ui-labs

**Model**: claude-opus-5-5
**Date**: 2026-11-16T16:50:13Z
**Evals**: 1, 2, 3, 4 (3 runs each per configuration)

## Summary

| Metric | With Skill | Without Skill | Delta |
|--------|------------|---------------|-------|
| Pass Rate | 100% ± 0% | 96% ± 7% | +0.04 |
| Time | 110.7s ± 35.6s | 78.9s ± 11.2s | +31.8s |
| Tokens | 958401 ± 523714 | 389621 ± 85111 | +568780 |

## Trials

| Setup | Trials | Statuses | Target skill loaded | Tokens (mean ± sd) | Wall s (mean ± sd) | Cost $ (mean, total) |
|---|---|---|---|---|---|---|
| with_skill | 12 | ok 12 | 12/12 | 958401 ± 523714 | 110.7 ± 35.6 | 0.8564, 10.2770 |
| without_skill | 12 | ok 12 | 0/12 | 389621 ± 85111 | 78.9 ± 11.2 | 0.4610, 5.5318 |

Tokens count input, output, and cache reads and writes across every model the session used.

## Per trial

| Eval | Setup | Run | Status | Pass rate | Skills loaded | Tokens | Output tokens | Wall s | Cost $ |
|---|---|---|---|---|---|---|---|---|---|
| eval-1-picker-story | with_skill | 1 | ok | 1 | roblox-dev:vide-ui-labs, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 622409 | 7460 | 83.5 | 0.6697 |
| eval-1-picker-story | with_skill | 2 | ok | 1 | roblox-dev:vide-ui-labs, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 482692 | 6767 | 76.7 | 0.6265 |
| eval-1-picker-story | with_skill | 3 | ok | 1 | roblox-dev:vide-ui-labs, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 512133 | 6737 | 76.6 | 0.6573 |
| eval-1-picker-story | without_skill | 1 | ok | 0.8333 | none | 481138 | 7640 | 81.5 | 0.4985 |
| eval-1-picker-story | without_skill | 2 | ok | 1 | none | 360683 | 5818 | 62.9 | 0.4145 |
| eval-1-picker-story | without_skill | 3 | ok | 1 | none | 332407 | 6159 | 71.9 | 0.3982 |
| eval-2-fix-story | with_skill | 1 | ok | 1 | roblox-dev:vide-ui-labs, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:code-comments | 838989 | 10435 | 110.3 | 0.7499 |
| eval-2-fix-story | with_skill | 2 | ok | 1 | roblox-dev:vide-ui-labs, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:vide-performance, roblox-dev:code-comments | 1100914 | 12911 | 136.9 | 0.9436 |
| eval-2-fix-story | with_skill | 3 | ok | 1 | roblox-dev:vide-ui-labs, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:vide-performance, roblox-dev:code-comments | 1582206 | 14349 | 146.2 | 1.1379 |
| eval-2-fix-story | without_skill | 1 | ok | 1 | none | 288883 | 7963 | 76.9 | 0.4053 |
| eval-2-fix-story | without_skill | 2 | ok | 0.8571 | none | 398988 | 8661 | 84.8 | 0.4911 |
| eval-2-fix-story | without_skill | 3 | ok | 1 | none | 456714 | 8850 | 83.8 | 0.4900 |
| eval-3-group-controls | with_skill | 1 | ok | 1 | roblox-dev:vide-ui-labs, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:code-comments | 660872 | 8925 | 86.2 | 0.6464 |
| eval-3-group-controls | with_skill | 2 | ok | 1 | roblox-dev:vide-ui-labs, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:code-comments | 553818 | 8798 | 79.2 | 0.5870 |
| eval-3-group-controls | with_skill | 3 | ok | 1 | roblox-dev:vide-ui-labs, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:code-comments | 468352 | 8089 | 73.9 | 0.5592 |
| eval-3-group-controls | without_skill | 1 | ok | 0.8333 | none | 334116 | 6747 | 69.4 | 0.3953 |
| eval-3-group-controls | without_skill | 2 | ok | 1 | none | 387402 | 6570 | 76.9 | 0.4287 |
| eval-3-group-controls | without_skill | 3 | ok | 1 | none | 220164 | 5952 | 61.6 | 0.3007 |
| eval-4-hud-story | with_skill | 1 | ok | 1 | roblox-dev:vide-ui-labs, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 1991692 | 17477 | 172 | 1.4192 |
| eval-4-hud-story | with_skill | 2 | ok | 1 | roblox-dev:vide-ui-labs, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 1658443 | 14545 | 148.8 | 1.1946 |
| eval-4-hud-story | with_skill | 3 | ok | 1 | roblox-dev:vide-ui-labs, roblox-dev:vide, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 1028288 | 14334 | 138.3 | 1.0858 |
| eval-4-hud-story | without_skill | 1 | ok | 1 | none | 488058 | 9361 | 89.4 | 0.5821 |
| eval-4-hud-story | without_skill | 2 | ok | 1 | none | 457712 | 9577 | 89.2 | 0.5579 |
| eval-4-hud-story | without_skill | 3 | ok | 1 | none | 469189 | 9924 | 98.6 | 0.5695 |

## Blind judge

| Eval | Pairs judged | with_skill wins | without_skill wins | Ties | Mean score with_skill | Mean score without_skill |
|---|---|---|---|---|---|---|
| eval-1-picker-story | 3/3 | 3 | 0 | 0 | 8.4 | 7.67 |
| eval-2-fix-story | 3/3 | 3 | 0 | 0 | 9 | 8.17 |
| eval-3-group-controls | 3/3 | 2 | 0 | 1 | 9.33 | 8.83 |
| eval-4-hud-story | 3/3 | 1 | 2 | 0 | 7.5 | 7.33 |
| **All** | 12/12 | 9 | 2 | 1 | 8.56 | 8 |

Judge runs: 12, mean 17773 tokens and 24.98 s each, $1.6103 in total.
