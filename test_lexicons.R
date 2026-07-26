#!/usr/bin/env Rscript
# Assertions for the Tier 2 lexicons. Run this before trusting any Tier 2 number.
#
#   Rscript test_lexicons.R
#
# Dictionary methods fail silently: a broken pattern matches nothing and produces a clean,
# publishable-looking null. The cases below are the ones where the measure would be wrong
# in a way that changes the conclusion — mostly advice-giving leaking into the ought self,
# which is the single confound the whole Tier 2 design rests on separating out.

suppressMessages(library(stringi))
source("lexicons.R")

n <- 0L; bad <- 0L
chk <- function(txt, pat, expect, label) {
  got <- stri_count_regex(normalise(txt), pat)
  n <<- n + 1L
  if ((expect == 0 && got != 0) || (expect > 0 && got != expect)) {
    bad <<- bad + 1L
    cat(sprintf("FAIL [%s] expected %d got %d: %s\n", label, expect, got, txt))
  }
}

# --- OUGHT: must fire on first-person obligation ---
chk("I should call my doctor tomorrow.",        OUGHT, 1, "ought/basic")
chk("I really should get out of bed.",          OUGHT, 1, "ought/hedged")
chk("I have to keep going for my family.",      OUGHT, 1, "ought/have-to")
chk("I need to be better than this.",           OUGHT, 1, "ought/need-to")
chk("I ought to have known better.",            OUGHT, 1, "ought/ought-to")
# Past-tense external necessity is not an ought self, and was never in the prereg.
chk("I had to call the cops on her.",           OUGHT, 0, "ought/had-to-excluded")
chk("I had to be rushed to the ER.",            OUGHT, 0, "ought/had-to-narrative")

# --- OUGHT: must NOT fire on advice or on a second-person subject ---
# This is the confound that would otherwise turn Tier 2 into a measure of how chatty a
# support community is.
chk("You should see a doctor about that.",      OUGHT, 0, "ought/2nd-person")
chk("She should probably talk to someone.",     OUGHT, 0, "ought/3rd-person")
chk("I think you should leave him.",            OUGHT, 0, "ought/embedded-advice")
chk("Everyone here should be kinder.",          OUGHT, 0, "ought/quantifier")

# --- ADVICE: the mirror image, must fire exactly where OUGHT does not ---
chk("You should see a doctor about that.",      ADVICE, 1, "advice/basic")
chk("I think you should leave him.",            ADVICE, 1, "advice/embedded")
chk("I should call my doctor tomorrow.",        ADVICE, 0, "advice/no-false-positive")

# --- OUGHT fillers: discourse markers are not obligations ---
# Each of these matches OUGHT by construction, so the subtraction must cancel it exactly.
for (s in c("I have to say this is rough.", "I should mention I am on medication.",
            "I need to know if this is normal.", "I have to admit I relapsed.")) {
  o <- stri_count_regex(normalise(s), OUGHT)
  f <- stri_count_regex(normalise(s), OUGHT_FILLER)
  n <- n + 1L
  if (o - f != 0) { bad <- bad + 1L
    cat(sprintf("FAIL [filler] net %d (ought %d filler %d): %s\n", o - f, o, f, s)) }
}
for (s in c("I need to vent about my week.", "I need to rant for a second.",
            "I must be underestimating myself.", "I must have missed the appointment.")) {
  o <- stri_count_regex(normalise(s), OUGHT)
  f <- stri_count_regex(normalise(s), OUGHT_FILLER)
  n <- n + 1L
  if (o - f != 0) { bad <- bad + 1L
    cat(sprintf("FAIL [filler2] net %d (ought %d filler %d): %s\n", o - f, o, f, s)) }
}
# Deontic "must" is a real ought and must survive the epistemic exclusion.
{
  s <- "I must stop doing this to myself."
  net <- stri_count_regex(normalise(s), OUGHT) - stri_count_regex(normalise(s), OUGHT_FILLER)
  n <- n + 1L
  if (net != 1) { bad <- bad + 1L
    cat(sprintf("FAIL [deontic-must] net %d, expected 1: %s\n", net, s)) }
}
# ...but a filler must not cancel a real obligation elsewhere in the same post.
{
  s <- "I have to say this is rough. I should quit my job."
  net <- stri_count_regex(normalise(s), OUGHT) - stri_count_regex(normalise(s), OUGHT_FILLER)
  n <- n + 1L
  if (net != 1) { bad <- bad + 1L
    cat(sprintf("FAIL [filler/oversubtract] net %d, expected 1: %s\n", net, s)) }
}

# --- IDEAL: counterfactual regret and unmet aspiration ---
chk("I should have been a better father.",      IDEAL, 1, "ideal/should-have")
chk("I wish I were someone else.",              IDEAL, 1, "ideal/wish")
chk("If only I had tried harder.",              IDEAL, 1, "ideal/if-only")
chk("I used to be the smart one.",              IDEAL, 1, "ideal/used-to-be")
chk("I wanted to be a doctor.",                 IDEAL, 1, "ideal/wanted-to-be")
chk("You should have told me.",                 IDEAL, 0, "ideal/2nd-person")
# The ought/ideal split is the entire hypothesis, so a bare obligation must not read as
# ideal-discrepancy and vice versa.
chk("I should call my doctor tomorrow.",        IDEAL, 0, "ideal/not-plain-ought")

# --- SELFCRIT ---
chk("I am worthless and everyone knows it.",    SELFCRIT, 1, "crit/copula")
chk("I'm such a failure.",                      SELFCRIT, 1, "crit/contraction")
chk("I hate myself for it.",                    SELFCRIT, 1, "crit/hate-myself")
chk("I feel like a burden to everyone.",        SELFCRIT, 1, "crit/burden")
chk("There is something wrong with me.",        SELFCRIT, 1, "crit/something-wrong")
chk("I’m such a failure.",                 SELFCRIT, 1, "crit/curly-apostrophe")
chk("I feel like such a worthless idiot.",      SELFCRIT, 1, "crit/like-plus-modifiers")
chk("You are worthless.",                       SELFCRIT, 0, "crit/2nd-person")
chk("My job is stupid and useless.",            SELFCRIT, 0, "crit/object-not-self")

# --- normalise() must not destroy matches ---
chk("I SHOULD go. https://x.com/a &amp;gt; I am worthless",
    OUGHT, 1, "normalise/case-and-url")

cat(sprintf("\n%d checks, %d failures\n", n, bad))
if (bad > 0) stop("Lexicon tests failed. Fix before running Tier 2.")
cat("All lexicon checks passed.\n")
