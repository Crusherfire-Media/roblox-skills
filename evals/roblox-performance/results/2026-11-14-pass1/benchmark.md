# Skill Benchmark: roblox-performance

**Model**: claude-opus-5-5
**Date**: 2026-11-14T19:19:35Z
**Evals**: 1, 2, 3, 4 (3 runs each per configuration)

## Summary

| Metric | With Skill | Without Skill | Delta |
|--------|------------|---------------|-------|
| Pass Rate | 100% ± 0% | 100% ± 0% | +0.00 |
| Time | 322.0s ± 213.2s | 167.6s ± 81.0s | +154.5s |
| Tokens | 1377968 ± 915692 | 357638 ± 161481 | +1020330 |

## Trials

| Setup | Trials | Statuses | Target skill loaded | Tokens (mean ± sd) | Wall s (mean ± sd) | Cost $ (mean, total) |
|---|---|---|---|---|---|---|
| with_skill | 12 | ok 12 | 12/12 | 1377968 ± 915692 | 322.0 ± 213.2 | 1.4837, 17.8042 |
| without_skill | 12 | ok 12 | 0/12 | 357638 ± 161481 | 167.6 ± 81.0 | 0.6049, 7.2590 |

Tokens count input, output, and cache reads and writes across every model the session used.

## Per trial

| Eval | Setup | Run | Status | Pass rate | Skills loaded | Tokens | Output tokens | Wall s | Cost $ |
|---|---|---|---|---|---|---|---|---|---|
| eval-1-placement-review | with_skill | 1 | ok | 1 | roblox-dev:roblox-performance, roblox-dev:luau-style-guide, roblox-dev:code-comments | 511158 | 7111 | 96.9 | 0.5835 |
| eval-1-placement-review | with_skill | 2 | ok | 1 | roblox-dev:roblox-performance, roblox-dev:luau-style-guide, roblox-dev:code-comments | 691977 | 9332 | 126.7 | 0.6957 |
| eval-1-placement-review | with_skill | 3 | ok | 1 | roblox-dev:roblox-performance, roblox-dev:luau-style-guide, roblox-dev:code-comments | 616361 | 7874 | 111.7 | 0.5831 |
| eval-1-placement-review | without_skill | 1 | ok | 1 | none | 145550 | 5400 | 70.1 | 0.2460 |
| eval-1-placement-review | without_skill | 2 | ok | 1 | none | 144431 | 5548 | 67.4 | 0.2522 |
| eval-1-placement-review | without_skill | 3 | ok | 1 | none | 145706 | 5554 | 69.2 | 0.2502 |
| eval-2-block-info-lag | with_skill | 1 | ok | 1 | roblox-dev:roblox-performance, roblox-dev:luau-style-guide, roblox-dev:code-comments | 840029 | 16772 | 201.2 | 0.8973 |
| eval-2-block-info-lag | with_skill | 2 | ok | 1 | roblox-dev:roblox-performance, roblox-dev:luau-style-guide, roblox-dev:code-comments | 1108955 | 24669 | 285.4 | 1.4315 |
| eval-2-block-info-lag | with_skill | 3 | ok | 1 | roblox-dev:roblox-performance, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 896242 | 16845 | 203.7 | 0.9638 |
| eval-2-block-info-lag | without_skill | 1 | ok | 1 | none | 394970 | 11794 | 140.6 | 0.5398 |
| eval-2-block-info-lag | without_skill | 2 | ok | 1 | none | 264234 | 9435 | 107.8 | 0.4044 |
| eval-2-block-info-lag | without_skill | 3 | ok | 1 | none | 428343 | 12442 | 143.8 | 0.5322 |
| eval-3-ghost-network | with_skill | 1 | ok | 1 | roblox-dev:roblox-performance, roblox-dev:luau-style-guide, roblox-dev:roblox-testing, roblox-dev:code-comments, roblox-dev:game-architecture, roblox-dev:roblox-performance | 2040113 | 64159 | 667.6 | 2.7454 |
| eval-3-ghost-network | with_skill | 2 | ok | 1 | roblox-dev:roblox-performance, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture, roblox-dev:roblox-testing, roblox-dev:roblox-performance | 3317533 | 64679 | 694.2 | 3.0994 |
| eval-3-ghost-network | with_skill | 3 | ok | 1 | roblox-dev:roblox-performance, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture, roblox-dev:roblox-performance | 2962944 | 62106 | 596.7 | 2.9086 |
| eval-3-ghost-network | without_skill | 1 | ok | 1 | none | 573193 | 28695 | 298.4 | 1.0592 |
| eval-3-ghost-network | without_skill | 2 | ok | 1 | none | 650874 | 25635 | 278.9 | 0.9817 |
| eval-3-ghost-network | without_skill | 3 | ok | 1 | none | 396807 | 22230 | 232.3 | 0.8190 |
| eval-4-build-loading | with_skill | 1 | ok | 1 | roblox-dev:roblox-performance, roblox-dev:luau-style-guide, roblox-dev:code-comments | 1193127 | 24056 | 267.1 | 1.2344 |
| eval-4-build-loading | with_skill | 2 | ok | 1 | roblox-dev:roblox-performance, roblox-dev:luau-style-guide, roblox-dev:code-comments | 1205427 | 28431 | 316.5 | 1.3544 |
| eval-4-build-loading | with_skill | 3 | ok | 1 | roblox-dev:roblox-performance, roblox-dev:luau-style-guide, roblox-dev:code-comments | 1151750 | 27631 | 296.6 | 1.3071 |
| eval-4-build-loading | without_skill | 1 | ok | 1 | none | 363983 | 20864 | 226 | 0.7876 |
| eval-4-build-loading | without_skill | 2 | ok | 1 | none | 389526 | 16763 | 183 | 0.6828 |
| eval-4-build-loading | without_skill | 3 | ok | 1 | none | 394034 | 17630 | 193.2 | 0.7038 |

## Blind judge

| Eval | Pairs judged | with_skill wins | without_skill wins | Ties | Mean score with_skill | Mean score without_skill |
|---|---|---|---|---|---|---|
| eval-1-placement-review | 3/3 | 3 | 0 | 0 | 9 | 8.5 |
| eval-2-block-info-lag | 3/3 | 1 | 2 | 0 | 8.27 | 8.67 |
| eval-3-ghost-network | 3/3 | 3 | 0 | 0 | 8.5 | 6.83 |
| eval-4-build-loading | 3/3 | 2 | 1 | 0 | 7.83 | 7.17 |
| **All** | 12/12 | 9 | 3 | 0 | 8.4 | 7.79 |

Judge runs: 12, mean 28968 tokens and 34.46 s each, $2.6343 in total.
