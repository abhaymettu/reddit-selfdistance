#!/usr/bin/env Rscript
# Tier 2: does the ought-self signal behave differently from the ideal-self signal?
# Hypotheses preregistered in PREREG.md, committed before this file existed.
#
#   Rscript test_lexicons.R && Rscript 04_tier2.R
#
# Higgins (1987) predicts ought-discrepancy pairs with agitation and ideal-discrepancy
# with dejection. The test is therefore a DOUBLE DISSOCIATION between two subreddit
# families that are both first-person distress narrative — holding constant the register
# confound that ate half the Tier 1 effect.

suppressMessages(library(data.table))
source("lexicons.R")

AGITATION <- c("anxiety", "socialanxiety", "healthanxiety")
DEJECTION <- c("depression", "lonely", "suicidewatch")
MIN_TOK   <- 25
SESOI     <- 0.10
LEAK_GATE <- 0.30

feat <- readRDS("out/features.rds")
feat <- feat[!duplicated(dup_key)][n_tok >= MIN_TOK][
             !author %in% c("[deleted]", "[removed]")][
             subreddit %in% c(AGITATION, DEJECTION)]
feat[, family := factor(fifelse(subreddit %in% DEJECTION, "dejection", "agitation"),
                        levels = c("agitation", "dejection"))]
feat[, log_tok := log(n_tok)]

cat("Analysis posts:", nrow(feat), "\n")
print(feat[, .(n = .N, ought = round(mean(rate_ought), 5), ideal = round(mean(rate_ideal), 5),
               crit = round(mean(rate_crit), 5), advice = round(mean(rate_advice), 5)),
           by = .(family, subreddit)][order(family, subreddit)])
cat("\n")

# --- Effect size helper ---------------------------------------------------------------
d_between <- function(x, g) {
  a <- x[g == "agitation"]; b <- x[g == "dejection"]
  sp <- sqrt(((length(a) - 1) * var(a) + (length(b) - 1) * var(b)) /
             (length(a) + length(b) - 2))
  (mean(b) - mean(a)) / sp          # positive = higher in DEJECTION
}

# --- Per-marker main effects, adjusted for the advice confound ------------------------
# Adjusted coefficients come from a model with the advice-modal rate in it, because the
# raw ought difference between two support communities is partly just how much advice
# each one hands out.
marker_fit <- function(d, marker) {
  f <- as.formula(paste0("rate_", marker, " ~ family + log_tok + rate_advice"))
  m <- lm(f, data = d)
  ci <- confint(m, "familydejection")
  data.table(marker = marker,
             d_raw  = d_between(d[[paste0("rate_", marker)]], d$family),
             b_adj  = coef(m)[["familydejection"]],
             lo = ci[1], hi = ci[2],
             # presence/absence, immune to the zero-inflation objection
             or_presence = exp(coef(glm(as.formula(paste0("I(n_", marker,
                                " > 0) ~ family + log_tok")), d, family = binomial))[["familydejection"]]))
}

primary <- feat[window == "2019"]
main <- rbindlist(lapply(c("ought", "ideal", "crit"), function(m) marker_fit(primary, m)))
cat("=== Main effects, 2019 (positive = higher in DEJECTION family) ===\n")
print(main[, .(marker, d_raw = round(d_raw, 3), b_adj = signif(b_adj, 3),
               OR_presence = round(or_presence, 3))])
cat("\n")

# --- H2a: the double dissociation -----------------------------------------------------
# Both markers are measured on the SAME post, so the interaction can be tested as a
# within-post difference score rather than a stacked model with correlated rows. Each
# marker is z-scored on the pooled sample first, since ought and ideal have different
# base rates and raw coefficients would not be comparable across them.
#
# delta = z(ideal) - z(ought).  Higgins predicts delta is HIGHER in the dejection family.
# A main effect on either marker alone is not support; the difference score is the test.
dissociation <- function(d, label) {
  z <- function(x) (x - mean(x)) / sd(x)
  d <- copy(d)[, delta := z(rate_ideal) - z(rate_ought)]
  m <- lm(delta ~ family + log_tok + rate_advice, data = d)
  ci <- confint(m, "familydejection")
  data.table(window = label, n = nrow(d),
             d_delta = d_between(d$delta, d$family),
             b_adj = coef(m)[["familydejection"]], lo = ci[1], hi = ci[2])
}

