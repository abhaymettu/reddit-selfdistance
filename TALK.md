# Five minutes, out loud

Notes for saying this in a meeting. Not a script — the beats, in order, with the numbers
that matter and the honest answers to the obvious pushback.

---

## 1. The question (30s)

There is a well-known finding that depressed people use more first-person singular
pronouns — more "I", "me", "my". The meta-analytic effect is about *r* = .13. Small but
real.

I wanted to test something more specific. Higgins' self-discrepancy theory says failing to
meet your **ought** self — duties, obligations — produces *anxiety*, while failing to meet
your **ideal** self — hopes, aspirations — produces *dejection*. That's a 40-year-old
prediction about two different kinds of self-failure. Nobody has tested whether those two
show up as different linguistic signatures at scale.

## 2. The data, and its central weakness (30s)

478,000 Reddit posts across 16 subreddits, three time windows, public dataset from Low et
al. 2020.

Say the weakness before anyone asks: **there is no symptom measure in this data.** I never
observe depression. I observe which subreddit someone posted in. Everything I say is about
community membership, not severity. I've requested DAIC-WOZ, which has PHQ-8 scores, for
the version of this that can use the word "severity."

## 3. The finding I did not expect (90s — this is the important part)

I started by replicating the pronoun effect. Depression subreddits versus ordinary ones —
r/fitness, r/personalfinance, r/jokes, r/teaching.

I got *r* = .47. Three and a half times the published effect.

That is not a discovery, that's a bug or a confound, and I had written an abort gate into
the script at *r* = .30 precisely so I couldn't talk myself into believing it. It fired.

The confound is **genre**. r/depression and r/suicidewatch are communities whose entire
norm is telling your own story in the first person. r/personalfinance is people asking
questions about their 401k. Counting "I" separates confessional writing from topical
writing, and it does that whether or not anybody is depressed.

So I changed the comparison group to *other mental health subreddits* — anxiety, ADHD,
PTSD, BPD — where everyone is writing first-person distress narrative and only the disorder
varies. The effect halved, to *r* = .21, stable across all three years.

**About half of the published-looking result was register, not depression.** If I show one
thing from this project, it's that.

## 4. The actual test (90s)

Now the Higgins test, with genre held constant. Two families, both first-person distress
writing:

- **Agitation:** anxiety, social anxiety, health anxiety
- **Dejection:** depression, lonely, suicide watch

Ought self measured as first-person modal obligation — "I should", "I have to", "I need to".
The crucial restriction is **first person**. "You should see a doctor" is a modal of
obligation with no ought self in it at all, and support forums are drowning in it. Counting
modals without that restriction measures how much advice a community gives.

Ideal self measured as counterfactual regret and unmet aspiration — "I wish", "if only",
"I should have been", "I used to be".

Result: obligation language runs slightly *higher* in the anxiety family. Regret and unmet
aspiration run clearly higher in the depression family. Since both markers come from the
same post, I test the crossover as a within-post difference score: *d* = 0.13, same
direction and magnitude in all three years.

**That's Higgins' prediction, in the direction he predicted, in language, at scale.**

## 5. Why I don't oversell it (60s — say this unprompted)

Three things, and I'd rather say them than have them found.

**It's asymmetric.** The ought half is *d* = −0.03, below the smallest effect size I
declared as interesting before I started. It points the right way but can't stand alone.
The crossover is carried by the ideal side. That's weaker than a true double dissociation.

**My real sample size is six, not 197,000.** The post-level confidence interval is
hairline-thin, but it describes uncertainty about *these six communities*. Treat each
community as one data point and the exact permutation test gives *p* = .10 — which is the
*floor* for a three-versus-three split. The rank separation is perfect, all three anxiety
communities on one side, all three depression communities on the other. So the evidence is
as strong as six communities can make it, and six communities isn't much.

**The corrections went against me and I kept them.** Hand-coding a validation sample showed
my obligation dictionary was catching "I had to call the cops" — past-tense external
circumstance, not an internalized standard. Also epistemic "I must be underestimating
myself," which is a guess, not a duty. Fixing those weakened the effect from 0.144 to
0.133. I applied them anyway, and `had to` was never in my preregistration in the first
place.

## 6. Close (20s)

Preregistered before running, committed to git before the analysis script existed, so the
ordering is checkable. 41 assertions on the dictionaries, mostly guarding against
advice-giving leaking into the obligation measure. Whole thing reproduces from a clean
checkout.

What I'd want next: the DAIC-WOZ severity scores, more communities per family so the unit
of analysis isn't six, and a human coder on the validation sample instead of me.

---

## Likely questions

**"Isn't r = .21 still just genre?"** Probably partly, yes. Even within mental health
communities, r/depression is more about the self than r/adhd is. I'd expect the true
disorder-specific effect to be below .21. Notably r/autism scores *lower* on I-talk than
r/personalfinance, which shows the register axis cuts across the clinical one.

**"Why not just use LIWC?"** The dataset ships LIWC columns. I checked one against raw
text: on a post with four unambiguous first-person pronouns, `liwc_1st_pers` reads 0. I
computed my own and validated it against the dataset's independent tokenizer at *r* = .9995.

**"Why not a mixed model with author random effects?"** That was the plan. The release
ships one post per author per subreddit-window, so within-person modeling isn't possible.
20,575 authors appear in two or more windows at multi-month gaps, which supports a coarse
between-window contrast but not the "does language shift *before* symptoms" question. I
descoped it rather than dress it up.

**"Could this be COVID?"** The 2020 window overlaps the pandemic onset. That's why the
primary analysis is 2019 with 2018 and 2020 held out. The effect is the same size in all
three.
