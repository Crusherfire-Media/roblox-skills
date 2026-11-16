# Skill Benchmark: game-architecture

**Model**: claude-opus-5-5
**Date**: 2026-11-14T17:20:08Z
**Evals**: 1, 2, 3, 4, 5 (3 runs each per configuration)

## Summary

| Metric | With Skill | Without Skill | Delta |
|--------|------------|---------------|-------|
| Pass Rate | 88% ± 7% | 85% ± 8% | +0.03 |
| Time | 226.9s ± 189.6s | 165.0s ± 114.3s | +61.9s |
| Tokens | 947835 ± 669827 | 752361 ± 652326 | +195474 |

## Trials

| Setup | Trials | Statuses | Target skill loaded | Tokens (mean ± sd) | Wall s (mean ± sd) | Cost $ (mean, total) |
|---|---|---|---|---|---|---|
| with_skill | 15 | ok 15 | 14/15 | 947835 ± 669827 | 226.9 ± 189.6 | 1.0101, 15.1516 |
| without_skill | 15 | ok 15 | 0/15 | 752361 ± 652326 | 165.0 ± 114.3 | 0.7867, 11.7999 |

Tokens count input, output, and cache reads and writes across every model the session used.

## Per trial

| Eval | Setup | Run | Status | Pass rate | Skills loaded | Tokens | Output tokens | Wall s | Cost $ |
|---|---|---|---|---|---|---|---|---|---|
| eval-1-placement-system | with_skill | 1 | ok | 0.875 | roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:rojo-workflow, roblox-dev:code-comments, roblox-dev:game-architecture | 2544669 | 60245 | 673.7 | 2.6731 |
| eval-1-placement-system | with_skill | 2 | ok | 0.875 | roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:rojo-workflow, roblox-dev:code-comments, roblox-dev:game-architecture, roblox-dev:roblox-testing | 2241660 | 48508 | 573.8 | 2.3315 |
| eval-1-placement-system | with_skill | 3 | ok | 0.875 | roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 1731521 | 42695 | 488.5 | 1.9933 |
| eval-1-placement-system | without_skill | 1 | ok | 0.875 | none | 2616614 | 36521 | 427.3 | 1.9814 |
| eval-1-placement-system | without_skill | 2 | ok | 0.875 | none | 1394199 | 29255 | 341.5 | 1.3557 |
| eval-1-placement-system | without_skill | 3 | ok | 0.875 | none | 1674711 | 32453 | 360.9 | 1.6311 |
| eval-2-block-cost | with_skill | 1 | ok | 0.8333 | roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:code-comments | 765161 | 10981 | 160.6 | 0.7707 |
| eval-2-block-cost | with_skill | 2 | ok | 0.8333 | roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:code-comments | 832048 | 11253 | 168 | 0.7441 |
| eval-2-block-cost | with_skill | 3 | ok | 0.8333 | roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:code-comments | 832041 | 13179 | 175.8 | 0.7949 |
| eval-2-block-cost | without_skill | 1 | ok | 0.8333 | none | 525175 | 9547 | 120.3 | 0.5471 |
| eval-2-block-cost | without_skill | 2 | ok | 0.8333 | none | 432411 | 9432 | 114.8 | 0.5149 |
| eval-2-block-cost | without_skill | 3 | ok | 0.8333 | none | 568948 | 10696 | 130.2 | 0.5811 |
| eval-3-startup-order | with_skill | 1 | ok | 0.8 | roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:code-comments | 465158 | 5208 | 73.3 | 0.4567 |
| eval-3-startup-order | with_skill | 2 | ok | 0.8 | roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:code-comments | 375609 | 4345 | 59.3 | 0.4084 |
| eval-3-startup-order | with_skill | 3 | ok | 0.8 | roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:code-comments | 511919 | 5591 | 82.7 | 0.4759 |
| eval-3-startup-order | without_skill | 1 | ok | 0.8 | none | 449223 | 4567 | 65.6 | 0.5279 |
| eval-3-startup-order | without_skill | 2 | ok | 0.8 | none | 567418 | 5513 | 78.7 | 0.6192 |
| eval-3-startup-order | without_skill | 3 | ok | 0.6 | none | 477516 | 6107 | 86.7 | 0.5480 |
| eval-4-admin-realm | with_skill | 1 | ok | 0.875 | roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:code-comments | 904464 | 14713 | 191.3 | 0.8987 |
| eval-4-admin-realm | with_skill | 2 | ok | 0.875 | roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:code-comments | 672785 | 14249 | 167.6 | 0.8742 |
| eval-4-admin-realm | with_skill | 3 | ok | 0.875 | roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:code-comments | 713452 | 12818 | 176.4 | 0.7648 |
| eval-4-admin-realm | without_skill | 1 | ok | 0.875 | none | 723784 | 14207 | 185.1 | 0.8721 |
| eval-4-admin-realm | without_skill | 2 | ok | 0.875 | none | 610181 | 8629 | 106.6 | 0.6509 |
| eval-4-admin-realm | without_skill | 3 | ok | 0.875 | none | 461091 | 11537 | 145.1 | 0.5910 |
| eval-5-plain-removal | with_skill | 1 | ok | 1 | roblox-dev:luau-style-guide, roblox-dev:code-comments | 488287 | 13267 | 144.5 | 0.6545 |
| eval-5-plain-removal | with_skill | 2 | ok | 1 | roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:code-comments | 605262 | 13281 | 149.1 | 0.6972 |
| eval-5-plain-removal | with_skill | 3 | ok | 1 | roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:code-comments | 533488 | 10526 | 118.2 | 0.6137 |
| eval-5-plain-removal | without_skill | 1 | ok | 1 | none | 284424 | 11148 | 113.1 | 0.4854 |
| eval-5-plain-removal | without_skill | 2 | ok | 0.875 | none | 240503 | 9600 | 97.4 | 0.4531 |
| eval-5-plain-removal | without_skill | 3 | ok | 0.875 | none | 259210 | 10240 | 101.5 | 0.4408 |

## Blind judge

| Eval | Pairs judged | with_skill wins | without_skill wins | Ties | Mean score with_skill | Mean score without_skill |
|---|---|---|---|---|---|---|
| eval-1-placement-system | 3/3 | 3 | 0 | 0 | 8.33 | 7.33 |
| eval-2-block-cost | 3/3 | 1 | 2 | 0 | 8.33 | 8.67 |
| eval-3-startup-order | 3/3 | 0 | 2 | 1 | 9.17 | 9.4 |
| eval-4-admin-realm | 3/3 | 1 | 2 | 0 | 7 | 6.83 |
| eval-5-plain-removal | 3/3 | 1 | 2 | 0 | 7.33 | 8 |
| **All** | 15/15 | 6 | 8 | 1 | 8.03 | 8.05 |

Judge runs: 15, mean 20325 tokens and 29.06 s each, $2.4539 in total.
