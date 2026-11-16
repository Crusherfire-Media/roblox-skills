# Skill Benchmark: roblox-performance

**Model**: claude-opus-5-5
**Date**: 2026-11-16T17:03:33Z
**Evals**: 1, 2, 3, 4 (3 runs each per configuration)

## Summary

| Metric | With Skill | Without Skill | Delta |
|--------|------------|---------------|-------|
| Pass Rate | 100% ± 0% | 100% ± 0% | +0.00 |
| Time | 254.3s ± 166.8s | 167.6s ± 81.0s | +86.7s |
| Tokens | 1096488 ± 735602 | 357638 ± 161481 | +738850 |

## Trials

| Setup | Trials | Statuses | Target skill loaded | Tokens (mean ± sd) | Wall s (mean ± sd) | Cost $ (mean, total) |
|---|---|---|---|---|---|---|
| with_skill | 12 | ok 12 | 12/12 | 1096488 ± 735602 | 254.3 ± 166.8 | 1.3033, 15.6401 |
| without_skill | 12 | ok 12 | 0/12 | 357638 ± 161481 | 167.6 ± 81.0 | 0.6049, 7.2590 |

Tokens count input, output, and cache reads and writes across every model the session used.

## Per trial

| Eval | Setup | Run | Status | Pass rate | Skills loaded | Tokens | Output tokens | Wall s | Cost $ |
|---|---|---|---|---|---|---|---|---|---|
| eval-1-placement-review | with_skill | 1 | ok | 1 | roblox-dev:roblox-performance, roblox-dev:luau-style-guide, roblox-dev:code-comments | 578558 | 7797 | 84.8 | 0.6381 |
| eval-1-placement-review | with_skill | 2 | ok | 1 | roblox-dev:roblox-performance, roblox-dev:luau-style-guide, roblox-dev:code-comments | 395273 | 7274 | 83.5 | 0.5057 |
| eval-1-placement-review | with_skill | 3 | ok | 1 | roblox-dev:roblox-performance, roblox-dev:luau-style-guide, roblox-dev:code-comments | 412683 | 8125 | 92.8 | 0.5461 |
| eval-1-placement-review | without_skill | 1 | ok | 1 | none | 145550 | 5400 | 70.1 | 0.2460 |
| eval-1-placement-review | without_skill | 2 | ok | 1 | none | 144431 | 5548 | 67.4 | 0.2522 |
| eval-1-placement-review | without_skill | 3 | ok | 1 | none | 145706 | 5554 | 69.2 | 0.2502 |
| eval-2-block-info-lag | with_skill | 1 | ok | 1 | roblox-dev:roblox-performance, roblox-dev:luau-style-guide, roblox-dev:code-comments | 605246 | 13916 | 143.2 | 0.7369 |
| eval-2-block-info-lag | with_skill | 2 | ok | 1 | roblox-dev:roblox-performance, roblox-dev:luau-style-guide, roblox-dev:code-comments | 664031 | 16483 | 164.8 | 0.8196 |
| eval-2-block-info-lag | with_skill | 3 | ok | 1 | roblox-dev:roblox-performance, roblox-dev:luau-style-guide, roblox-dev:code-comments | 565564 | 14733 | 146.7 | 0.8121 |
| eval-2-block-info-lag | without_skill | 1 | ok | 1 | none | 394970 | 11794 | 140.6 | 0.5398 |
| eval-2-block-info-lag | without_skill | 2 | ok | 1 | none | 264234 | 9435 | 107.8 | 0.4044 |
| eval-2-block-info-lag | without_skill | 3 | ok | 1 | none | 428343 | 12442 | 143.8 | 0.5322 |
| eval-3-ghost-network | with_skill | 1 | ok | 1 | roblox-dev:roblox-performance, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture, roblox-dev:roblox-testing, roblox-dev:roblox-testing | 2205774 | 52594 | 486.8 | 2.4984 |
| eval-3-ghost-network | with_skill | 2 | ok | 1 | roblox-dev:roblox-performance, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture, roblox-dev:roblox-performance | 1717835 | 51721 | 528.8 | 2.2958 |
| eval-3-ghost-network | with_skill | 3 | ok | 1 | roblox-dev:roblox-performance, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture, roblox-dev:roblox-performance, roblox-dev:roblox-testing | 1765644 | 45211 | 466.2 | 2.1964 |
| eval-3-ghost-network | without_skill | 1 | ok | 1 | none | 573193 | 28695 | 298.4 | 1.0592 |
| eval-3-ghost-network | without_skill | 2 | ok | 1 | none | 650874 | 25635 | 278.9 | 0.9817 |
| eval-3-ghost-network | without_skill | 3 | ok | 1 | none | 396807 | 22230 | 232.3 | 0.8190 |
| eval-4-build-loading | with_skill | 1 | ok | 1 | roblox-dev:roblox-performance, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:roblox-performance, roblox-dev:roblox-testing | 2451969 | 42480 | 378.4 | 2.2920 |
| eval-4-build-loading | with_skill | 2 | ok | 1 | roblox-dev:roblox-performance, roblox-dev:luau-style-guide, roblox-dev:code-comments | 1027413 | 23780 | 234.8 | 1.1648 |
| eval-4-build-loading | with_skill | 3 | ok | 1 | roblox-dev:roblox-performance, roblox-dev:luau-style-guide, roblox-dev:code-comments | 767862 | 25325 | 240.4 | 1.1342 |
| eval-4-build-loading | without_skill | 1 | ok | 1 | none | 363983 | 20864 | 226 | 0.7876 |
| eval-4-build-loading | without_skill | 2 | ok | 1 | none | 389526 | 16763 | 183 | 0.6828 |
| eval-4-build-loading | without_skill | 3 | ok | 1 | none | 394034 | 17630 | 193.2 | 0.7038 |

## Blind judge

| Eval | Pairs judged | with_skill wins | without_skill wins | Ties | Mean score with_skill | Mean score without_skill |
|---|---|---|---|---|---|---|
| eval-1-placement-review | 3/3 | 2 | 1 | 0 | 8.83 | 8.67 |
| eval-2-block-info-lag | 3/3 | 2 | 1 | 0 | 8.53 | 8.6 |
| eval-3-ghost-network | 3/3 | 3 | 0 | 0 | 8.17 | 6.67 |
| eval-4-build-loading | 3/3 | 2 | 1 | 0 | 8.17 | 7.5 |
| **All** | 12/12 | 9 | 3 | 0 | 8.42 | 7.86 |

Judge runs: 12, mean 26084 tokens and 30.2 s each, $2.4573 in total.
