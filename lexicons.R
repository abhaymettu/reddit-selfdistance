# Lexicons for Tier 1 and Tier 2. Sourced by 02_features.R and by test_lexicons.R, so
# the patterns that get tested are literally the patterns that get run. Duplicating them
# into the test would let the two drift apart, which is the failure mode that makes
# dictionary methods untrustworthy in the first place.
#
# NOTE ON ESCAPING: these live in a file and are never passed via `Rscript -e`. Backslash
# escapes do not survive the shell reliably, and they fail *silently* by matching nothing,
# which is indistinguishable from a real null result. That cost a debugging cycle.

PRON_1SG <- "\\b(i|me|my|mine|myself|i'm|i've|i'll|i'd)\\b"
TOKEN    <- "[a-z0-9']+"

# Optional hedge/adverb slot so "i really should" and "i just need to" are caught. A
# closed list rather than \w+ so it cannot swallow a subject and match across a clause
# boundary ("i think you should" must not count as a first-person obligation).
HEDGE <- "(?:really |just |always |still |probably |also |honestly |literally |definitely )*"

# OUGHT SELF: first-person modal obligation. The first-person restriction is the whole
# point. "you should see a doctor" is a modal of obligation containing no ought self at
# all, and support subreddits are saturated with it — an unrestricted modal count measures
# how much a community gives advice, nothing more.
# "had to" is deliberately EXCLUDED. It was in an early draft of this file but not in the
# preregistered pattern, and hand-coding the validation sample showed why the prereg was
# right: roughly a third of flagged spans were past-tense narration of external necessity
# ("i had to call the cops", "i had to be rushed to the e.r."), which is circumstance, not
# an internalised self-guide. Removing it restores the preregistered definition.
OUGHT <- paste0("\\bi ", HEDGE, "(?:should|ought to|have to|need to|must|gotta)\\b")

# Fillers: syntactically identical to OUGHT, semantically empty. "i have to say this is
# bad" is a discourse marker, not an obligation the writer feels bound by.
# Two classes found by hand-coding the validation sample, both added here:
#  - discourse-purpose statements ("i need to vent", "i need to rant"). These announce the
#    speech act rather than express a standard the writer is failing to meet. Same logic as
#    "i have to say", which was already excluded.
#  - EPISTEMIC "must" ("i must be underestimating myself", "i must have missed it"), which
#    is an inference, not an obligation. Deontic "must" ("i must stop") is kept.
OUGHT_FILLER <- paste0("\\bi ", HEDGE,
  "(?:should |have to |need to |must )",
  "(?:mention|say|admit|note|ask|add|point out|clarify|confess|tell you|know",
  "|vent|rant|get this off|preface)\\b",
  "|\\bi ", HEDGE, "must (?:be|have been|have|not be)\\b")

# ADVICE MODALS: the confound, measured directly so it can be controlled rather than
# hoped away.
ADVICE <- paste0("\\b(?:you|he|she|they|we) ", HEDGE,
                 "(?:should|ought to|have to|need to|must|gotta)\\b")

# IDEAL SELF: counterfactual regret and unmet aspiration, first-person only. This is the
# half the original brief left out; without it Higgins' prediction has no contrast to be
# tested against.
IDEAL <- paste0(
  "\\bi ", HEDGE, "(?:should|could|would)(?:'ve| have)\\b",
  "|\\bi ", HEDGE, "wish\\b",
  "|\\bif only i\\b",
  "|\\bi ", HEDGE, "used to be\\b",
  "|\\bi ", HEDGE, "was supposed to\\b",
  "|\\bi ", HEDGE, "(?:wanted|meant) to be\\b",
  "|\\bwhat i could have been\\b")

# SELF-CRITICISM: seeded from FSCRS (Gilbert et al. 2004) inadequate-self and hated-self
# item content, restricted to first-person subjects so second-person insults do not count.
SELFCRIT <- paste0(
  # Subject+copula must be one alternation: "i'm" has no space to sit between "i" and
  # "'m", so a "\\bi " prefix silently misses every contracted self-statement — which is
  # most of them in this register.
  "\\b(?:i am|i'm|i was|i feel|i felt|i look|i sound|i seem|i've been|i get) ", HEDGE,
  "(?:like )?(?:so |such |a |an |really |completely |totally |absolutely |just |kind of )*",
  "(?:worthless|useless|pathetic|stupid|idiot|idiotic|failure|disgusting|inadequate",
  "|broken|hopeless|weak|ugly|burden|garbage|trash|loser|unlovable|repulsive|a mess)\\b",
  "|\\bi ", HEDGE, "(?:hate|despise|loathe|disgust|blame|resent) myself\\b",
  "|\\b(?:disappointed|ashamed|embarrassed|disgusted) (?:in|with|of) myself\\b",
  "|\\bhard on myself\\b|\\bmy own fault\\b|\\bi'?m not good enough\\b",
  "|\\bi ", HEDGE, "deserve (?:to|it|this|nothing|worse|punishment)\\b",
  "|\\bsomething (?:is )?wrong with me\\b|\\bi ruin(?:ed)? everything\\b")

# SELF-DISTANCING (exploratory — H2c). Second-person self-reference cannot be told apart
# from addressing the reader without coreference resolution, so this is a crude upper
# bound and is reported as one, net of the advice rate.
PRON_2ND <- "\\b(you|your|yours|yourself|you're|you've)\\b"
PRON_3RD <- "\\b(he|she|they|him|her|them|his|hers|their)\\b"

# Normalise a post the same way everywhere: lowercase, strip URLs and reddit HTML
# entities. Applied identically in the pipeline and in the validation sample, so the
# hand-coded precision estimate describes the counter that actually runs.
normalise <- function(x) {
  x <- stringi::stri_trans_tolower(x)
  # Curly apostrophes are common in Reddit text and would make "i'm" fail to match a
  # pattern written with a straight quote. Another silent-deflation bug, so fold them
  # before anything else looks at the string.
  x <- stringi::stri_replace_all_fixed(x, "’", "'")
  x <- stringi::stri_replace_all_regex(x, "https?://\\S+|www\\.\\S+", " ")
  stringi::stri_replace_all_regex(x, "&amp;#x200b;|&amp;|&gt;|&lt;", " ")
}
