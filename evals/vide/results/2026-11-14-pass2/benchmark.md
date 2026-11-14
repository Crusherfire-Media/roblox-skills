# Skill Benchmark: vide

**Model**: claude-opus-5-5
**Date**: 2026-11-14T16:04:26Z
**Evals**: 1, 2, 3, 4 (3 runs each per configuration)

## Summary

| Metric | With Skill | Without Skill | Delta |
|--------|------------|---------------|-------|
| Pass Rate | 99% ± 4% | 96% ± 7% | +0.03 |
| Time | 297.2s ± 183.0s | 153.5s ± 71.1s | +143.7s |
| Tokens | 1759305 ± 989184 | 520006 ± 212947 | +1239300 |

## Trials

| Setup | Trials | Statuses | Target skill loaded | Tokens (mean ± sd) | Wall s (mean ± sd) | Cost $ (mean, total) |
|---|---|---|---|---|---|---|
| with_skill | 12 | ok 12 | 12/12 | 1759305 ± 989184 | 297.2 ± 183.0 | 1.5275, 18.3306 |
| without_skill | 12 | ok 12 | 0/12 | 520006 ± 212947 | 153.5 ± 71.1 | 0.6515, 7.8180 |

Tokens count input, output, and cache reads and writes across every model the session used.

## Per trial

| Eval | Setup | Run | Status | Pass rate | Skills loaded | Tokens | Output tokens | Wall s | Cost $ |
|---|---|---|---|---|---|---|---|---|---|
| eval-1-block-picker | with_skill | 1 | ok | 1 | roblox-dev:vide, roblox-dev:roblox-lua-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture, roblox-dev:vide-ui-labs | 1519665 | 24615 | 284.9 | 1.4674 |
| eval-1-block-picker | with_skill | 2 | ok | 1 | roblox-dev:vide, roblox-dev:roblox-lua-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture, roblox-dev:vide-ui-labs | 1551440 | 25501 | 291.6 | 1.4681 |
| eval-1-block-picker | with_skill | 3 | ok | 1 | roblox-dev:vide, roblox-dev:roblox-lua-style-guide, roblox-dev:game-ui-design, roblox-dev:code-comments, roblox-dev:game-architecture, roblox-dev:vide-ui-labs | 1492446 | 21867 | 247.4 | 1.4114 |
| eval-1-block-picker | without_skill | 1 | ok | 1 | none | 446444 | 9774 | 117.3 | 0.5192 |
| eval-1-block-picker | without_skill | 2 | ok | 1 | none | 321088 | 7136 | 88.5 | 0.3947 |
| eval-1-block-picker | without_skill | 3 | ok | 1 | none | 390775 | 12323 | 134.8 | 0.5792 |
| eval-2-fix-picker | with_skill | 1 | ok | 1 | roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:roblox-lua-style-guide, roblox-dev:code-comments | 1077640 | 11338 | 156.9 | 0.8638 |
| eval-2-fix-picker | with_skill | 2 | ok | 1 | roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:roblox-lua-style-guide, roblox-dev:code-comments | 1002964 | 10141 | 139.2 | 0.7717 |
| eval-2-fix-picker | with_skill | 3 | ok | 1 | roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:roblox-lua-style-guide, roblox-dev:code-comments | 741293 | 9583 | 122.9 | 0.7050 |
| eval-2-fix-picker | without_skill | 1 | ok | 1 | none | 321206 | 8360 | 99.8 | 0.4212 |
| eval-2-fix-picker | without_skill | 2 | ok | 0.8571 | none | 403355 | 7790 | 90.3 | 0.4635 |
| eval-2-fix-picker | without_skill | 3 | ok | 0.8571 | none | 627171 | 9044 | 113.9 | 0.5562 |
| eval-3-picker-screens | with_skill | 1 | ok | 1 | roblox-dev:vide, roblox-dev:roblox-lua-style-guide, roblox-dev:vide-ui-labs, roblox-dev:code-comments, roblox-dev:game-architecture | 2315837 | 39248 | 433.8 | 2.0572 |
| eval-3-picker-screens | with_skill | 2 | ok | 0.8571 | roblox-dev:vide, roblox-dev:roblox-lua-style-guide, roblox-dev:vide-ui-labs, roblox-dev:game-ui-design, roblox-dev:code-comments, roblox-dev:game-architecture, roblox-dev:vide, roblox-dev:vide-ui-labs | 3914976 | 59710 | 678.2 | 3.3470 |
| eval-3-picker-screens | with_skill | 3 | ok | 1 | roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:roblox-lua-style-guide, roblox-dev:game-ui-design, roblox-dev:code-comments, roblox-dev:game-architecture, roblox-dev:vide, roblox-dev:vide-ui-labs | 3352811 | 53738 | 609.2 | 2.9789 |
| eval-3-picker-screens | without_skill | 1 | ok | 1 | none | 553482 | 21212 | 226.9 | 0.8498 |
| eval-3-picker-screens | without_skill | 2 | ok | 1 | none | 1070281 | 27265 | 306 | 1.1672 |
| eval-3-picker-screens | without_skill | 3 | ok | 1 | none | 730705 | 24101 | 259.9 | 1.0148 |
| eval-4-picker-motion | with_skill | 1 | ok | 1 | roblox-dev:vide, roblox-dev:roblox-lua-style-guide, roblox-dev:vide-ui-labs, roblox-dev:code-comments | 1757234 | 15336 | 216.8 | 1.2040 |
| eval-4-picker-motion | with_skill | 2 | ok | 1 | roblox-dev:vide, roblox-dev:roblox-lua-style-guide, roblox-dev:vide-ui-labs, roblox-dev:code-comments | 756572 | 14313 | 168.1 | 0.8512 |
| eval-4-picker-motion | with_skill | 3 | ok | 1 | roblox-dev:vide, roblox-dev:roblox-lua-style-guide, roblox-dev:vide-ui-labs, roblox-dev:code-comments | 1628785 | 16464 | 217.5 | 1.2047 |
| eval-4-picker-motion | without_skill | 1 | ok | 0.8333 | none | 474560 | 10379 | 121.2 | 0.6070 |
| eval-4-picker-motion | without_skill | 2 | ok | 1 | none | 529467 | 12804 | 146.3 | 0.7014 |
| eval-4-picker-motion | without_skill | 3 | ok | 1 | none | 371535 | 11600 | 137.3 | 0.5439 |

## Blind judge

| Eval | Pairs judged | with_skill wins | without_skill wins | Ties | Mean score with_skill | Mean score without_skill |
|---|---|---|---|---|---|---|
| eval-1-block-picker | 3/3 | 2 | 1 | 0 | 8.33 | 7.83 |
| eval-2-fix-picker | 3/3 | 3 | 0 | 0 | 9.17 | 8 |
| eval-3-picker-screens | 3/3 | 3 | 0 | 0 | 7.83 | 7 |
| eval-4-picker-motion | 3/3 | 2 | 1 | 0 | 8.17 | 8.17 |
| **All** | 12/12 | 10 | 2 | 0 | 8.38 | 7.75 |

Judge runs: 12, mean 20023 tokens and 32.29 s each, $2.0505 in total.
