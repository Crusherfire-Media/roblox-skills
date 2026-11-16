# Skill Benchmark: rojo-workflow

**Model**: claude-opus-5-5
**Date**: 2026-11-16T18:00:27Z
**Evals**: 1, 2, 3, 4 (3 runs each per configuration)

## Summary

| Metric | With Skill | Without Skill | Delta |
|--------|------------|---------------|-------|
| Pass Rate | 90% ± 23% | 89% ± 23% | +0.01 |
| Time | 135.0s ± 33.2s | 93.4s ± 33.1s | +41.6s |
| Tokens | 823358 ± 358583 | 443550 ± 352550 | +379809 |

## Trials

| Setup | Trials | Statuses | Target skill loaded | Tokens (mean ± sd) | Wall s (mean ± sd) | Cost $ (mean, total) |
|---|---|---|---|---|---|---|
| with_skill | 12 | ok 12 | 12/12 | 823358 ± 358583 | 135.0 ± 33.2 | 0.7375, 8.8504 |
| without_skill | 12 | ok 12 | 0/12 | 443550 ± 352550 | 93.4 ± 33.1 | 0.4614, 5.5363 |

Tokens count input, output, and cache reads and writes across every model the session used.

## Per trial

| Eval | Setup | Run | Status | Pass rate | Skills loaded | Tokens | Output tokens | Wall s | Cost $ |
|---|---|---|---|---|---|---|---|---|---|
| eval-1-move-rules | with_skill | 1 | ok | 1 | roblox-dev:rojo-workflow, roblox-dev:luau-style-guide, roblox-dev:roblox-testing, roblox-dev:code-comments, roblox-dev:game-architecture | 841539 | 14068 | 159 | 0.9297 |
| eval-1-move-rules | with_skill | 2 | ok | 1 | roblox-dev:rojo-workflow, roblox-dev:roblox-testing, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 1734937 | 14547 | 196.1 | 1.2298 |
| eval-1-move-rules | with_skill | 3 | ok | 1 | roblox-dev:rojo-workflow, roblox-dev:luau-style-guide, roblox-dev:roblox-testing, roblox-dev:code-comments, roblox-dev:game-architecture | 864621 | 12540 | 166 | 0.8939 |
| eval-1-move-rules | without_skill | 1 | ok | 1 | none | 375098 | 8490 | 79.4 | 0.4468 |
| eval-1-move-rules | without_skill | 2 | ok | 1 | none | 387809 | 10229 | 104.8 | 0.4699 |
| eval-1-move-rules | without_skill | 3 | ok | 1 | none | 452933 | 10460 | 105.8 | 0.5220 |
| eval-2-starter-kit | with_skill | 1 | ok | 1 | roblox-dev:rojo-workflow, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 520414 | 8237 | 100.6 | 0.5782 |
| eval-2-starter-kit | with_skill | 2 | ok | 1 | roblox-dev:rojo-workflow, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 548717 | 6790 | 95 | 0.5666 |
| eval-2-starter-kit | with_skill | 3 | ok | 1 | roblox-dev:rojo-workflow, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 662209 | 7524 | 107.7 | 0.6083 |
| eval-2-starter-kit | without_skill | 1 | ok | 1 | none | 199383 | 6682 | 70.4 | 0.2975 |
| eval-2-starter-kit | without_skill | 2 | ok | 1 | none | 267422 | 5900 | 60.8 | 0.3152 |
| eval-2-starter-kit | without_skill | 3 | ok | 0.8571 | none | 235557 | 5685 | 61.7 | 0.3029 |
| eval-3-add-t | with_skill | 1 | ok | 1 | roblox-dev:rojo-workflow, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 1073373 | 10508 | 155.6 | 0.8340 |
| eval-3-add-t | with_skill | 2 | ok | 1 | roblox-dev:rojo-workflow, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 988782 | 10356 | 145.6 | 0.7985 |
| eval-3-add-t | with_skill | 3 | ok | 1 | roblox-dev:rojo-workflow, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 745948 | 11003 | 140.6 | 0.7785 |
| eval-3-add-t | without_skill | 1 | ok | 1 | none | 371674 | 11030 | 103.8 | 0.4279 |
| eval-3-add-t | without_skill | 2 | ok | 1 | none | 293519 | 7199 | 71.5 | 0.3758 |
| eval-3-add-t | without_skill | 3 | ok | 1 | none | 547129 | 10973 | 95.9 | 0.5558 |
| eval-4-fix-project | with_skill | 1 | ok | 0.4 | roblox-dev:rojo-workflow | 554887 | 8998 | 111 | 0.5258 |
| eval-4-fix-project | with_skill | 2 | ok | 0.4 | roblox-dev:rojo-workflow | 376868 | 7310 | 91.1 | 0.4011 |
| eval-4-fix-project | with_skill | 3 | ok | 1 | roblox-dev:rojo-workflow | 968004 | 10666 | 151.4 | 0.7061 |
| eval-4-fix-project | without_skill | 1 | ok | 0.4 | none | 279070 | 7935 | 79.7 | 0.3779 |
| eval-4-fix-project | without_skill | 2 | ok | 0.4 | none | 393591 | 10593 | 103.9 | 0.4599 |
| eval-4-fix-project | without_skill | 3 | ok | 1 | none | 1519410 | 16227 | 183.2 | 0.9846 |

## Blind judge

| Eval | Pairs judged | with_skill wins | without_skill wins | Ties | Mean score with_skill | Mean score without_skill |
|---|---|---|---|---|---|---|
| eval-1-move-rules | 3/3 | 1 | 1 | 1 | 9.33 | 9.33 |
| eval-2-starter-kit | 3/3 | 3 | 0 | 0 | 9 | 7.5 |
| eval-3-add-t | 3/3 | 2 | 1 | 0 | 8.73 | 8.6 |
| eval-4-fix-project | 3/3 | 3 | 0 | 0 | 5.67 | 4.33 |
| **All** | 12/12 | 9 | 2 | 1 | 8.18 | 7.44 |

Judge runs: 12, mean 16183 tokens and 22.63 s each, $1.5445 in total.
