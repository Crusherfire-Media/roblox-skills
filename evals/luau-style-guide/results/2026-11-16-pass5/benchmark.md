# Skill Benchmark: luau-style-guide

**Model**: claude-opus-5-5
**Date**: 2026-11-16T18:20:06Z
**Evals**: 1, 2, 3, 4 (3 runs each per configuration)

## Summary

| Metric | With Skill | Without Skill | Delta |
|--------|------------|---------------|-------|
| Pass Rate | 90% ± 7% | 81% ± 16% | +0.10 |
| Time | 156.5s ± 46.3s | 122.3s ± 49.7s | +34.2s |
| Tokens | 539744 ± 272824 | 370497 ± 209884 | +169248 |

## Trials

| Setup | Trials | Statuses | Target skill loaded | Tokens (mean ± sd) | Wall s (mean ± sd) | Cost $ (mean, total) |
|---|---|---|---|---|---|---|
| with_skill | 12 | ok 12 | 12/12 | 539744 ± 272824 | 156.5 ± 46.3 | 0.7397, 8.8764 |
| without_skill | 12 | ok 12 | 0/12 | 370497 ± 209884 | 122.3 ± 49.7 | 0.5171, 6.2052 |

Tokens count input, output, and cache reads and writes across every model the session used.

## Per trial

| Eval | Setup | Run | Status | Pass rate | Skills loaded | Tokens | Output tokens | Wall s | Cost $ |
|---|---|---|---|---|---|---|---|---|---|
| eval-1-block-inventory | with_skill | 1 | ok | 0.9091 | roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 437176 | 9829 | 105.4 | 0.5689 |
| eval-1-block-inventory | with_skill | 2 | ok | 0.8182 | roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 445807 | 10618 | 108.8 | 0.5888 |
| eval-1-block-inventory | with_skill | 3 | ok | 0.8182 | roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 580064 | 9123 | 98.6 | 0.5842 |
| eval-1-block-inventory | without_skill | 1 | ok | 0.6364 | none | 704238 | 14762 | 153.9 | 0.7119 |
| eval-1-block-inventory | without_skill | 2 | ok | 0.6364 | none | 447570 | 11093 | 113.8 | 0.5660 |
| eval-1-block-inventory | without_skill | 3 | ok | 0.5455 | none | 443082 | 8180 | 82.9 | 0.4958 |
| eval-2-refactor-plot-stats | with_skill | 1 | ok | 0.9286 | roblox-dev:luau-style-guide, roblox-dev:code-comments | 383892 | 19485 | 221.5 | 0.7879 |
| eval-2-refactor-plot-stats | with_skill | 2 | ok | 0.9286 | roblox-dev:luau-style-guide, roblox-dev:code-comments | 401203 | 17113 | 184.9 | 0.7175 |
| eval-2-refactor-plot-stats | with_skill | 3 | ok | 0.9286 | roblox-dev:luau-style-guide, roblox-dev:code-comments | 535234 | 22883 | 247.5 | 0.9363 |
| eval-2-refactor-plot-stats | without_skill | 1 | ok | 0.6429 | none | 816824 | 23367 | 252 | 0.9325 |
| eval-2-refactor-plot-stats | without_skill | 2 | ok | 0.8571 | none | 189045 | 13479 | 135.9 | 0.4926 |
| eval-2-refactor-plot-stats | without_skill | 3 | ok | 0.9286 | none | 381980 | 13675 | 159.4 | 0.5706 |
| eval-3-review-block-shop | with_skill | 1 | ok | 1 | roblox-dev:luau-style-guide | 189088 | 11466 | 129.3 | 0.5530 |
| eval-3-review-block-shop | with_skill | 2 | ok | 1 | roblox-dev:luau-style-guide | 321120 | 11261 | 133.1 | 0.5992 |
| eval-3-review-block-shop | with_skill | 3 | ok | 1 | roblox-dev:luau-style-guide | 331437 | 13133 | 147.8 | 0.6527 |
| eval-3-review-block-shop | without_skill | 1 | ok | 1 | none | 236708 | 10008 | 115.8 | 0.4340 |
| eval-3-review-block-shop | without_skill | 2 | ok | 1 | none | 200977 | 9275 | 110.9 | 0.4016 |
| eval-3-review-block-shop | without_skill | 3 | ok | 1 | none | 168292 | 8682 | 102.3 | 0.3790 |
| eval-4-ghost-preview | with_skill | 1 | ok | 0.8333 | roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 894424 | 16699 | 174.6 | 0.9823 |
| eval-4-ghost-preview | with_skill | 2 | ok | 0.8333 | roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 1098956 | 13418 | 151.5 | 0.9207 |
| eval-4-ghost-preview | with_skill | 3 | ok | 0.8333 | roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 858531 | 17292 | 175 | 0.9849 |
| eval-4-ghost-preview | without_skill | 1 | ok | 0.8333 | none | 388828 | 8418 | 85.5 | 0.4661 |
| eval-4-ghost-preview | without_skill | 2 | ok | 0.8333 | none | 282679 | 6751 | 66.2 | 0.4194 |
| eval-4-ghost-preview | without_skill | 3 | ok | 0.75 | none | 185738 | 8004 | 88.9 | 0.3357 |

## Blind judge

| Eval | Pairs judged | with_skill wins | without_skill wins | Ties | Mean score with_skill | Mean score without_skill |
|---|---|---|---|---|---|---|
| eval-1-block-inventory | 3/3 | 3 | 0 | 0 | 8.83 | 6.83 |
| eval-2-refactor-plot-stats | 3/3 | 3 | 0 | 0 | 8 | 6.5 |
| eval-3-review-block-shop | 3/3 | 3 | 0 | 0 | 9.27 | 7 |
| eval-4-ghost-preview | 3/3 | 2 | 1 | 0 | 7.83 | 8.33 |
| **All** | 12/12 | 11 | 1 | 0 | 8.48 | 7.17 |

Judge runs: 12, mean 27774 tokens and 34 s each, $2.1013 in total.
