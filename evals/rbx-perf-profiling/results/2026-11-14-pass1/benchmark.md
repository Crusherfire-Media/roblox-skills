# Skill Benchmark: rbx-perf-profiling

**Model**: claude-opus-5-5
**Date**: 2026-11-14T19:38:55Z
**Evals**: 1, 2, 3, 4 (3 runs each per configuration)

## Summary

| Metric | With Skill | Without Skill | Delta |
|--------|------------|---------------|-------|
| Pass Rate | 100% ± 0% | 91% ± 8% | +0.09 |
| Time | 166.0s ± 57.7s | 165.4s ± 72.3s | +0.6s |
| Tokens | 641398 ± 341237 | 448044 ± 254079 | +193354 |

## Trials

| Setup | Trials | Statuses | Target skill loaded | Tokens (mean ± sd) | Wall s (mean ± sd) | Cost $ (mean, total) |
|---|---|---|---|---|---|---|
| with_skill | 12 | ok 12 | 12/12 | 641398 ± 341237 | 166.0 ± 57.7 | 0.8919, 10.7027 |
| without_skill | 12 | ok 12 | 0/12 | 448044 ± 254079 | 165.4 ± 72.3 | 0.5470, 6.5639 |

Tokens count input, output, and cache reads and writes across every model the session used.

## Per trial

| Eval | Setup | Run | Status | Pass rate | Skills loaded | Tokens | Output tokens | Wall s | Cost $ |
|---|---|---|---|---|---|---|---|---|---|
| eval-1-stutter-diagnosis | with_skill | 1 | ok | 1 | roblox-dev:rbx-perf-profiling | 144257 | 9081 | 95.2 | 0.4512 |
| eval-1-stutter-diagnosis | with_skill | 2 | ok | 1 | roblox-dev:rbx-perf-profiling | 129712 | 7232 | 83.5 | 0.3573 |
| eval-1-stutter-diagnosis | with_skill | 3 | ok | 1 | roblox-dev:rbx-perf-profiling | 169178 | 8699 | 93.5 | 0.4180 |
| eval-1-stutter-diagnosis | without_skill | 1 | ok | 1 | none | 132351 | 9058 | 96.8 | 0.3898 |
| eval-1-stutter-diagnosis | without_skill | 2 | ok | 1 | none | 156126 | 9490 | 103.5 | 0.4080 |
| eval-1-stutter-diagnosis | without_skill | 3 | ok | 1 | none | 172168 | 8844 | 97.5 | 0.4028 |
| eval-2-spike-report | with_skill | 1 | ok | 1 | roblox-dev:rbx-perf-profiling, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 802031 | 24292 | 242.3 | 1.2618 |
| eval-2-spike-report | with_skill | 2 | ok | 1 | roblox-dev:rbx-perf-profiling, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 947718 | 17809 | 193.5 | 1.1339 |
| eval-2-spike-report | with_skill | 3 | ok | 1 | roblox-dev:rbx-perf-profiling, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 1150938 | 23243 | 238.4 | 1.3341 |
| eval-2-spike-report | without_skill | 1 | ok | 0.7778 | none | 660450 | 34485 | 231.5 | 0.7722 |
| eval-2-spike-report | without_skill | 2 | ok | 1 | none | 894646 | 34855 | 255.9 | 0.8908 |
| eval-2-spike-report | without_skill | 3 | ok | 0.8889 | none | 610211 | 38022 | 218.3 | 0.6439 |
| eval-3-fix-frame-report | with_skill | 1 | ok | 1 | roblox-dev:rbx-perf-profiling, roblox-dev:luau-style-guide, roblox-dev:code-comments | 812223 | 18859 | 204.4 | 1.0812 |
| eval-3-fix-frame-report | with_skill | 2 | ok | 1 | roblox-dev:rbx-perf-profiling, roblox-dev:luau-style-guide, roblox-dev:code-comments | 857490 | 16443 | 188.7 | 1.0248 |
| eval-3-fix-frame-report | with_skill | 3 | ok | 1 | roblox-dev:rbx-perf-profiling, roblox-dev:luau-style-guide, roblox-dev:code-comments | 478522 | 23861 | 228.1 | 1.1445 |
| eval-3-fix-frame-report | without_skill | 1 | ok | 0.875 | none | 608978 | 33532 | 233.8 | 0.7003 |
| eval-3-fix-frame-report | without_skill | 2 | ok | 0.875 | none | 704059 | 43025 | 282 | 0.7599 |
| eval-3-fix-frame-report | without_skill | 3 | ok | 0.875 | none | 185466 | 9024 | 94.8 | 0.4101 |
| eval-4-memory-script | with_skill | 1 | ok | 1 | roblox-dev:rbx-perf-profiling, roblox-dev:luau-style-guide, roblox-dev:code-comments | 793708 | 11820 | 135.9 | 0.8824 |
| eval-4-memory-script | with_skill | 2 | ok | 1 | roblox-dev:rbx-perf-profiling, roblox-dev:luau-style-guide, roblox-dev:code-comments | 571675 | 12536 | 143.1 | 0.7533 |
| eval-4-memory-script | with_skill | 3 | ok | 1 | roblox-dev:rbx-perf-profiling, roblox-dev:luau-style-guide, roblox-dev:code-comments | 839322 | 13077 | 145.3 | 0.8602 |
| eval-4-memory-script | without_skill | 1 | ok | 0.8571 | none | 366761 | 18199 | 127.7 | 0.3668 |
| eval-4-memory-script | without_skill | 2 | ok | 0.8571 | none | 367800 | 12637 | 106.4 | 0.3616 |
| eval-4-memory-script | without_skill | 3 | ok | 0.8571 | none | 517510 | 21659 | 136.4 | 0.4577 |

## Blind judge

| Eval | Pairs judged | with_skill wins | without_skill wins | Ties | Mean score with_skill | Mean score without_skill |
|---|---|---|---|---|---|---|
| eval-1-stutter-diagnosis | 3/3 | 2 | 1 | 0 | 8.73 | 8.67 |
| eval-2-spike-report | 3/3 | 1 | 2 | 0 | 7.33 | 7.33 |
| eval-3-fix-frame-report | 3/3 | 3 | 0 | 0 | 8.5 | 5.67 |
| eval-4-memory-script | 3/3 | 3 | 0 | 0 | 7.67 | 5.5 |
| **All** | 12/12 | 9 | 3 | 0 | 8.06 | 6.79 |

Judge runs: 12, mean 20472 tokens and 30.49 s each, $2.0257 in total.
