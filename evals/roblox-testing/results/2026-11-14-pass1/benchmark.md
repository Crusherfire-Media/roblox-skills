# Skill Benchmark: roblox-testing

**Model**: claude-opus-5-5
**Date**: 2026-11-14T20:00:57Z
**Evals**: 1, 2, 3, 4 (3 runs each per configuration)

## Summary

| Metric | With Skill | Without Skill | Delta |
|--------|------------|---------------|-------|
| Pass Rate | 97% ± 4% | 93% ± 13% | +0.04 |
| Time | 198.2s ± 50.7s | 164.1s ± 77.1s | +34.1s |
| Tokens | 961798 ± 146924 | 466349 ± 218534 | +495449 |

## Trials

| Setup | Trials | Statuses | Target skill loaded | Tokens (mean ± sd) | Wall s (mean ± sd) | Cost $ (mean, total) |
|---|---|---|---|---|---|---|
| with_skill | 12 | ok 12 | 12/12 | 961798 ± 146924 | 198.2 ± 50.7 | 0.9820, 11.7843 |
| without_skill | 12 | ok 12 | 0/12 | 466349 ± 218534 | 164.1 ± 77.1 | 0.5947, 7.1367 |

Tokens count input, output, and cache reads and writes across every model the session used.

## Per trial

| Eval | Setup | Run | Status | Pass rate | Skills loaded | Tokens | Output tokens | Wall s | Cost $ |
|---|---|---|---|---|---|---|---|---|---|
| eval-1-placement-specs | with_skill | 1 | ok | 1 | roblox-dev:roblox-testing, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 981764 | 17114 | 197.7 | 1.0832 |
| eval-1-placement-specs | with_skill | 2 | ok | 1 | roblox-dev:roblox-testing, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 855992 | 17627 | 221 | 1.0202 |
| eval-1-placement-specs | with_skill | 3 | ok | 1 | roblox-dev:roblox-testing, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 1007829 | 16720 | 209.2 | 1.0402 |
| eval-1-placement-specs | without_skill | 1 | ok | 1 | none | 456942 | 14860 | 166.3 | 0.6191 |
| eval-1-placement-specs | without_skill | 2 | ok | 1 | none | 291544 | 11096 | 119.4 | 0.4646 |
| eval-1-placement-specs | without_skill | 3 | ok | 1 | none | 534955 | 13805 | 156.7 | 0.6035 |
| eval-2-fix-inventory | with_skill | 1 | ok | 1 | roblox-dev:roblox-testing, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 830866 | 8332 | 129.2 | 0.7516 |
| eval-2-fix-inventory | with_skill | 2 | ok | 1 | roblox-dev:roblox-testing, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 663667 | 7054 | 104.1 | 0.6896 |
| eval-2-fix-inventory | with_skill | 3 | ok | 1 | roblox-dev:roblox-testing, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 988883 | 7876 | 127.8 | 0.7967 |
| eval-2-fix-inventory | without_skill | 1 | ok | 1 | none | 373303 | 5455 | 88.5 | 0.3408 |
| eval-2-fix-inventory | without_skill | 2 | ok | 1 | none | 186916 | 3928 | 59.8 | 0.2174 |
| eval-2-fix-inventory | without_skill | 3 | ok | 1 | none | 368302 | 5723 | 87.1 | 0.3396 |
| eval-3-ci-runner | with_skill | 1 | ok | 0.9091 | roblox-dev:roblox-testing, roblox-dev:luau-style-guide, roblox-dev:code-comments | 1121280 | 18001 | 226.6 | 0.9708 |
| eval-3-ci-runner | with_skill | 2 | ok | 0.9091 | roblox-dev:roblox-testing, roblox-dev:luau-style-guide, roblox-dev:code-comments | 823400 | 17931 | 212 | 0.9145 |
| eval-3-ci-runner | with_skill | 3 | ok | 0.9091 | roblox-dev:roblox-testing, roblox-dev:luau-style-guide, roblox-dev:code-comments | 1157647 | 19610 | 242.7 | 1.0972 |
| eval-3-ci-runner | without_skill | 1 | ok | 0.9091 | none | 970617 | 38327 | 329 | 1.0159 |
| eval-3-ci-runner | without_skill | 2 | ok | 0.7273 | none | 767054 | 23803 | 260.1 | 0.9822 |
| eval-3-ci-runner | without_skill | 3 | ok | 0.6364 | none | 300497 | 20820 | 214.2 | 0.7082 |
| eval-4-prune-suite | with_skill | 1 | ok | 1 | roblox-dev:roblox-testing, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 974200 | 16555 | 201.5 | 1.0594 |
| eval-4-prune-suite | with_skill | 2 | ok | 0.9167 | roblox-dev:roblox-testing, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 992808 | 22939 | 256.8 | 1.1883 |
| eval-4-prune-suite | with_skill | 3 | ok | 1 | roblox-dev:roblox-testing, roblox-dev:luau-style-guide, roblox-dev:code-comments, roblox-dev:game-architecture | 1143243 | 19836 | 249.6 | 1.1725 |
| eval-4-prune-suite | without_skill | 1 | ok | 1 | none | 371086 | 11938 | 138.1 | 0.5334 |
| eval-4-prune-suite | without_skill | 2 | ok | 1 | none | 411868 | 13274 | 153.5 | 0.5594 |
| eval-4-prune-suite | without_skill | 3 | ok | 0.8333 | none | 563103 | 17811 | 196.6 | 0.7526 |

## Blind judge

| Eval | Pairs judged | with_skill wins | without_skill wins | Ties | Mean score with_skill | Mean score without_skill |
|---|---|---|---|---|---|---|
| eval-1-placement-specs | 3/3 | 2 | 1 | 0 | 7.83 | 8 |
| eval-2-fix-inventory | 3/3 | 1 | 2 | 0 | 8.17 | 8.83 |
| eval-3-ci-runner | 3/3 | 3 | 0 | 0 | 8.83 | 5.5 |
| eval-4-prune-suite | 3/3 | 3 | 0 | 0 | 8.83 | 6.67 |
| **All** | 12/12 | 9 | 3 | 0 | 8.42 | 7.25 |

Judge runs: 12, mean 20532 tokens and 30.81 s each, $2.101 in total.
