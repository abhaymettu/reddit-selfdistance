Registered 2026-07-27 at https://osf.io/z3uph/
This file is the source text of that registration, kept here for version history.

TRANSPARENCY STATEMENT

Scope. This registration covers Tier 2 of the project only.

Tier 1 was run before this registration and is not covered by it. It is reported in the
repository as prior work motivating the design below.

Tier 3, a within-person panel analysis, is not covered either. It was never preregistered.
It was run after this document was written, but that is not the same as being specified in
advance, and none of the rules below govern it. The repository reports it as exploratory;
its headline effect was subsequently found to be an arithmetic artifact of centring.

Tier 2 was specified before its analysis was written. The ordering is verifiable in the
public commit history at https://github.com/abhaymettu/reddit-selfdistance. PREREG.md was
first committed at 2026-07-26 17:48:07 -0500 (e8a2ae6) and the Tier 2 analysis script at
18:15:23 (c9c9667). PREREG.md was edited once afterwards; that commit changed punctuation
and a byline and altered no hypothesis, threshold, lexicon definition, or falsification
criterion.

Timing of posting. This document is posted to OSF after the Tier 2 analyses were run, so
it is not a prospective registration. What the commit history establishes is that the
hypotheses, the smallest effect size of interest, the leak gate, the falsification
condition, and the dictionary validation threshold were fixed before the analyses they
govern.

Validation status. The dictionary validation specified below has been completed. 200 items
were hand-coded by the author, blind to the dictionary's own classifications. Ought
precision was 0.52, 95% CI [0.374, 0.663]. Self-criticism precision was 0.94, 95% CI
[0.835, 0.987]. Under the threshold specified below, H2a is reported as exploratory rather
than confirmatory. That change has been applied in the repository README and report.


PREREGISTRATION, TIER 2: OUGHT-SELF AND IDEAL-SELF LINGUISTIC SIGNATURES


BACKGROUND

Higgins (1987) predicts a specific dissociation. Ought-self discrepancy produces
agitation-related affect (anxiety, threat). Ideal-self discrepancy produces
dejection-related affect (sadness, disappointment). The prediction is about which
discrepancy pairs with which emotion, not about overall discrepancy magnitude.

That structure has never been tested at scale with a direct linguistic
operationalization. Modal verbs of obligation are a plausible surface marker of the ought
self; counterfactual and unmet-aspiration language is the corresponding marker for the
ideal self.


WHY THIS IS AN INTERACTION AND NOT TWO MAIN EFFECTS

A main effect of obligation language on a depression grouping is uninterpretable. It is
confounded with generic distress, and with advice-giving register, since "you should see
a doctor" is a modal of obligation with no ought self in it.

Tier 1 already demonstrated how badly register confounds pass themselves off as findings
in this corpus. Comparing depression subreddits against topical subreddits gave r = .47 on
a measure that should sit near .13, and roughly half of that was genre.

So the test is a double dissociation across two subreddit families, both of which are
first-person distress narrative.

  Agitation family: anxiety, socialanxiety, healthanxiety
  Dejection family: depression, lonely, suicidewatch


HYPOTHESES

H2a (primary). A family by marker-type interaction. Self-directed ought-modal rate is
higher in the agitation family than in the dejection family, AND ideal-discrepancy rate is
higher in the dejection family than in the agitation family. Both directions must hold. A
single main effect in either marker does not support H2a.

H2b. Self-directed negative evaluation (FSCRS-seeded) is higher in the dejection family
than the agitation family.

H2c (exploratory, not confirmatory). Self-distanced reference (second- and third-person
self-reference, self-naming) is lower in the dejection family. Flagged exploratory because
the base rate of self-naming in this corpus is unknown and likely small.


MEASURES

All rates are per token, using the same tokenizer for numerator and denominator, validated
against the dataset's independent count at r = .9994.

Ought self: first-person modal obligation only, of the form "i (really/just/...)
should / ought to / have to / need to / must / gotta". Second- and third-person modals are
counted separately as an advice-giving covariate, not folded in. Discourse fillers are
excluded: "i should mention", "i need to say", "i have to admit", "i have to say".

Ideal self: "should have", "could have been", "if only", "i wish", "supposed to be",
"wanted to be", "used to be", restricted to first-person contexts.

Self-criticism: seed lexicon from FSCRS inadequate-self and hated-self item content,
restricted to first-person subjects.

Self-distancing: second-person and third-person self-reference, and self-naming, defined
as a recurring capitalized sentence subject that is not a known interlocutor.


ANALYSIS

Post-level linear models. Outcome is marker rate. Predictors are family (agitation vs
dejection), log token count, advice-modal rate, and window. The interaction is tested by
fitting both markers and comparing the family coefficient across them, via a stacked model
with a marker by family term.

Primary window is 2019. The 2018 and post-2019 windows are held out as replication. An
effect that does not hold sign and rough magnitude in all three windows is reported as a
window artifact regardless of significance.


INFERENCE RULES, FIXED IN ADVANCE

Smallest effect size of interest is absolute d of 0.10. Effects below this are reported as
null regardless of p.

P-values are not reported as evidence. At n above 100,000 they are uninformative. Effect
sizes with 95% confidence intervals only.

Leak gate: any absolute r above 0.30 on a single marker triggers a stop-and-diagnose, not
a writeup. Tier 1 tripped this gate and the diagnosis changed the design. The same rule
applies here.

Authors appearing in both families are removed in a preregistered robustness check.


DICTIONARY VALIDATION, REQUIRED BEFORE H2 IS REPORTED

200 sampled posts, hand-coded by the author, for presence of a self-directed ought
statement and presence of self-directed negative evaluation. The sample is stratified: 50
posts the dictionary flagged and 50 hard negatives per marker, where a hard negative
contains the surface form but was not counted. Posts with no surface form at all are
excluded because they are trivially correct and would inflate any agreement statistic.

Precision and recall against those codes are reported alongside the results.

If precision on the ought dictionary is below .70, the measure is reported as unvalidated
and H2a is downgraded to exploratory.

Note on the resolution of this threshold. With only 50 flagged items per marker, a
precision estimate landing near the cutoff would carry a confidence interval wide enough
to straddle it, and the sample could not then decisively resolve its own gate. The rule is
therefore applied to the point estimate, with the confidence interval reported alongside so
a reader can judge how sharp the decision was.

In the event, ought precision was 0.52 with a 95% confidence interval of [0.374, 0.663].
The interval lies entirely below the cutoff.


WHAT WOULD FALSIFY H2A

Both markers moving in the same direction across families. That is generic distress
severity, not self-discrepancy structure. This is the most likely outcome and it will be
reported as such.
