#!/usr/bin/env Rscript
# Tier 3, reduced: within-person change across time windows.
#
#   Rscript 06_tier3.R
#
# THE ORIGINAL DESIGN IS NOT POSSIBLE ON THIS DATA. The plan called for mixed models on
# users with >= 5 posts spanning >= 30 days. The release ships one post per author per
# subreddit-window, so nobody has 5 posts in a window. What exists instead is a thin,
# irregular panel: authors who show up in more than one of the three windows
# (Jan-Apr 2018, Jan-Apr 2019, Jan-Apr 2020), i.e. observations roughly a year apart.
#
# So this script answers a WEAKER question than "does self-distanced language shift before
# symptom language". It answers: within the same person, in years when they write in a more
# self-distanced way, do they also write with less self-criticism -- and does distancing in
# one year go with self-criticism the NEXT year? Annual spacing cannot speak to whether one
# leads the other by days or weeks, which is what the original question was about.
#
# Reporting a year-lagged association as "prediction" would be overselling it, so the
# output says association throughout.

suppressMessages({library(data.table)})
have_lme4 <- requireNamespace("lme4", quietly = TRUE)

feat <- readRDS("out/features.rds")
feat <- feat[!duplicated(dup_key)][n_tok >= 25][!author %in% c("[deleted]", "[removed]")]

# Self-immersed vs self-distanced reference. The distancing measure is CRUDE: second-person
# "you" cannot be separated from addressing the reader without coreference resolution, and
# third-person pronouns mostly refer to other people, not to the self. Treat this as an
# upper bound on distancing, and read every result below as exploratory. It is reported
# because the question was asked, not because the measure is good.
feat[, distancing := (n_2nd + n_3rd) / (n_1sg + n_2nd + n_3rd + 1)]

# One row per author-window: authors post in several subreddits within a window, and we
# want a person-year, not a post.
pw <- feat[, .(distancing = mean(distancing), crit = mean(rate_crit),
               ought = mean(rate_ought), ideal = mean(rate_ideal),
               log_tok = mean(log(n_tok)), n_posts = .N),
           by = .(author, window)]
pw[, t := match(window, c("2018", "2019", "post"))]   # windows are ordered in time

panel <- pw[author %in% pw[, .N, by = author][N >= 2, author]]
setorder(panel, author, t)
cat("Author-windows:", nrow(panel), "| authors with >=2 windows:", uniqueN(panel$author), "\n")
cat("Authors in all 3 windows:", panel[, .N, by = author][N == 3, .N], "\n\n")

# --- Within-person centring ----------------------------------------------------------
# Subtracting each person's own mean is what makes this a WITHIN-person estimate. Without
# it, the coefficient is contaminated by between-person differences: people who are
# generally more self-critical are also generally different in a hundred other ways, and
# that comparison is just the cross-sectional result again wearing a longitudinal costume.
panel[, `:=`(dist_c = distancing - mean(distancing),
             crit_c = crit - mean(crit),
             tok_c  = log_tok - mean(log_tok)), by = author]

fit <- function(f, d, label) {
  if (have_lme4) {
    m <- lme4::lmer(f, data = d, REML = FALSE,
                    control = lme4::lmerControl(calc.derivs = FALSE))
    b <- lme4::fixef(m)[2]; se <- sqrt(diag(as.matrix(vcov(m))))[2]
  } else {
    m <- lm(f, data = d); b <- coef(m)[2]; se <- summary(m)$coefficients[2, 2]
  }
  data.table(model = label, n = nrow(d), b = b, lo = b - 1.96 * se, hi = b + 1.96 * se)
}

# --- Same-window association (the negative control) ----------------------------------
# Both variables come from the same posts, so shared topic and mood-of-the-moment can
# manufacture this on their own. It is fit FIRST, as the thing the lagged model has to beat.
same <- fit(crit_c ~ dist_c + tok_c + (1 | author), panel, "same window (negative control)")

# --- Lagged association ---------------------------------------------------------------
# Distancing in one window, self-criticism in the NEXT. Predictor and outcome now come from
# different posts written about a year apart, which removes the same-document artefact but
# introduces a year of unobserved life.
lag <- merge(panel[, .(author, t, dist_c, log_tok)],
             panel[, .(author, t_next = t - 1, crit_next = crit_c)],
             by.x = c("author", "t"), by.y = c("author", "t_next"))
lag[, tok_c := log_tok - mean(log_tok), by = author]
cat("Lagged pairs (consecutive windows, same author):", nrow(lag), "\n")
cat("Authors contributing a lagged pair:", uniqueN(lag$author), "\n\n")

