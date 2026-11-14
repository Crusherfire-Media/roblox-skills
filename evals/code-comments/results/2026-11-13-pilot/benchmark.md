# Skill Benchmark: code-comments

**Model**: claude-opus-5-5
**Date**: 2026-11-14T07:16:49Z
**Evals**: 1, 2, 3, 4 (3 runs each per configuration)

## Summary

| Metric | With Skill | Without Skill | Delta |
|--------|------------|---------------|-------|
| Pass Rate | 99% ± 4% | 91% ± 7% | +0.08 |
| Time | 102.0s ± 21.4s | 66.3s ± 31.2s | +35.8s |
| Tokens | 409530 ± 108914 | 176223 ± 86280 | +233307 |

## Trials

| Setup | Trials | Statuses | Target skill loaded | Tokens (mean ± sd) | Wall s (mean ± sd) | Cost $ (mean, total) |
|---|---|---|---|---|---|---|
| with_skill | 12 | ok 12 | 12/12 | 409530 ± 108914 | 102.0 ± 21.4 | 0.5405, 6.4860 |
| without_skill | 12 | ok 12 | 0/12 | 176223 ± 86280 | 66.3 ± 31.2 | 0.2753, 3.3041 |

Tokens count input, output, and cache reads and writes across every model the session used.

## Per trial

| Eval | Setup | Run | Status | Pass rate | Skills loaded | Tokens | Output tokens | Wall s | Cost $ |
|---|---|---|---|---|---|---|---|---|---|
| eval-1-placement-rules | with_skill | 1 | ok | 1 | roblox-dev:roblox-lua-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 472850 | 8914 | 119.3 | 0.5059 |
| eval-1-placement-rules | with_skill | 2 | ok | 1 | roblox-dev:roblox-lua-style-guide, roblox-dev:game-architecture, roblox-dev:code-comments, roblox-dev:rojo-workflow | 380442 | 9426 | 121.3 | 0.5323 |
| eval-1-placement-rules | with_skill | 3 | ok | 1 | roblox-dev:roblox-lua-style-guide, roblox-dev:game-architecture, roblox-dev:code-comments | 502642 | 10716 | 137.7 | 0.5761 |
| eval-1-placement-rules | without_skill | 1 | ok | 0.8571 | none | 282378 | 10265 | 124.6 | 0.4216 |
| eval-1-placement-rules | without_skill | 2 | ok | 0.8571 | none | 227780 | 7729 | 95.1 | 0.3066 |
| eval-1-placement-rules | without_skill | 3 | ok | 1 | none | 233397 | 9520 | 112.7 | 0.3589 |
| eval-2-placement-server | with_skill | 1 | ok | 1 | roblox-dev:roblox-lua-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 464889 | 8257 | 99.4 | 0.5453 |
| eval-2-placement-server | with_skill | 2 | ok | 0.875 | roblox-dev:roblox-lua-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 599204 | 11598 | 132.9 | 0.7404 |
| eval-2-placement-server | with_skill | 3 | ok | 1 | roblox-dev:roblox-lua-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 578684 | 9008 | 110.1 | 0.6567 |
| eval-2-placement-server | without_skill | 1 | ok | 1 | none | 206263 | 5026 | 64.6 | 0.2735 |
| eval-2-placement-server | without_skill | 2 | ok | 0.875 | none | 195314 | 4325 | 53 | 0.2485 |
| eval-2-placement-server | without_skill | 3 | ok | 1 | none | 325227 | 5796 | 76.6 | 0.3584 |
| eval-3-cleanup-placement-server | with_skill | 1 | ok | 1 | roblox-dev:code-comments, roblox-dev:roblox-lua-style-guide | 311780 | 8362 | 87.2 | 0.4713 |
| eval-3-cleanup-placement-server | with_skill | 2 | ok | 1 | roblox-dev:code-comments, roblox-dev:roblox-lua-style-guide | 312226 | 8687 | 90.6 | 0.4795 |
| eval-3-cleanup-placement-server | with_skill | 3 | ok | 1 | roblox-dev:code-comments, roblox-dev:roblox-lua-style-guide | 308745 | 7890 | 87.1 | 0.4567 |
| eval-3-cleanup-placement-server | without_skill | 1 | ok | 0.9524 | none | 145815 | 5396 | 65.7 | 0.2485 |
| eval-3-cleanup-placement-server | without_skill | 2 | ok | 0.9524 | none | 144396 | 4925 | 52 | 0.2349 |
| eval-3-cleanup-placement-server | without_skill | 3 | ok | 0.9048 | none | 168462 | 5147 | 57 | 0.2436 |
| eval-4-cleanup-block-picker | with_skill | 1 | ok | 1 | roblox-dev:code-comments, roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:roblox-lua-style-guide | 327140 | 6936 | 81.5 | 0.5052 |
| eval-4-cleanup-block-picker | with_skill | 2 | ok | 1 | roblox-dev:code-comments, roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:roblox-lua-style-guide | 328831 | 7150 | 81 | 0.5124 |
| eval-4-cleanup-block-picker | with_skill | 3 | ok | 1 | roblox-dev:code-comments, roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:roblox-lua-style-guide | 326925 | 6908 | 76.5 | 0.5044 |
| eval-4-cleanup-block-picker | without_skill | 1 | ok | 0.8333 | none | 61817 | 2689 | 31.6 | 0.2366 |
| eval-4-cleanup-block-picker | without_skill | 2 | ok | 0.8333 | none | 61816 | 2645 | 26.8 | 0.2361 |
| eval-4-cleanup-block-picker | without_skill | 3 | ok | 0.8333 | none | 62007 | 2780 | 35.4 | 0.1367 |

## Blind judge

| Eval | Pairs judged | with_skill wins | without_skill wins | Ties | Mean score with_skill | Mean score without_skill |
|---|---|---|---|---|---|---|
| eval-1-placement-rules | 3/3 | 3 | 0 | 0 | 8.5 | 7.33 |
| eval-2-placement-server | 3/3 | 1 | 2 | 0 | 7.67 | 8.5 |
| eval-3-cleanup-placement-server | 3/3 | 3 | 0 | 0 | 9.33 | 6.33 |
| eval-4-cleanup-block-picker | 3/3 | 3 | 0 | 0 | 9.17 | 6.83 |
| **All** | 12/12 | 10 | 2 | 0 | 8.67 | 7.25 |

Judge runs: 12, mean 13502 tokens and 22.08 s each, $1.3611 in total.