h2a <- rbindlist(lapply(c("2019", "2018", "post"),
                        function(w) dissociation(feat[window == w], w)))
cat("=== H2a: ideal-minus-ought difference score (positive = Higgins' prediction) ===\n")
print(h2a[, .(window, n, d_delta = round(d_delta, 3), b_adj = round(b_adj, 4),
              ci = sprintf("[%.4f, %.4f]", lo, hi))])

supported <- all(h2a$d_delta > 0) && abs(h2a$d_delta[1]) >= SESOI
cat("\nH2a:", if (supported) "SUPPORTED" else "NOT SUPPORTED",
    "— direction consistent across windows:", all(h2a$d_delta > 0),
    "| primary |d| >= SESOI:", abs(h2a$d_delta[1]) >= SESOI, "\n")

# ASYMMETRY CHECK. The prereg required both halves to hold. They do directionally, but a
# crossover carried entirely by one marker is a weaker claim than a true double
# dissociation, and reporting it as "supported" without this line would overstate it.
ought_d <- main[marker == "ought"]$d_raw; ideal_d <- main[marker == "ideal"]$d_raw
cat(sprintf("  ought  d = %+.3f (agitation higher: %s) %s\n", ought_d,
            ought_d < 0, if (abs(ought_d) < SESOI) "** BELOW SESOI **" else ""))
cat(sprintf("  ideal  d = %+.3f (dejection higher: %s) %s\n", ideal_d,
            ideal_d > 0, if (abs(ideal_d) < SESOI) "** BELOW SESOI **" else ""))
if (abs(ought_d) < SESOI)
  cat("  => ASYMMETRIC: the crossover is carried by the ideal marker. The ought side is\n",
      "     directionally as Higgins predicts but too small to stand on its own.\n")

# The preregistered falsification condition: both markers moving the same way is generic
# distress severity, not self-discrepancy structure.
same_dir <- sign(main[marker == "ought"]$d_raw) == sign(main[marker == "ideal"]$d_raw)
cat("Falsification check — both markers move the same direction:", same_dir,
    if (same_dir) "  <-- consistent with generic distress, NOT a dissociation\n" else "\n")

# --- H2b: self-criticism ---------------------------------------------------------------
h2b <- rbindlist(lapply(c("2019", "2018", "post"), function(w)
  cbind(window = w, marker_fit(feat[window == w], "crit"))))
cat("\n=== H2b: self-criticism, higher in dejection family? ===\n")
print(h2b[, .(window, d = round(d_raw, 3), OR_presence = round(or_presence, 3))])
cat("H2b:", if (all(h2b$d_raw > 0) && abs(h2b$d_raw[1]) >= SESOI) "SUPPORTED" else "NOT SUPPORTED", "\n")

# --- H2c (exploratory): self-distancing -------------------------------------------------
# Second-person rate cannot be separated from addressing the reader without coreference
# resolution, so this is an upper bound and is labelled exploratory in the prereg.
h2c <- feat[window == "2019", .(rate_2nd = mean(rate_2nd), rate_3rd = mean(rate_3rd),
                                rate_1sg = mean(rate_1sg)), by = family]
cat("\n=== H2c (EXPLORATORY, contaminated by reader-addressing) ===\n")
print(h2c)

# --- Robustness: authors in both families ---------------------------------------------
both <- feat[, .(a = any(family == "agitation"), d = any(family == "dejection")),
             by = author][a & d, author]
