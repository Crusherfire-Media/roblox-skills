# Skill Benchmark: game-architecture

**Model**: claude-opus-5-5
**Date**: 2026-11-16T17:30:29Z
**Evals**: 1, 2, 3, 4, 5 (3 runs each per configuration)

## Summary

| Metric | With Skill | Without Skill | Delta |
|--------|------------|---------------|-------|
| Pass Rate | 88% ± 7% | 85% ± 8% | +0.03 |
| Time | 165.3s ± 146.9s | 165.0s ± 114.3s | +0.3s |
| Tokens | 826570 ± 642173 | 752361 ± 652326 | +74209 |

## Trials

| Setup | Trials | Statuses | Target skill loaded | Tokens (mean ± sd) | Wall s (mean ± sd) | Cost $ (mean, total) |
|---|---|---|---|---|---|---|
| with_skill | 15 | ok 15 | 12/15 | 826570 ± 642173 | 165.3 ± 146.9 | 0.9032, 13.5477 |
| without_skill | 15 | ok 15 | 0/15 | 752361 ± 652326 | 165.0 ± 114.3 | 0.7867, 11.7999 |

Tokens count input, output, and cache reads and writes across every model the session used.

## Per trial

| Eval | Setup | Run | Status | Pass rate | Skills loaded | Tokens | Output tokens | Wall s | Cost $ |
|---|---|---|---|---|---|---|---|---|---|
| eval-1-placement-system | with_skill | 1 | ok | 0.875 | roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 2268417 | 47304 | 473.3 | 2.3011 |
| eval-1-placement-system | with_skill | 2 | ok | 0.875 | roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:rojo-workflow, roblox-dev:code-comments, roblox-dev:game-architecture | 2279462 | 47167 | 499.2 | 2.3132 |
| eval-1-placement-system | with_skill | 3 | ok | 0.875 | roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:code-comments | 1422657 | 34717 | 341.5 | 1.6427 |
| eval-1-placement-system | without_skill | 1 | ok | 0.875 | none | 2616614 | 36521 | 427.3 | 1.9814 |
| eval-1-placement-system | without_skill | 2 | ok | 0.875 | none | 1394199 | 29255 | 341.5 | 1.3557 |
| eval-1-placement-system | without_skill | 3 | ok | 0.875 | none | 1674711 | 32453 | 360.9 | 1.6311 |
| eval-2-block-cost | with_skill | 1 | ok | 0.8333 | roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:code-comments | 863154 | 11209 | 123.9 | 0.7716 |
| eval-2-block-cost | with_skill | 2 | ok | 0.8333 | roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:code-comments | 585066 | 8812 | 90.7 | 0.6305 |
| eval-2-block-cost | with_skill | 3 | ok | 0.8333 | roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:code-comments | 547046 | 8397 | 86.3 | 0.5734 |
| eval-2-block-cost | without_skill | 1 | ok | 0.8333 | none | 525175 | 9547 | 120.3 | 0.5471 |
| eval-2-block-cost | without_skill | 2 | ok | 0.8333 | none | 432411 | 9432 | 114.8 | 0.5149 |
| eval-2-block-cost | without_skill | 3 | ok | 0.8333 | none | 568948 | 10696 | 130.2 | 0.5811 |
| eval-3-startup-order | with_skill | 1 | ok | 0.8 | roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:code-comments | 425083 | 5396 | 53.9 | 0.4435 |
| eval-3-startup-order | with_skill | 2 | ok | 0.8 | roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:code-comments | 491853 | 6019 | 66.9 | 0.4942 |
| eval-3-startup-order | with_skill | 3 | ok | 0.8 | roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:code-comments | 436957 | 5622 | 55.2 | 0.4762 |
| eval-3-startup-order | without_skill | 1 | ok | 0.8 | none | 449223 | 4567 | 65.6 | 0.5279 |
| eval-3-startup-order | without_skill | 2 | ok | 0.8 | none | 567418 | 5513 | 78.7 | 0.6192 |
| eval-3-startup-order | without_skill | 3 | ok | 0.6 | none | 477516 | 6107 | 86.7 | 0.5480 |
| eval-4-admin-realm | with_skill | 1 | ok | 0.875 | roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:code-comments | 661173 | 13098 | 141 | 0.7976 |
| eval-4-admin-realm | with_skill | 2 | ok | 0.875 | roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:code-comments | 408335 | 10150 | 103.9 | 0.6096 |
| eval-4-admin-realm | with_skill | 3 | ok | 0.875 | roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:code-comments | 602645 | 11624 | 132.5 | 0.7108 |
| eval-4-admin-realm | without_skill | 1 | ok | 0.875 | none | 723784 | 14207 | 185.1 | 0.8721 |
| eval-4-admin-realm | without_skill | 2 | ok | 0.875 | none | 610181 | 8629 | 106.6 | 0.6509 |
| eval-4-admin-realm | without_skill | 3 | ok | 0.875 | none | 461091 | 11537 | 145.1 | 0.5910 |
| eval-5-plain-removal | with_skill | 1 | ok | 1 | roblox-dev:luau-style-guide, roblox-dev:code-comments | 332362 | 10612 | 98.8 | 0.5279 |
| eval-5-plain-removal | with_skill | 2 | ok | 1 | roblox-dev:luau-style-guide, roblox-dev:code-comments | 562391 | 11473 | 104.7 | 0.6515 |
| eval-5-plain-removal | with_skill | 3 | ok | 1 | roblox-dev:luau-style-guide, roblox-dev:code-comments | 511944 | 11729 | 108.2 | 0.6040 |
| eval-5-plain-removal | without_skill | 1 | ok | 1 | none | 284424 | 11148 | 113.1 | 0.4854 |
| eval-5-plain-removal | without_skill | 2 | ok | 0.875 | none | 240503 | 9600 | 97.4 | 0.4531 |
| eval-5-plain-removal | without_skill | 3 | ok | 0.875 | none | 259210 | 10240 | 101.5 | 0.4408 |

## Blind judge

| Eval | Pairs judged | with_skill wins | without_skill wins | Ties | Mean score with_skill | Mean score without_skill |
|---|---|---|---|---|---|---|
| eval-1-placement-system | 3/3 | 2 | 1 | 0 | 7.83 | 7.67 |
| eval-2-block-cost | 3/3 | 0 | 2 | 1 | 8.5 | 8.93 |
| eval-3-startup-order | 3/3 | 0 | 2 | 1 | 8.93 | 9.17 |
| eval-4-admin-realm | 3/3 | 2 | 1 | 0 | 8.83 | 8.5 |
| eval-5-plain-removal | 3/3 | 2 | 1 | 0 | 8.5 | 8 |
| **All** | 15/15 | 6 | 7 | 2 | 8.52 | 8.45 |

Judge runs: 15, mean 26538 tokens and 28.15 s each, $2.5724 in total.
