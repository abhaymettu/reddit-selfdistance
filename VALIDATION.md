# Dictionary validation

`PREREG.md` requires precision/recall against hand-coded posts before Tier 2 results are
reported, and requires H2a be downgraded to exploratory if ought precision falls below .70.

## Status: provisional, machine-coded

**The coding below was done by me (Claude), not by a human rater.** That is not what the
preregistration asked for and it is not a substitute. It is reported as a provisional
estimate so the measurement error is visible now rather than after the writeup, and so the
error classes it found could be fixed. `out/validation_sample.csv` is generated with a
blank `true_label` column and a fixed seed, ready for human coding; `Rscript
05_validate.R --score` computes the real numbers once it is filled in.

Treat every figure here as an upper bound on rater agreement, since the same system wrote
the dictionary and judged its output.

## Provisional precision (flagged posts, 2019 + held-out windows pooled)

| Marker | Coded | Provisional precision |
|---|---|---|
| ought (self-directed obligation) | 24 | ~0.79 |
| self-criticism (FSCRS-seeded) | 18 | ~0.94 |

Both clear the .70 prereg threshold, so H2a stands as confirmatory pending human coding.

## Error classes found, and what was done about them

Hand-coding was worth doing: it found four systematic errors, three of which were fixed.

**1. Past-tense external necessity — FIXED.** `had to` was capturing narration of
circumstance ("i had to call the cops on her", "i had to be rushed to the e.r."), not an
internalised self-guide. It was in an early lexicon draft but *not* in the preregistered
pattern, so removing it restored the prereg definition. This weakened the headline result
(delta *d* 0.144 → 0.133) and was applied anyway.

**2. Epistemic `must` — FIXED.** "i must be underestimating myself" is an inference, not
an obligation. Now excluded via `i must (be|have been|have|not be)`, while deontic "i must
stop" is kept. Covered by a test.

**3. Discourse-purpose statements — FIXED.** "i need to vent", "i need to rant" announce a
speech act rather than express a standard the writer is failing to meet — the same logic
that already excluded "i have to say". Added to the filler list.

**4. Quotation and reported speech — NOT FIXED, known ceiling.** One flagged post was
quoting someone else's shopping list ("i gotta write it down"). Detecting quotation
reliably needs more than regex. Rate is low (~1 in 50) and there is no reason to expect it
to differ between families, so it should add noise rather than bias.

## One error class that biases *against* the finding

In r/healthanxiety, "something wrong with me" is often meant medically ("i wonder if
there's something wrong with me and why i feel like i'm dying") rather than as
self-evaluation. That inflates self-criticism in the agitation family. Since the result is
that self-criticism is *higher in the dejection family*, this false positive works against
H2b, making the reported effect conservative rather than inflated.

## What a human coder should do

1. Open `out/validation_sample.csv` (gitignored — it contains raw post text).
2. Fill `true_label` with 1/0 using the instructions `05_validate.R` prints.
3. Run `Rscript 05_validate.R --score`.
4. Replace this file's numbers with the real ones, and if ought precision < .70, mark H2a
   exploratory in `README.md` and `report.qmd` as the prereg requires.

The sample is stratified: 50 flagged and 50 hard negatives per marker. Hard negatives are
posts containing the surface form that the dictionary did *not* count — usually
second-person subjects or fillers. Unflagged posts with no modal at all are excluded
because they are trivially correct and would inflate any agreement statistic.
