# Skill Benchmark: luau-style-guide

**Model**: claude-opus-5-5
**Date**: 2026-11-16T17:52:54Z
**Evals**: 1, 2, 3, 4 (3 runs each per configuration)

## Summary

| Metric | With Skill | Without Skill | Delta |
|--------|------------|---------------|-------|
| Pass Rate | 89% ± 9% | 78% ± 17% | +0.11 |
| Time | 177.1s ± 58.6s | 116.6s ± 25.4s | +60.6s |
| Tokens | 629967 ± 275780 | 299194 ± 109518 | +330772 |

## Trials

| Setup | Trials | Statuses | Target skill loaded | Tokens (mean ± sd) | Wall s (mean ± sd) | Cost $ (mean, total) |
|---|---|---|---|---|---|---|
| with_skill | 12 | ok 12 | 12/12 | 629967 ± 275780 | 177.1 ± 58.6 | 0.8262, 9.9143 |
| without_skill | 12 | ok 12 | 0/12 | 299194 ± 109518 | 116.6 ± 25.4 | 0.4666, 5.5995 |

Tokens count input, output, and cache reads and writes across every model the session used.

## Per trial

| Eval | Setup | Run | Status | Pass rate | Skills loaded | Tokens | Output tokens | Wall s | Cost $ |
|---|---|---|---|---|---|---|---|---|---|
| eval-1-block-inventory | with_skill | 1 | ok | 0.8182 | roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 654761 | 11475 | 141.5 | 0.8681 |
| eval-1-block-inventory | with_skill | 2 | ok | 0.9091 | roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 578967 | 12962 | 147.4 | 0.7834 |
| eval-1-block-inventory | with_skill | 3 | ok | 0.8182 | roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 805206 | 12083 | 150.7 | 0.8108 |
| eval-1-block-inventory | without_skill | 1 | ok | 0.5455 | none | 451247 | 8148 | 106.7 | 0.4660 |
| eval-1-block-inventory | without_skill | 2 | ok | 0.5455 | none | 259666 | 5950 | 75.5 | 0.3557 |
| eval-1-block-inventory | without_skill | 3 | ok | 0.5455 | none | 508612 | 9206 | 112.7 | 0.5372 |
| eval-2-refactor-plot-stats | with_skill | 1 | ok | 0.9286 | roblox-dev:luau-style-guide, roblox-dev:code-comments | 479117 | 16849 | 202.8 | 0.7498 |
| eval-2-refactor-plot-stats | with_skill | 2 | ok | 0.9286 | roblox-dev:luau-style-guide, roblox-dev:code-comments | 645302 | 27793 | 300.9 | 1.0710 |
| eval-2-refactor-plot-stats | with_skill | 3 | ok | 0.9286 | roblox-dev:luau-style-guide, roblox-dev:code-comments | 708173 | 24891 | 274.6 | 1.0357 |
| eval-2-refactor-plot-stats | without_skill | 1 | ok | 0.8571 | none | 297021 | 16278 | 167.2 | 0.6062 |
| eval-2-refactor-plot-stats | without_skill | 2 | ok | 0.8571 | none | 255232 | 11557 | 128.7 | 0.4387 |
| eval-2-refactor-plot-stats | without_skill | 3 | ok | 0.7857 | none | 252977 | 14016 | 146.8 | 0.5200 |
| eval-3-review-block-shop | with_skill | 1 | ok | 1 | roblox-dev:luau-style-guide | 270008 | 9485 | 108.6 | 0.5395 |
| eval-3-review-block-shop | with_skill | 2 | ok | 1 | roblox-dev:luau-style-guide | 333745 | 10812 | 123.3 | 0.5909 |
| eval-3-review-block-shop | with_skill | 3 | ok | 1 | roblox-dev:luau-style-guide | 456439 | 11853 | 139.4 | 0.6454 |
| eval-3-review-block-shop | without_skill | 1 | ok | 1 | none | 263199 | 11670 | 130.4 | 0.4861 |
| eval-3-review-block-shop | without_skill | 2 | ok | 1 | none | 105609 | 10923 | 116 | 0.3932 |
| eval-3-review-block-shop | without_skill | 3 | ok | 1 | none | 209338 | 11571 | 127.8 | 0.4714 |
| eval-4-ghost-preview | with_skill | 1 | ok | 0.75 | roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 553739 | 19802 | 190.4 | 0.9258 |
| eval-4-ghost-preview | with_skill | 2 | ok | 0.8333 | roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 1344365 | 14053 | 183.1 | 1.0558 |
| eval-4-ghost-preview | with_skill | 3 | ok | 0.75 | roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 729778 | 14063 | 162.9 | 0.8381 |
| eval-4-ghost-preview | without_skill | 1 | ok | 0.75 | none | 272791 | 8231 | 98.1 | 0.4254 |
| eval-4-ghost-preview | without_skill | 2 | ok | 0.75 | none | 407439 | 8055 | 96.1 | 0.4929 |
| eval-4-ghost-preview | without_skill | 3 | ok | 0.75 | none | 307200 | 7346 | 92.7 | 0.4066 |

## Blind judge

| Eval | Pairs judged | with_skill wins | without_skill wins | Ties | Mean score with_skill | Mean score without_skill |
|---|---|---|---|---|---|---|
| eval-1-block-inventory | 3/3 | 3 | 0 | 0 | 8.83 | 5.67 |
| eval-2-refactor-plot-stats | 3/3 | 1 | 2 | 0 | 6.83 | 7 |
| eval-3-review-block-shop | 3/3 | 3 | 0 | 0 | 9 | 7.17 |
| eval-4-ghost-preview | 3/3 | 1 | 2 | 0 | 7.67 | 7.67 |
| **All** | 12/12 | 8 | 4 | 0 | 8.08 | 6.88 |

Judge runs: 12, mean 24000 tokens and 32.22 s each, $1.9857 in total.
