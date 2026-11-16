# Skill Benchmark: game-architecture

**Model**: claude-opus-5-5
**Date**: 2026-11-16T16:32:22Z
**Evals**: 1, 2, 3, 4, 5 (3 runs each per configuration)

## Summary

| Metric | With Skill | Without Skill | Delta |
|--------|------------|---------------|-------|
| Pass Rate | 88% ± 7% | 85% ± 8% | +0.03 |
| Time | 188.3s ± 155.2s | 165.0s ± 114.3s | +23.3s |
| Tokens | 839997 ± 457903 | 752361 ± 652326 | +87637 |

## Trials

| Setup | Trials | Statuses | Target skill loaded | Tokens (mean ± sd) | Wall s (mean ± sd) | Cost $ (mean, total) |
|---|---|---|---|---|---|---|
| with_skill | 15 | ok 15 | 12/15 | 839997 ± 457903 | 188.3 ± 155.2 | 1.0167, 15.2504 |
| without_skill | 15 | ok 15 | 0/15 | 752361 ± 652326 | 165.0 ± 114.3 | 0.7867, 11.7999 |

Tokens count input, output, and cache reads and writes across every model the session used.

## Per trial

| Eval | Setup | Run | Status | Pass rate | Skills loaded | Tokens | Output tokens | Wall s | Cost $ |
|---|---|---|---|---|---|---|---|---|---|
| eval-1-placement-system | with_skill | 1 | ok | 0.875 | roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:rojo-workflow, roblox-dev:code-comments, roblox-dev:game-architecture | 1776075 | 49029 | 474.9 | 2.2273 |
| eval-1-placement-system | with_skill | 2 | ok | 0.875 | roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture, roblox-dev:roblox-testing | 1452357 | 50340 | 490.8 | 2.1098 |
| eval-1-placement-system | with_skill | 3 | ok | 0.875 | roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture, roblox-dev:roblox-testing | 1415404 | 42626 | 412 | 1.9621 |
| eval-1-placement-system | without_skill | 1 | ok | 0.875 | none | 2616614 | 36521 | 427.3 | 1.9814 |
| eval-1-placement-system | without_skill | 2 | ok | 0.875 | none | 1394199 | 29255 | 341.5 | 1.3557 |
| eval-1-placement-system | without_skill | 3 | ok | 0.875 | none | 1674711 | 32453 | 360.9 | 1.6311 |
| eval-2-block-cost | with_skill | 1 | ok | 0.8333 | roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:code-comments | 1002296 | 14172 | 142.1 | 0.8832 |
| eval-2-block-cost | with_skill | 2 | ok | 0.8333 | roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:code-comments | 503778 | 7537 | 71.7 | 0.5465 |
| eval-2-block-cost | with_skill | 3 | ok | 0.8333 | roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:code-comments | 698810 | 10716 | 114.4 | 0.6928 |
| eval-2-block-cost | without_skill | 1 | ok | 0.8333 | none | 525175 | 9547 | 120.3 | 0.5471 |
| eval-2-block-cost | without_skill | 2 | ok | 0.8333 | none | 432411 | 9432 | 114.8 | 0.5149 |
| eval-2-block-cost | without_skill | 3 | ok | 0.8333 | none | 568948 | 10696 | 130.2 | 0.5811 |
| eval-3-startup-order | with_skill | 1 | ok | 0.8 | roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:code-comments | 462992 | 4530 | 46.7 | 0.4350 |
| eval-3-startup-order | with_skill | 2 | ok | 0.8 | roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:code-comments | 384172 | 4996 | 51.5 | 0.4324 |
| eval-3-startup-order | with_skill | 3 | ok | 0.8 | roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:code-comments | 387849 | 4544 | 46.2 | 0.4283 |
| eval-3-startup-order | without_skill | 1 | ok | 0.8 | none | 449223 | 4567 | 65.6 | 0.5279 |
| eval-3-startup-order | without_skill | 2 | ok | 0.8 | none | 567418 | 5513 | 78.7 | 0.6192 |
| eval-3-startup-order | without_skill | 3 | ok | 0.6 | none | 477516 | 6107 | 86.7 | 0.5480 |
| eval-4-admin-realm | with_skill | 1 | ok | 0.875 | roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:code-comments | 745403 | 14644 | 154.9 | 0.8434 |
| eval-4-admin-realm | with_skill | 2 | ok | 0.875 | roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:code-comments | 604935 | 8378 | 84.5 | 0.7126 |
| eval-4-admin-realm | with_skill | 3 | ok | 0.875 | roblox-dev:game-architecture, roblox-dev:luau-style-guide, roblox-dev:code-comments | 475551 | 11486 | 117 | 0.7262 |
| eval-4-admin-realm | without_skill | 1 | ok | 0.875 | none | 723784 | 14207 | 185.1 | 0.8721 |
| eval-4-admin-realm | without_skill | 2 | ok | 0.875 | none | 610181 | 8629 | 106.6 | 0.6509 |
| eval-4-admin-realm | without_skill | 3 | ok | 0.875 | none | 461091 | 11537 | 145.1 | 0.5910 |
| eval-5-plain-removal | with_skill | 1 | ok | 1 | roblox-dev:luau-style-guide, roblox-dev:code-comments | 1400369 | 30489 | 291.2 | 1.4950 |
| eval-5-plain-removal | with_skill | 2 | ok | 1 | roblox-dev:luau-style-guide, roblox-dev:code-comments | 483166 | 12648 | 115.2 | 0.6302 |
| eval-5-plain-removal | with_skill | 3 | ok | 1 | roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:roblox-testing | 806802 | 23046 | 210.9 | 1.1257 |
| eval-5-plain-removal | without_skill | 1 | ok | 1 | none | 284424 | 11148 | 113.1 | 0.4854 |
| eval-5-plain-removal | without_skill | 2 | ok | 0.875 | none | 240503 | 9600 | 97.4 | 0.4531 |
| eval-5-plain-removal | without_skill | 3 | ok | 0.875 | none | 259210 | 10240 | 101.5 | 0.4408 |

## Blind judge

| Eval | Pairs judged | with_skill wins | without_skill wins | Ties | Mean score with_skill | Mean score without_skill |
|---|---|---|---|---|---|---|
| eval-1-placement-system | 3/3 | 2 | 1 | 0 | 8.17 | 7.83 |
| eval-2-block-cost | 3/3 | 0 | 3 | 0 | 8.67 | 8.93 |
| eval-3-startup-order | 3/3 | 1 | 1 | 1 | 9.17 | 9.17 |
| eval-4-admin-realm | 3/3 | 1 | 2 | 0 | 8.5 | 8.67 |
| eval-5-plain-removal | 3/3 | 2 | 1 | 0 | 8.67 | 7.77 |
| **All** | 15/15 | 6 | 8 | 1 | 8.63 | 8.47 |

Judge runs: 15, mean 20543 tokens and 26.82 s each, $2.4427 in total.
