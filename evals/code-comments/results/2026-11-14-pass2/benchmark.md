# Skill Benchmark: code-comments

**Model**: claude-opus-5-5
**Date**: 2026-11-14T15:46:13Z
**Evals**: 1, 2, 3, 4 (3 runs each per configuration)

## Summary

| Metric | With Skill | Without Skill | Delta |
|--------|------------|---------------|-------|
| Pass Rate | 99% ± 3% | 89% ± 8% | +0.10 |
| Time | 99.7s ± 18.5s | 58.3s ± 25.0s | +41.4s |
| Tokens | 362595 ± 117470 | 139291 ± 54702 | +223303 |

## Trials

| Setup | Trials | Statuses | Target skill loaded | Tokens (mean ± sd) | Wall s (mean ± sd) | Cost $ (mean, total) |
|---|---|---|---|---|---|---|
| with_skill | 12 | ok 12 | 12/12 | 362595 ± 117470 | 99.7 ± 18.5 | 0.5537, 6.6448 |
| without_skill | 12 | ok 12 | 0/12 | 139291 ± 54702 | 58.3 ± 25.0 | 0.2520, 3.0237 |

Tokens count input, output, and cache reads and writes across every model the session used.

## Per trial

| Eval | Setup | Run | Status | Pass rate | Skills loaded | Tokens | Output tokens | Wall s | Cost $ |
|---|---|---|---|---|---|---|---|---|---|
| eval-1-placement-rules | with_skill | 1 | ok | 1 | roblox-dev:roblox-lua-style-guide, roblox-dev:game-architecture, roblox-dev:code-comments | 247698 | 7901 | 103.9 | 0.4920 |
| eval-1-placement-rules | with_skill | 2 | ok | 1 | roblox-dev:roblox-lua-style-guide, roblox-dev:game-architecture, roblox-dev:code-comments | 341904 | 9659 | 112.9 | 0.5309 |
| eval-1-placement-rules | with_skill | 3 | ok | 1 | roblox-dev:roblox-lua-style-guide, roblox-dev:game-architecture, roblox-dev:code-comments | 235428 | 10078 | 108.3 | 0.5189 |
| eval-1-placement-rules | without_skill | 1 | ok | 0.8571 | none | 231846 | 9730 | 112.2 | 0.3862 |
| eval-1-placement-rules | without_skill | 2 | ok | 1 | none | 115292 | 6745 | 73.4 | 0.2485 |
| eval-1-placement-rules | without_skill | 3 | ok | 1 | none | 143778 | 8316 | 93.2 | 0.3013 |
| eval-2-placement-server | with_skill | 1 | ok | 1 | roblox-dev:roblox-lua-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 591182 | 9149 | 121.6 | 0.6195 |
| eval-2-placement-server | with_skill | 2 | ok | 1 | roblox-dev:roblox-lua-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 448225 | 9279 | 110.8 | 0.5574 |
| eval-2-placement-server | with_skill | 3 | ok | 1 | roblox-dev:roblox-lua-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 585337 | 10868 | 133.5 | 0.6898 |
| eval-2-placement-server | without_skill | 1 | ok | 0.875 | none | 150324 | 4128 | 47 | 0.2587 |
| eval-2-placement-server | without_skill | 2 | ok | 1 | none | 165838 | 3912 | 53.1 | 0.2278 |
| eval-2-placement-server | without_skill | 3 | ok | 0.875 | none | 191256 | 4154 | 52.2 | 0.2405 |
| eval-3-cleanup-placement-server | with_skill | 1 | ok | 1 | roblox-dev:code-comments, roblox-dev:roblox-lua-style-guide | 320665 | 8515 | 85.4 | 0.4927 |
| eval-3-cleanup-placement-server | with_skill | 2 | ok | 1 | roblox-dev:code-comments, roblox-dev:roblox-lua-style-guide | 322154 | 8989 | 89.7 | 0.4920 |
| eval-3-cleanup-placement-server | with_skill | 3 | ok | 1 | roblox-dev:code-comments, roblox-dev:roblox-lua-style-guide | 307280 | 8687 | 96.5 | 0.4729 |
| eval-3-cleanup-placement-server | without_skill | 1 | ok | 0.9091 | none | 175203 | 5549 | 65.7 | 0.2635 |
| eval-3-cleanup-placement-server | without_skill | 2 | ok | 0.9091 | none | 171240 | 5188 | 56.5 | 0.2521 |
| eval-3-cleanup-placement-server | without_skill | 3 | ok | 0.9091 | none | 140664 | 4790 | 53 | 0.2312 |
| eval-4-cleanup-block-picker | with_skill | 1 | ok | 0.9444 | roblox-dev:code-comments, roblox-dev:vide, roblox-dev:roblox-lua-style-guide, roblox-dev:vide-ui-labs | 307982 | 6539 | 75.4 | 0.5883 |
| eval-4-cleanup-block-picker | with_skill | 2 | ok | 0.9444 | roblox-dev:code-comments, roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:roblox-lua-style-guide | 321502 | 6649 | 79.4 | 0.5934 |
| eval-4-cleanup-block-picker | with_skill | 3 | ok | 0.9444 | roblox-dev:code-comments, roblox-dev:vide, roblox-dev:vide-ui-labs, roblox-dev:roblox-lua-style-guide | 321778 | 6821 | 78.7 | 0.5971 |
| eval-4-cleanup-block-picker | without_skill | 1 | ok | 0.7778 | none | 62246 | 2860 | 33.2 | 0.2420 |
| eval-4-cleanup-block-picker | without_skill | 2 | ok | 0.7778 | none | 61963 | 2708 | 27.9 | 0.2380 |
| eval-4-cleanup-block-picker | without_skill | 3 | ok | 0.7778 | none | 61846 | 2680 | 32 | 0.1341 |

## Blind judge

| Eval | Pairs judged | with_skill wins | without_skill wins | Ties | Mean score with_skill | Mean score without_skill |
|---|---|---|---|---|---|---|
| eval-1-placement-rules | 3/3 | 3 | 0 | 0 | 8.5 | 7.33 |
| eval-2-placement-server | 3/3 | 1 | 2 | 0 | 7.83 | 8 |
| eval-3-cleanup-placement-server | 3/3 | 3 | 0 | 0 | 9.33 | 6.67 |
| eval-4-cleanup-block-picker | 3/3 | 3 | 0 | 0 | 9 | 6.83 |
| **All** | 12/12 | 10 | 2 | 0 | 8.67 | 7.21 |

Judge runs: 12, mean 16612 tokens and 24.08 s each, $1.5534 in total.
