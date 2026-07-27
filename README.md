# Self-distancing, self-criticism, and the ought/ideal split in Reddit mental health text

Do linguistic markers of self-distancing and self-criticism track depressive symptoms, and
does the **ought**-self signal behave differently from the **ideal**-self signal?

Higgins' self-discrepancy theory predicts that ought-discrepancy produces anxiety while
ideal-discrepancy produces dejection. If those map onto separable linguistic signatures,
that is testable at scale and, as far as I can find, has not been cleanly tested. That is
the target. Tier 1 below is the replication groundwork that has to hold first.

## Status

| Tier | What | State |
|---|---|---|
| 0 | Data audit / go-no-go | done |
| 1 | I-talk vs depression grouping | **done — see Findings** |
| 2 | Ought vs ideal double dissociation | **done — supported, with caveats** |
| 3 | Within-person over time | **done in reduced form — see below** |
| 4 | Limitations | below, and in `report.qmd` |

## Data

Reddit Mental Health Dataset, Low et al. 2020, *JMIR* 22(10):e22635.
Zenodo [10.5281/zenodo.3941387](https://zenodo.org/records/3941387), public domain, no
application needed. 28 subreddits × 4 time windows, 108 CSVs.

This repo uses 16 subreddits across 3 windows (2018, 2019, post = Jan–Apr 2020),
**478,675 posts**. `data/` is gitignored; nothing derived from raw text or usernames is
committed.

```sh
Rscript 00_download.R    # 47 files, ~1.2 GB, skips what you already have
```

Each CSV carries `subreddit, author, date, post` plus ~346 precomputed feature columns.

**Do not use the bundled `liwc_1st_pers` column.** On a r/depression post containing four
unambiguous first-person singular pronouns it reads 0, and its corpus mean is 0.47 per
post against a median post length of 140 words. Whatever it counts, it is not first-person
singular pronoun use. All pronoun measures here are computed from raw text and validated
against the dataset's own tokenizer (`n_words`, agreement r = .9995).

## Run

```sh
Rscript 00_download.R   # ~1.2 GB from Zenodo
Rscript 01_audit.R      # go/no-go: confirms post/author/date columns exist
Rscript test_lexicons.R # 41 dictionary assertions
Rscript 02_features.R   # text -> out/features.rds  (the one expensive pass, ~3 min)
Rscript 03_tier1.R      # Tier 1 results + figure
Rscript 04_tier2.R      # Tier 2 results
Rscript 06_tier3.R      # Tier 3 reduced (needs lme4)
quarto render report.qmd
```

R 4.5, `data.table`, `stringi`, `ggplot2`, and `lme4` for Tier 3 only.

## Findings (Tier 1)

**The headline is a negative methodological result, and it is the useful part.**

The obvious design — depression subreddits (depression, lonely, suicidewatch) vs
non-mental-health subreddits (fitness, jokes, personalfinance, teaching) — gives
**r = .47, d = 1.08**. The literature's meta-analytic I-talk effect is around r = .13.
A number 3.5× the published effect is a red flag, not a discovery, and the script's
preregistered `|r| > 0.3` gate aborted on it.

The gate was right, but the cause is not a coding bug. It is **confounded genre**.
r/depression and r/suicidewatch are communities whose norm is first-person confessional
narrative; r/personalfinance and r/teaching are topic-oriented Q&A. Any first-person
pronoun measure separates those registers whether or not anyone is depressed. Dropping
r/jokes (the most third-person control) barely moved it, so it is not one bad control —
it is the entire control arm.

Holding genre constant by comparing against **other mental-health subreddits** — where
everyone writes first-person distress narrative and only the disorder varies:

| Contrast | 2019 | 2018 | post (2020) |
|---|---|---|---|
| vs topical subreddits (confounded) | r = .472 | .489 | .490 |
| vs other mental-health (genre-matched) | **r = .211** | .224 | .223 |
| genre-matched, cross-arm authors removed | **r = .224** | .238 | .235 |

Stable across all three time windows, so it is not a window artifact. 4.9% of authors post
in both arms; removing them moves r *up* slightly, so that overlap was attenuating rather
than inflating the estimate.

**Roughly half the naive association is register, not depression.** The residual r ≈ .22
is still somewhat above the r ≈ .13 literature, and I would expect the remaining gap to be
more of the same: even within mental-health subreddits, r/depression is more
self-focused-by-topic than r/adhd. r/autism landing down among the topical subreddits
(fig) is the same effect from the other side.

![1SG rate by subreddit](out/fig_1sg_by_subreddit.png)

### What this number is not

It is **not** a replication of the r = .13 effect. Those estimates come from continuous
depression scales administered to the people who produced the language. This dataset has
no symptom measure at all, so the criterion here is subreddit membership — a different and
much cruder estimand. Landing near .13 would have been a coincidence worth distrusting.
A DAIC-WOZ request (PHQ-8-scored interview transcripts) is out for the severity version.

## Findings (Tier 2)

Hypotheses were preregistered in `PREREG.md` and **committed to git before `04_tier2.R`
existed** — the ordering is verifiable in the history, not just asserted.

The test is a double dissociation between two families that are both first-person distress
narrative, so the Tier 1 register confound is held constant:

- **Agitation family:** anxiety, socialanxiety, healthanxiety
- **Dejection family:** depression, lonely, suicidewatch

Markers are restricted to first-person subjects, which matters more than any other design
choice here: *"you should see a doctor"* is a modal of obligation containing no ought self,
and support communities are full of it. Second/third-person modals are counted separately
and entered as a covariate.

| Marker | *d* (+ = higher in dejection) | OR for ≥1 occurrence |
|---|---|---|
| ought (self-directed obligation) | **−0.034** | 0.91 |
| ideal (counterfactual / unmet aspiration) | **+0.153** | 1.82 |
| self-criticism (FSCRS-seeded) | **+0.156** | 2.39 |

Because both markers come from the same post, the interaction is tested as a within-post
difference score, `delta = z(ideal) − z(ought)`, avoiding the correlated-rows problem a
stacked model would create. Higgins predicts delta is higher in the dejection family:

| Window | *d* for delta | 95% CI |
|---|---|---|
| 2019 (primary) | **0.134** | [0.163, 0.211] |
| 2018 (held out) | 0.130 | [0.153, 0.211] |
| 2020 (held out) | 0.123 | [0.149, 0.192] |

Direction holds in all three windows. The preregistered falsification condition — both
markers moving the same direction, i.e. generic distress rather than self-discrepancy
structure — **did not occur**. Robust to removing the 4.1% of authors in both families.

**But it leans on r/anxiety.** Leave-one-subreddit-out puts delta in [0.090, 0.168], and the
low end is dropping r/anxiety — which takes the effect just *below* the preregistered SESOI
of 0.10. No single community reverses the sign, but one of six can push it under the
threshold I set in advance, and that belongs in the summary rather than a footnote.

### Caveats that matter more than the point estimate

**It is asymmetric.** The ought effect (*d* = −0.034) is below the preregistered SESOI of
0.10. It points the way Higgins predicts but cannot stand alone — the crossover is carried
by the ideal marker. That is weaker than a true double dissociation and is reported as such.

**The unit of analysis is six communities, not 197,106 posts.** The post-level CIs are
hairline-thin because *n* is huge, but they describe uncertainty about *these six
communities*. Treating each community as one observation, the exact permutation test gives
*p* = 0.10 — the **floor** for a 3-vs-3 split, attained because rank separation is perfect:

| Family | Subreddit | mean delta |
|---|---|---|
| agitation | healthanxiety | −0.064 |
| agitation | socialanxiety | −0.088 |
| agitation | anxiety | −0.157 |
| dejection | lonely | +0.173 |
| dejection | suicidewatch | +0.082 |
| dejection | depression | +0.028 |

As strong as six communities can make it, which is not very strong.

**Corrections went against the finding and it survived.** Hand-coding the validation sample
(`VALIDATION.md`) found four systematic error classes in the ought dictionary and fixed
three: `had to` catching past-tense external necessity ("i had to call the cops"), epistemic
`must` ("i must be underestimating myself" is an inference, not a duty), and
discourse-purpose statements ("i need to vent"). `had to` was in an early lexicon draft but
*not* in the preregistered pattern, so removing it restored the prereg definition rather
than tuning toward a result. Cumulative effect: delta *d* 0.144 → 0.134. Applied anyway.

The validation coding is **provisional and machine-coded, not human-rated** — see
`VALIDATION.md`, which is explicit about what that does and does not buy you.

`test_lexicons.R` holds 41 assertions on the dictionaries — mostly that advice-giving does
not leak into the ought measure, which is the single confound the design rests on. Run it
before trusting any Tier 2 number.

## Findings (Tier 3, reduced)

The original design — mixed models on users with ≥5 posts spanning ≥30 days — is impossible
here: the release ships one post per author per subreddit-window. What exists is a thin,
irregular panel of authors appearing in more than one of the three windows, i.e.
observations about a **year** apart.

**42,715 author-windows / 20,519 authors** with ≥2 windows; 1,677 with all three. All
predictors are person-mean-centred, so estimates are within-person.

| Model | n | b | 95% CI |
|---|---|---|---|
| same window (negative control) | 42,715 | −0.000514 | [−0.00064, −0.00039] |
| naive lagged: distancing(t) → self-crit(t+1) | 19,343 | +0.000548 | [0.00035, 0.00075] |
| lagged, 3-window authors only | 3,354 | +0.000356 | [−0.00013, 0.00084] |

Within the same window, more self-distanced language goes with **less** self-criticism —
the direction the self-distancing literature predicts.

### The lagged result is an artefact, and catching it is the point

The naive lagged model flips sign and looks significant. It is arithmetic, not psychology.

**91.8% of these authors have exactly two windows.** For someone with two observations,
person-mean-centring forces `x_c = (d/2, −d/2)` and `y_c = (e/2, −e/2)`. The contemporaneous
pair is `(d/2, e/2)`; the lagged pair is `(d/2, −e/2)` — *exactly the negative, by
construction, for every such author*. So a lagged regression on two-observation people is
mechanically the mirror of the contemporaneous one and contains no information about time.

The script verifies this numerically rather than asserting it: on two-window authors the
contemporaneous slope is −0.000589 and the lagged slope +0.000604, a **ratio of −1.025**
against the −1.000 an exact artefact predicts.

Restricting the lag to authors observed in all three windows — where centring does not force
a reversal — gives an interval that **crosses zero**. And even that estimate carries
small-T dynamic panel (Nickell) bias.

**Conclusion: there is a within-person association in the same window, and no evidence of
temporal ordering.** The question that motivated Tier 3 — does self-distanced language shift
*before* symptom language — needs days-to-weeks resolution. This panel is annual. It cannot
answer it, and no amount of modelling will make it.

## Limitations

Self-selected sample. No clinical diagnosis anywhere in the design. Subreddit membership
is a poor disorder proxy and each community mixes sufferers, supporters, and lurkers.
Everything is correlational. At n > 100k every p-value is < .001 and carries no
information, so effect sizes and CIs are reported and p-values deliberately omitted; a
smallest effect size of interest (|d| ≥ 0.10) was declared before estimation. Dictionary
methods miss sarcasm, quotation, and negation. The four timeframes are windows, not a
balanced panel. **Ethics:** the data is public domain, but no post text or usernames are
committed; only aggregate results are published.

## Files

```
00_download.R   fetch the 47 CSVs this project uses
01_audit.R      go/no-go on the data release
lexicons.R      all regex patterns, shared by the pipeline and the tests
test_lexicons.R 41 assertions — run before trusting any Tier 2 number
02_features.R   text -> per-post features (the only pass over raw text)
03_tier1.R      Tier 1 estimation, robustness, figure
04_tier2.R      Tier 2 double dissociation + community-level permutation test
06_tier3.R      Tier 3 reduced: within-person panel + the centring-artefact check
05_validate.R   generates the hand-coding sample; --score computes precision
PREREG.md       Tier 2 hypotheses, committed before 04_tier2.R existed
VALIDATION.md   dictionary error classes found and fixed
TALK.md         the five-minute verbal version
report.qmd      the reproducible write-up
out/            results CSV + figure (committed); features.rds (not)
```
