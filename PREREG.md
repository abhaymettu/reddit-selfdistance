# Preregistration, Tier 2: ought-self and ideal-self linguistic signatures

Paste to OSF and timestamp **before** running `04_tier2.R`. Tier 1 (already run, reported
in README) is not covered here; it is prior work that motivates the design below.

## Background

Higgins (1987) predicts a specific dissociation: **ought**-self discrepancy produces
agitation-related affect (anxiety, threat), **ideal**-self discrepancy produces
dejection-related affect (sadness, disappointment). The prediction is about *which
discrepancy pairs with which emotion*, not about overall discrepancy magnitude.

That structure has never been tested at scale with a direct linguistic operationalization.
Modal verbs of obligation are a plausible surface marker of the ought self; counterfactual
and unmet-aspiration language is the corresponding marker for the ideal self.

## Why this is an interaction and not two main effects

A main effect of obligation language on a depression grouping is uninterpretable. It is
confounded with (a) generic distress, and (b) advice-giving register, since "you should
see a doctor" is a modal of obligation with no ought self in it. Tier 1 already
demonstrated how badly register confounds pass themselves off as findings in this corpus:
comparing depression subreddits against topical subreddits gave r = .47 on a measure that
should sit near .13, and roughly half of that was genre.

So the test is a **double dissociation** across two subreddit families, both of which are
first-person distress narrative:

- **Agitation family:** anxiety, socialanxiety, healthanxiety
- **Dejection family:** depression, lonely, suicidewatch

## Hypotheses

**H2a (primary).** A family × marker-type interaction. Self-directed ought-modal rate is
higher in the agitation family than in the dejection family, *and* ideal-discrepancy rate
is higher in the dejection family than in the agitation family. **Both directions must
hold.** A single main effect in either marker does not support H2a.

**H2b.** Self-directed negative evaluation (FSCRS-seeded) is higher in the dejection
family than the agitation family.

**H2c (exploratory, not confirmatory).** Self-distanced reference (second- and
third-person self-reference, self-naming) is *lower* in the dejection family. Flagged
exploratory because the base rate of self-naming in this corpus is unknown and likely
small.

## Measures

All rates are per token, using the same tokenizer for numerator and denominator
(`02_features.R`; validated against the dataset's independent count at r = .9994).

- **Ought self:** first-person modal obligation only, `i (really/just/…)? (should|ought
  to|have to|need to|must|gotta)`. Second- and third-person modals are counted
  **separately** as an advice-giving covariate, not folded in. Discourse fillers excluded:
  `i should mention`, `i need to say`, `i have to admit`, `i have to say`.
- **Ideal self:** `should have`, `could have been`, `if only`, `i wish`, `supposed to be`,
  `wanted to be`, `used to be`, restricted to first-person contexts.
- **Self-criticism:** seed lexicon from FSCRS inadequate-self and hated-self item content,
  restricted to first-person subjects.
- **Self-distancing:** second-person and third-person self-reference; self-naming
  (recurring capitalized sentence subject that is not a known interlocutor).

## Analysis

Post-level linear models, outcome = marker rate, predictors = family (agitation vs
dejection) + log token count + advice-modal rate + window. The interaction is tested by
fitting both markers and comparing the family coefficient across them (seemingly unrelated
/ stacked model with marker × family term).

Primary window **2019**; **2018** and **post** held out as replication. An effect that
does not hold sign and rough magnitude in all three windows is reported as a window
artifact regardless of significance.

## Inference rules, fixed in advance

- **Smallest effect size of interest: |d| ≥ 0.10.** Effects below this are reported as
  null regardless of p.
- p-values are **not** reported as evidence. At n > 100k they are uninformative. Effect
  sizes with 95% CIs only.
- **Leak gate:** any |r| > 0.30 on a single marker triggers a stop-and-diagnose, not a
  writeup. Tier 1 tripped this gate and the diagnosis changed the design; the same rule
  applies here.
- Authors appearing in both families are removed in a preregistered robustness check.

## Dictionary validation (required before H2 is reported)

200 randomly sampled posts, hand-coded for (a) presence of a self-directed ought
statement, (b) presence of self-directed negative evaluation. Precision and recall of each
dictionary against those codes are reported alongside the results. If precision on the
ought dictionary is below .70, the measure is reported as unvalidated and H2a is
downgraded to exploratory.

## What would falsify H2a

Both markers moving in the *same* direction across families, that is generic distress
severity, not self-discrepancy structure. This is the most likely outcome and it will be
reported as such.
