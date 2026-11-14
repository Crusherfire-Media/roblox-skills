# Skill Benchmark: block-catalog

**Model**: claude-opus-5-5
**Date**: 2026-11-14T00:49:52Z
**Evals**: 0 (2 runs each per configuration)

## Summary

| Metric | With Skill | Without Skill | Delta |
|--------|------------|---------------|-------|
| Pass Rate | 93% ± 10% | 86% ± 0% | +0.07 |
| Time | 39.9s ± 4.2s | 72.7s ± 14.9s | -32.8s |
| Tokens | 159549 ± 2653 | 172052 ± 36649 | -12502 |

## Trials

| Setup | Trials | Statuses | Target skill loaded | Tokens (mean ± sd) | Wall s (mean ± sd) | Cost $ (mean, total) |
|---|---|---|---|---|---|---|
| with_skill | 2 | ok 2 | 2/2 | 159549 ± 2653 | 39.9 ± 4.2 | 0.1680, 0.3359 |
| without_skill | 2 | ok 2 | 0/2 | 172052 ± 36649 | 72.7 ± 14.9 | 0.1939, 0.3878 |

Tokens count input, output, and cache reads and writes across every model the session used.

## Per trial

| Eval | Setup | Run | Status | Pass rate | Skills loaded | Tokens | Output tokens | Wall s | Cost $ |
|---|---|---|---|---|---|---|---|---|---|
| eval-0-block-catalog | with_skill | 1 | ok | 0.8571 | roblox-dev:block-catalog | 157673 | 1891 | 36.9 | 0.1637 |
| eval-0-block-catalog | with_skill | 2 | ok | 1 | roblox-dev:block-catalog | 161425 | 2013 | 42.9 | 0.1723 |
| eval-0-block-catalog | without_skill | 1 | ok | 0.8571 | none | 197966 | 4472 | 83.2 | 0.2227 |
| eval-0-block-catalog | without_skill | 2 | ok | 0.8571 | none | 146137 | 3087 | 62.1 | 0.1651 |

## Blind judge

| Eval | Pairs judged | with_skill wins | without_skill wins | Ties | Mean score with_skill | Mean score without_skill |
|---|---|---|---|---|---|---|
| eval-0-block-catalog | 2/2 | 0 | 2 | 0 | 7.25 | 9 |
| **All** | 2/2 | 0 | 2 | 0 | 7.25 | 9 |

Judge runs: 2, mean 8010 tokens and 21.12 s each, $0.1276 in total.
