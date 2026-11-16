# Skill Benchmark: rojo-workflow

**Model**: claude-opus-5-5
**Date**: 2026-11-16T16:18:00Z
**Evals**: 1, 2, 3, 4 (3 runs each per configuration)

## Summary

| Metric | With Skill | Without Skill | Delta |
|--------|------------|---------------|-------|
| Pass Rate | 95% ± 17% | 89% ± 23% | +0.06 |
| Time | 117.4s ± 24.6s | 93.4s ± 33.1s | +24.0s |
| Tokens | 817430 ± 254733 | 443550 ± 352550 | +373880 |

## Trials

| Setup | Trials | Statuses | Target skill loaded | Tokens (mean ± sd) | Wall s (mean ± sd) | Cost $ (mean, total) |
|---|---|---|---|---|---|---|
| with_skill | 12 | ok 12 | 12/12 | 817430 ± 254733 | 117.4 ± 24.6 | 0.7630, 9.1566 |
| without_skill | 12 | ok 12 | 0/12 | 443550 ± 352550 | 93.4 ± 33.1 | 0.4614, 5.5363 |

Tokens count input, output, and cache reads and writes across every model the session used.

## Per trial

| Eval | Setup | Run | Status | Pass rate | Skills loaded | Tokens | Output tokens | Wall s | Cost $ |
|---|---|---|---|---|---|---|---|---|---|
| eval-1-move-rules | with_skill | 1 | ok | 1 | roblox-dev:rojo-workflow, roblox-dev:roblox-testing, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 1146881 | 14211 | 155.1 | 0.9974 |
| eval-1-move-rules | with_skill | 2 | ok | 1 | roblox-dev:rojo-workflow, roblox-dev:luau-style-guide, roblox-dev:roblox-testing, roblox-dev:code-comments, roblox-dev:game-architecture | 1286191 | 12990 | 143.6 | 0.9954 |
| eval-1-move-rules | with_skill | 3 | ok | 1 | roblox-dev:rojo-workflow, roblox-dev:luau-style-guide, roblox-dev:roblox-testing, roblox-dev:code-comments, roblox-dev:game-architecture | 819447 | 14208 | 140.2 | 0.8990 |
| eval-1-move-rules | without_skill | 1 | ok | 1 | none | 375098 | 8490 | 79.4 | 0.4468 |
| eval-1-move-rules | without_skill | 2 | ok | 1 | none | 387809 | 10229 | 104.8 | 0.4699 |
| eval-1-move-rules | without_skill | 3 | ok | 1 | none | 452933 | 10460 | 105.8 | 0.5220 |
| eval-2-starter-kit | with_skill | 1 | ok | 1 | roblox-dev:rojo-workflow, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 501688 | 9448 | 95.1 | 0.6398 |
| eval-2-starter-kit | with_skill | 2 | ok | 1 | roblox-dev:rojo-workflow, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 508416 | 7797 | 77.2 | 0.5852 |
| eval-2-starter-kit | with_skill | 3 | ok | 1 | roblox-dev:rojo-workflow, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 489604 | 9978 | 93.5 | 0.6301 |
| eval-2-starter-kit | without_skill | 1 | ok | 1 | none | 199383 | 6682 | 70.4 | 0.2975 |
| eval-2-starter-kit | without_skill | 2 | ok | 1 | none | 267422 | 5900 | 60.8 | 0.3152 |
| eval-2-starter-kit | without_skill | 3 | ok | 0.8571 | none | 235557 | 5685 | 61.7 | 0.3029 |
| eval-3-add-t | with_skill | 1 | ok | 1 | roblox-dev:rojo-workflow, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 869636 | 13991 | 136.3 | 0.8079 |
| eval-3-add-t | with_skill | 2 | ok | 1 | roblox-dev:rojo-workflow, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 947537 | 11616 | 117.7 | 0.7884 |
| eval-3-add-t | with_skill | 3 | ok | 1 | roblox-dev:rojo-workflow, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 947062 | 13545 | 132.3 | 0.8528 |
| eval-3-add-t | without_skill | 1 | ok | 1 | none | 371674 | 11030 | 103.8 | 0.4279 |
| eval-3-add-t | without_skill | 2 | ok | 1 | none | 293519 | 7199 | 71.5 | 0.3758 |
| eval-3-add-t | without_skill | 3 | ok | 1 | none | 547129 | 10973 | 95.9 | 0.5558 |
| eval-4-fix-project | with_skill | 1 | ok | 1 | roblox-dev:rojo-workflow | 624957 | 8763 | 90.7 | 0.5471 |
| eval-4-fix-project | with_skill | 2 | ok | 0.4 | roblox-dev:rojo-workflow | 767532 | 11394 | 113.9 | 0.6443 |
| eval-4-fix-project | with_skill | 3 | ok | 1 | roblox-dev:rojo-workflow | 900204 | 10244 | 112.8 | 0.7691 |
| eval-4-fix-project | without_skill | 1 | ok | 0.4 | none | 279070 | 7935 | 79.7 | 0.3779 |
| eval-4-fix-project | without_skill | 2 | ok | 0.4 | none | 393591 | 10593 | 103.9 | 0.4599 |
| eval-4-fix-project | without_skill | 3 | ok | 1 | none | 1519410 | 16227 | 183.2 | 0.9846 |

## Blind judge

| Eval | Pairs judged | with_skill wins | without_skill wins | Ties | Mean score with_skill | Mean score without_skill |
|---|---|---|---|---|---|---|
| eval-1-move-rules | 3/3 | 1 | 0 | 2 | 9.67 | 9.5 |
| eval-2-starter-kit | 3/3 | 2 | 1 | 0 | 8.83 | 8 |
| eval-3-add-t | 3/3 | 1 | 2 | 0 | 8.33 | 8.67 |
| eval-4-fix-project | 3/3 | 3 | 0 | 0 | 7.67 | 4 |
| **All** | 12/12 | 7 | 3 | 2 | 8.63 | 7.54 |

Judge runs: 12, mean 14941 tokens and 19.51 s each, $1.4799 in total.
