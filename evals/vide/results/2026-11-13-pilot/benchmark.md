# Skill Benchmark: vide

**Model**: claude-opus-5-5
**Date**: 2026-11-14T07:36:36Z
**Evals**: 1, 2, 3, 4 (3 runs each per configuration)

## Summary

| Metric | With Skill | Without Skill | Delta |
|--------|------------|---------------|-------|
| Pass Rate | 100% ± 0% | 96% ± 7% | +0.04 |
| Time | 283.9s ± 174.0s | 153.5s ± 71.1s | +130.4s |
| Tokens | 1700430 ± 998690 | 520006 ± 212947 | +1180424 |

## Trials

| Setup | Trials | Statuses | Target skill loaded | Tokens (mean ± sd) | Wall s (mean ± sd) | Cost $ (mean, total) |
|---|---|---|---|---|---|---|
| with_skill | 12 | ok 12 | 12/12 | 1700430 ± 998690 | 283.9 ± 174.0 | 1.5026, 18.0312 |
| without_skill | 12 | ok 12 | 0/12 | 520006 ± 212947 | 153.5 ± 71.1 | 0.6515, 7.8180 |

Tokens count input, output, and cache reads and writes across every model the session used.

## Per trial

| Eval | Setup | Run | Status | Pass rate | Skills loaded | Tokens | Output tokens | Wall s | Cost $ |
|---|---|---|---|---|---|---|---|---|---|
| eval-1-block-picker | with_skill | 1 | ok | 1 | roblox-dev:vide, roblox-dev:roblox-lua-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture, roblox-dev:vide-ui-labs | 1697371 | 23415 | 265.6 | 1.4979 |
| eval-1-block-picker | with_skill | 2 | ok | 1 | roblox-dev:vide, roblox-dev:roblox-lua-style-guide, roblox-dev:game-architecture, roblox-dev:code-comments, roblox-dev:vide-ui-labs | 1337404 | 24018 | 269 | 1.3836 |
| eval-1-block-picker | with_skill | 3 | ok | 1 | roblox-dev:vide, roblox-dev:roblox-lua-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture, roblox-dev:vide-ui-labs, roblox-dev:vide, roblox-dev:game-ui-design | 3214834 | 51394 | 574.2 | 2.8373 |
| eval-1-block-picker | without_skill | 1 | ok | 1 | none | 446444 | 9774 | 117.3 | 0.5192 |
| eval-1-block-picker | without_skill | 2 | ok | 1 | none | 321088 | 7136 | 88.5 | 0.3947 |
| eval-1-block-picker | without_skill | 3 | ok | 1 | none | 390775 | 12323 | 134.8 | 0.5792 |
| eval-2-fix-picker | with_skill | 1 | ok | 1 | roblox-dev:vide, roblox-dev:roblox-lua-style-guide, roblox-dev:vide-ui-labs, roblox-dev:code-comments | 774976 | 9956 | 126.3 | 0.7284 |
| eval-2-fix-picker | with_skill | 2 | ok | 1 | roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:roblox-lua-style-guide, roblox-dev:code-comments | 872737 | 13117 | 155.7 | 0.8745 |
| eval-2-fix-picker | with_skill | 3 | ok | 1 | roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:roblox-lua-style-guide, roblox-dev:code-comments | 759355 | 9625 | 120.3 | 0.7080 |
| eval-2-fix-picker | without_skill | 1 | ok | 1 | none | 321206 | 8360 | 99.8 | 0.4212 |
| eval-2-fix-picker | without_skill | 2 | ok | 0.8571 | none | 403355 | 7790 | 90.3 | 0.4635 |
| eval-2-fix-picker | without_skill | 3 | ok | 0.8571 | none | 627171 | 9044 | 113.9 | 0.5562 |
| eval-3-picker-screens | with_skill | 1 | ok | 1 | roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:roblox-lua-style-guide, roblox-dev:game-ui-design, roblox-dev:code-comments, roblox-dev:game-architecture | 1392156 | 27188 | 288.1 | 1.5696 |
| eval-3-picker-screens | with_skill | 2 | ok | 1 | roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:roblox-lua-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 2785229 | 29889 | 354.6 | 2.0362 |
| eval-3-picker-screens | with_skill | 3 | ok | 1 | roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:roblox-lua-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture, roblox-dev:vide | 3632836 | 58773 | 670 | 3.1252 |
| eval-3-picker-screens | without_skill | 1 | ok | 1 | none | 553482 | 21212 | 226.9 | 0.8498 |
| eval-3-picker-screens | without_skill | 2 | ok | 1 | none | 1070281 | 27265 | 306 | 1.1672 |
| eval-3-picker-screens | without_skill | 3 | ok | 1 | none | 730705 | 24101 | 259.9 | 1.0148 |
| eval-4-picker-motion | with_skill | 1 | ok | 1 | roblox-dev:vide, roblox-dev:roblox-lua-style-guide, roblox-dev:vide-ui-labs, roblox-dev:code-comments | 1012337 | 17012 | 188.3 | 1.0641 |
| eval-4-picker-motion | with_skill | 2 | ok | 1 | roblox-dev:vide, roblox-dev:roblox-lua-style-guide, roblox-dev:vide-ui-labs, roblox-dev:code-comments | 949860 | 14426 | 167.1 | 0.9045 |
| eval-4-picker-motion | with_skill | 3 | ok | 1 | roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:roblox-lua-style-guide, roblox-dev:code-comments | 1976068 | 17209 | 227.5 | 1.3019 |
| eval-4-picker-motion | without_skill | 1 | ok | 0.8333 | none | 474560 | 10379 | 121.2 | 0.6070 |
| eval-4-picker-motion | without_skill | 2 | ok | 1 | none | 529467 | 12804 | 146.3 | 0.7014 |
| eval-4-picker-motion | without_skill | 3 | ok | 1 | none | 371535 | 11600 | 137.3 | 0.5439 |

## Blind judge

| Eval | Pairs judged | with_skill wins | without_skill wins | Ties | Mean score with_skill | Mean score without_skill |
|---|---|---|---|---|---|---|
| eval-1-block-picker | 3/3 | 2 | 1 | 0 | 8.5 | 7.83 |
| eval-2-fix-picker | 3/3 | 2 | 1 | 0 | 8.83 | 8.33 |
| eval-3-picker-screens | 3/3 | 3 | 0 | 0 | 8.5 | 7 |
| eval-4-picker-motion | 3/3 | 1 | 2 | 0 | 7.83 | 8.17 |
| **All** | 12/12 | 8 | 4 | 0 | 8.42 | 7.83 |

Judge runs: 12, mean 19061 tokens and 29.92 s each, $2.0107 in total.
