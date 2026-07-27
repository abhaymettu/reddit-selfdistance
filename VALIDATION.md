# Dictionary validation

`PREREG.md` requires precision and recall against hand-coded posts before Tier 2 results
are reported, and requires H2a be downgraded to exploratory if ought precision falls
below .70.

That threshold was not met. H2a is reported as exploratory.

## Result, 200 items hand-coded by the author, 2026-07-27

| Marker | Precision | 95% CI | Recall vs hard negatives | Prereg gate |
|---|---|---|---|---|
| ought (self-directed obligation) | **0.52** | [0.374, 0.663] | 0.63 | **FAIL** |
| self-criticism (FSCRS-seeded) | **0.94** | [0.835, 0.987] | 0.66 | pass |

Reproduce with `Rscript 05_validate.R --score`.

The ought failure is not marginal. The entire confidence interval sits below the .70
threshold, so this is not a case where a larger sample might rescue it.

## What the split means

The two dictionaries were built the same way, validated by the same coder on the same
afternoon, against the same corpus. One works and one does not, and the reason is in
what they are made of.

Self-criticism is built from content words: "failure", "worthless", "pathetic", "hate
myself". These are close to unambiguous: a person who writes them is nearly always
evaluating themselves. Precision 0.94.

Ought is built from function words: "have to", "need to", "should", "must", "gotta". English
modals of necessity are massively polysemous. The same surface form covers an internalised
standard, a logistical errand, a question, advice to someone else, and epistemic
inference, and regex cannot separate them.

Of the 50 flagged ought items, 24 were judged non-instances. The dominant class was
practical necessity rather than internalised obligation:

> "i need to clear that with my wife" · "it's just medicine i have to take everyday" ·
> "now i have to correct them in person" · "do whatever i need to do to get ready" ·
> "i have to start the conversation" · "whenever i have to sit at the table"

Higgins' ought self is a standard about who a person believes they should be. "I have to
take my medicine" is a scheduling fact. The dictionary does not distinguish the two, so
what it measures is closer to a record of tasks than a self-guide.

The generalisable point is that lexical markers survive validation for content words and
fail for modal verbs. Any operationalisation of an internalised standard through modals of
necessity should be validated before use rather than after.

## Coding standard, and where it drifted

The written instruction was "an obligation or requirement they feel bound by, about
themselves." In practice the author applied a stricter, more construct-faithful reading,
rejecting logistical necessities that the literal instruction arguably admits.

This is disclosed rather than corrected, for two reasons. The stricter reading is the one
that matches the construct Tier 2 is testing, so it is the more informative number. And
re-coding after seeing the result would destroy the independence that makes the number
worth anything.

Two further procedural notes, recorded for completeness:

- One batch of 20 self-criticism items was re-shown after a data-entry error. The author
  reports their judgments were unchanged.
- The coding rule was clarified partway through the self-criticism set: for "i feel X",
  the code depends on whether X is an emotion (hopeless, numb, tired → 0) or a
  characterisation of the person (failure, burden, broken → 1). Hedging with "i feel like"
  does not change the code, since the FSCRS items this lexicon is seeded from are written
  in exactly that hedged form. A small number of earlier calls predate the clarification.

## The LLM pass, and why it was not enough

Before the author coded, the same 200 items were coded by an LLM into a separate
`machine_label` column. That column is retained. It was never allowed to stand in for the
human rating, because the LLM was the same system that wrote the dictionary being tested.

Comparing the two:

| Marker | Human precision | LLM precision | Human 1s | LLM 1s | Cohen's kappa |
|---|---|---|---|---|---|
| ought | 0.52 | 0.80 | 41/100 | 58/100 | 0.242 |
| self-criticism | 0.94 | 0.86 | 71/100 | 60/100 | 0.585 |

The LLM erred in opposite directions on the two markers. It over-called ought, raising
apparent precision from 0.52 to 0.80 and converting a clear threshold failure into a pass.
It under-called self-criticism, lowering 0.94 to 0.86.

So LLM annotation error here is not a constant bias that could be corrected with an
offset. It is construct-dependent, and it was largest precisely where the construct was
hardest and the validation mattered most. Had the LLM numbers been accepted, H2a would
have been reported as confirmatory on a measure with 0.52 precision.

`Rscript 05_validate.R --score --col machine_label` reproduces the LLM figures.

## Error classes found, and what was done about them

Coding found four systematic errors, three of which were fixed before the final run.

1. Past-tense external necessity, fixed. `had to` was capturing narration of
circumstance ("i had to call the cops on her"), not an internalised self-guide. It was in
an early lexicon draft but *not* in the preregistered pattern, so removing it restored the
prereg definition. This weakened the headline result and was applied anyway. Cumulatively
the three fixes moved delta *d* from 0.144 to 0.134.

2. Epistemic `must`, fixed. "i must be underestimating myself" is an inference, not an
obligation. Now excluded via `i must (be|have been|have|not be)`, while deontic "i must
stop" is kept. Covered by a test.

3. Discourse-purpose statements, fixed. "i need to vent", "i need to rant" announce a
speech act rather than express a standard the writer is failing to meet, the same logic
that already excluded "i have to say". Added to the filler list.

4. Quotation and reported speech, not fixed, a known ceiling. Detecting quotation
reliably needs more than regex. Rate is low and there is no reason to expect it to differ
between families, so it should add noise rather than bias.

Note that these fixes addressed *identifiable* error classes. The 0.52 precision shows the
residual problem is not a list of patches but the choice of surface form itself.

## One error class that biases against the finding

In r/healthanxiety, "something wrong with me" is often meant medically ("i wonder if
there's something wrong with me and why i feel like i'm dying") rather than as
self-evaluation. That inflates self-criticism in the agitation family. Since H2b claims
self-criticism is *higher in the dejection family*, this false positive works against the
result, making it conservative rather than inflated.

## Recall

Recall against hard negatives is 0.63 and 0.66, so roughly a third of genuine cases
carrying the surface form are missed. Hard negatives are posts containing the surface form
that the dictionary did not count; posts with no surface form at all are excluded because
they are trivially correct and would inflate any agreement statistic.

This is a sensitivity limit rather than a validity problem for the between-family
contrast, since there is no reason for the miss rate to differ between families. It does
mean the absolute rates must not be read as prevalence.

## Reproducing the validation from scratch

1. `Rscript 05_validate.R` regenerates the stratified sample with a fixed seed. Do this
   first: a sample left over from an earlier run may have come from an older lexicon, and
   coding it would produce precision figures for a dictionary no longer in use.
2. Code `true_label` in `out/validation_sample.csv`, either in a spreadsheet or with
   `python3 code_sample.py`, which shows one item at a time and saves after every answer.
   **Ignore `flagged` and `machine_label` while coding.**
3. `Rscript 05_validate.R --score`.

`--score` no longer regenerates the sample. It used to fall through the generation code
before scoring, which overwrote the file and silently destroyed the coding it was about to
score.