cat("\nAuthors in both families:", length(both),
    sprintf("(%.1f%%)\n", 100 * length(both) / uniqueN(feat$author)))
rb <- dissociation(feat[window == "2019" & !author %in% both], "2019 no cross-family")
print(rb[, .(window, n, d_delta = round(d_delta, 3))])

# --- THE UNIT-OF-ANALYSIS PROBLEM ------------------------------------------------------
# The CIs above are post-level, and at n = 66k they are hairline thin. They describe
# uncertainty about *these six communities*, not about agitation and dejection disorders
# in general. For the family-level claim the effective sample size is 6, not 197,106.
# Leave-one-subreddit-out is the cheapest honest check: if dropping any single community
# collapses the effect, the finding is about that community, not about the construct.
cat("\n=== Leave-one-subreddit-out on H2a (2019) ===\n")
loo <- rbindlist(lapply(c(AGITATION, DEJECTION), function(s) {
  d <- feat[window == "2019" & subreddit != s]
  cbind(dropped = s, dissociation(d, "2019")[, .(n, d_delta = round(d_delta, 3))])
}))
print(loo)
cat("Range of d_delta across leave-one-out fits: [",
    sprintf("%.3f, %.3f", min(loo$d_delta), max(loo$d_delta)), "]\n")
if (min(loo$d_delta) <= 0)
  cat("WARNING: at least one community carries the whole effect. Do not generalise.\n")

# Subreddit-level means: the six numbers the family claim actually rests on.
cat("\nPer-subreddit ideal-minus-ought z-difference (the 6 real data points):\n")
zz <- copy(feat[window == "2019"])
zz[, delta := (rate_ideal - mean(rate_ideal)) / sd(rate_ideal) -
              (rate_ought - mean(rate_ought)) / sd(rate_ought)]
sub_means <- zz[, .(n = .N, mean_delta = mean(delta)), by = .(family, subreddit)][
                order(family, -mean_delta)]
print(sub_means[, .(family, subreddit, n, mean_delta = round(mean_delta, 3))])

# Exact permutation test at the level the claim is actually made. Treating each community
# as one observation, there are choose(6,3) = 20 ways to split them into two families of
# three. The p-value is the share of splits giving a separation at least this extreme.
# With 3 vs 3 the smallest attainable one-sided p is 1/20 = .05, so this test cannot
# produce a small p no matter how clean the data — which is exactly why it is the honest
# one to report next to a post-level CI of [0.178, 0.226].
obs <- mean(sub_means[family == "dejection"]$mean_delta) -
       mean(sub_means[family == "agitation"]$mean_delta)
combs <- combn(6, 3)
perm <- apply(combs, 2, function(i)
  mean(sub_means$mean_delta[i]) - mean(sub_means$mean_delta[-i]))
p_exact <- mean(abs(perm) >= abs(obs))
cat(sprintf("\nCommunity-level exact permutation test (n = 6 communities):\n"))
cat(sprintf("  observed family difference = %.3f | two-sided p = %.3f (floor = %.3f)\n",
            obs, p_exact, 2 / ncol(combs)))
cat("  Perfect rank separation:",
    max(sub_means[family == "agitation"]$mean_delta) <
    min(sub_means[family == "dejection"]$mean_delta), "\n")

# --- Leak gate --------------------------------------------------------------------------
if (max(abs(main$d_raw)) > LEAK_GATE * 3.4)   # d ~ 3.4x r in this range
  stop("ABORT: a marker effect is implausibly large. Diagnose before writing anything up.")

fwrite(rbind(h2a[, .(test = "H2a", window, n, effect = d_delta, lo, hi)],
             rb[,  .(test = "H2a_no_cross", window, n, effect = d_delta, lo, hi)]),
       "out/tier2_results.csv")
fwrite(main, "out/tier2_main_effects.csv")
cat("\nWrote out/tier2_results.csv, out/tier2_main_effects.csv\n")