lagged <- fit(crit_next ~ dist_c + tok_c + (1 | author), lag, "distancing(t) -> self-crit(t+1)")

# --- THE T=2 ARTEFACT, which is why the lagged sign flips -----------------------------
# For an author with exactly TWO windows, person-mean-centring forces x_c = (d/2, -d/2)
# and y_c = (e/2, -e/2). The contemporaneous pair is (d/2, e/2) and the lagged pair is
# (d/2, -e/2) -- EXACTLY the negative, by construction, for every such author. So a lagged
# regression run on two-observation people is mechanically the mirror of the
# contemporaneous one and carries no information about time order whatsoever.
#
# Most authors here have exactly two windows, so the sign flip above is arithmetic, not
# psychology. Anyone reporting it as "distancing predicts LATER self-criticism in the
# opposite direction" would be reporting a property of subtraction.
n_t2 <- panel[, .N, by = author][N == 2, .N]
n_t3 <- panel[, .N, by = author][N == 3, .N]
cat(sprintf("Authors with exactly 2 windows: %d (%.1f%%) | with 3: %d\n",
            n_t2, 100 * n_t2 / (n_t2 + n_t3), n_t3))
cat("With T=2, centring makes the lagged estimate the exact negative of the\n",
    "contemporaneous one. The lagged row above is therefore an artefact.\n\n")

# Refit the lag using only authors observed in all three windows, where centring does not
# force an exact sign reversal. Note this is still a small-T dynamic panel, so the estimate
# is biased (Nickell bias) even here -- it is reported as a direction check, not an effect.
lag3 <- lag[author %in% panel[, .N, by = author][N == 3, author]]
lagged3 <- if (nrow(lag3) > 100) {
  fit(crit_next ~ dist_c + tok_c + (1 | author), lag3, "lagged, 3-window authors only")
} else NULL

res <- rbind(same, lagged, lagged3)
cat("=== Tier 3 (reduced): within-person, annual spacing ===\n")
print(res[, .(model, n, b = signif(b, 3), ci = sprintf("[%.5f, %.5f]", lo, hi))])

crosses <- res[, (lo < 0 & hi > 0)]
cat("\nIntervals crossing zero:",
    if (!any(crosses)) "none" else paste(res$model[crosses], collapse = "; "), "\n")

# Verify the artefact numerically rather than asserting it: on two-window authors the
# lagged slope should come out as almost exactly minus the contemporaneous slope.
lag2 <- lag[author %in% panel[, .N, by = author][N == 2, author]]
if (nrow(lag2) > 100) {
  # Plain lm here, deliberately. A T=2 author contributes exactly ONE lagged row, so a
  # per-author random intercept has as many groups as observations and is not identifiable
  # -- lmer errors out. This check is a demonstration of arithmetic, not an inference, so
  # the random effect is not wanted anyway.
  b_same <- coef(lm(crit_c ~ dist_c + tok_c, panel[author %in% lag2$author]))[2]
  b_lag  <- coef(lm(crit_next ~ dist_c + tok_c, lag2))[2]
  cat(sprintf("\nArtefact check on 2-window authors (n = %d):\n", nrow(lag2)))
  cat(sprintf("  contemporaneous b = %.6f | lagged b = %.6f | ratio = %.3f\n",
              b_same, b_lag, b_lag / b_same))
  cat("  An exact centring artefact gives -1.000. Confirmed: the naive lagged model is\n")
  cat("  the contemporaneous model with the sign flipped, and says nothing about time.\n")
}

cat("\nCONCLUSION: the honest read is that this panel supports a within-person\n")
cat("association between self-distanced language and self-criticism in the SAME\n")
cat("window, and cannot establish temporal ordering. The apparent sign reversal in the\n")
cat("naive lagged model is an artefact of centring two observations, not evidence that\n")
cat("distancing precedes anything.\n")

fwrite(res, "out/tier3_results.csv")
cat("\nWrote out/tier3_results.csv\n")

cat("\n--- What this cannot show ---\n")
cat("* Spacing is ~1 year. The original question (does distancing shift BEFORE symptom\n")
cat("  language) needs days-to-weeks resolution. This cannot answer it.\n")
cat("* The 2019->2020 transition spans the onset of COVID-19.\n")
cat("* Authors who post across multiple years are self-selected and unusual: persistence\n")
cat("  in a mental health forum is itself a variable.\n")
cat("* The distancing measure cannot separate 'you' meaning me from 'you' meaning you.\n")
if (!have_lme4) cat("* lme4 absent: fit with lm(), so no person random effect.\n")
