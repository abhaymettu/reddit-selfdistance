#!/usr/bin/env Rscript
# Tier 1: conceptual replication of the I-talk / depression association.
#
# WHAT THIS IS NOT: a replication of the r = .13 meta-analytic effect (Edwards &
# Holtzman 2017; Tackman et al. 2019). Those estimates come from continuous depression
# scales administered to the same people who produced the language. This dataset has no
# symptom measure at all. Here the criterion is *subreddit membership*, which is a
# different and much cruder estimand. A number near .13 would be a pleasing coincidence,
# not a successful replication, and the report says so.
#
#   Rscript 03_tier1.R

suppressMessages({library(data.table)})

# TWO CONTROL ARMS, AND THE DIFFERENCE BETWEEN THEM IS THE POINT.
#
# The obvious design compares depression subreddits against non-mental-health ones. That
# design returns r = .47, d = 1.1 — nowhere near the r = .13 literature, and it tripped
# the leak gate on the first run. The gate was right, but the leak is not a coding bug.
# It is confounded genre: r/depression and r/suicidewatch are communities whose norm is
# first-person confessional narrative, while r/personalfinance and r/teaching are
# topic-oriented Q&A. Any first-person-pronoun measure separates those two registers
# whether or not anyone is depressed. Dropping r/jokes (the most third-person control)
# barely moved it, so it is not one bad control either — it is the whole arm.
#
# The fix is to hold genre constant: compare against OTHER mental health subreddits,
# where everyone is writing first-person distress narrative and only the disorder varies.
# That contrast is the one that can carry a claim about depression specifically.
DEPRESSION  <- c("depression", "lonely", "suicidewatch")
CTRL_TOPIC  <- c("fitness", "jokes", "personalfinance", "teaching")            # confounded
CTRL_GENRE  <- c("adhd", "autism", "ptsd", "bipolarreddit", "bpd",             # matched
                 "EDAnonymous", "anxiety", "socialanxiety", "healthanxiety")
MIN_TOK    <- 25     # rate denominators explode on short posts
SESOI      <- 0.10   # smallest effect size of interest, declared before looking
LEAK_GATE  <- 0.30   # |r| above this means a bug or a leak, not a discovery

feat <- readRDS("out/features.rds")
cat("Raw posts:", nrow(feat), "\n")

# --- Cleaning, in the order that matters ---------------------------------------------
# Crossposts and copypasta duplicate whole posts across subreddits. Left in, they inflate
# any between-group difference by repeating the same text in one arm.
n0 <- nrow(feat)
feat <- feat[!duplicated(dup_key)]
cat("Dropped exact-duplicate bodies:", n0 - nrow(feat), "\n")

n0 <- nrow(feat); feat <- feat[n_tok >= MIN_TOK]
cat("Dropped posts <", MIN_TOK, "tokens:", n0 - nrow(feat), "\n")

n0 <- nrow(feat); feat <- feat[!author %in% c("[deleted]", "[removed]")]
cat("Dropped deleted/removed authors:", n0 - nrow(feat), "\n")
cat("Analysis posts:", nrow(feat), "\n\n")

# --- Leak check: is one author carrying an arm? --------------------------------------
cat("Largest single-author post count:", feat[, .N, by = author][order(-N)]$N[1],
    "(the release ships one post per author per window, so this caps at n_windows)\n\n")

cat("Per-subreddit mean 1SG rate — read this before any headline number:\n")
arm <- function(s) fifelse(s %in% DEPRESSION, "depression",
                   fifelse(s %in% CTRL_GENRE, "other-MH", "topical"))
print(feat[, .(arm = arm(subreddit[1]), n = .N, mean_1sg = round(mean(rate_1sg), 4),
               median_tok = as.double(median(n_tok))), by = subreddit][order(-mean_1sg)])
cat("\n")

# --- Estimation ----------------------------------------------------------------------
# Primary window is 2019. 2018 and post are held out: an effect that does not survive a
# different time window is a window artifact, and one fit on one slice cannot tell you.
fit_window <- function(d, label) {
  ct <- cor.test(d$rate_1sg, d$grp)          # point-biserial
  r  <- unname(ct$estimate)
  # Cohen's d from the same contrast, since d is the scale the SESOI is stated on
  m1 <- d[grp == 1, rate_1sg]; m0 <- d[grp == 0, rate_1sg]
  sp <- sqrt(((length(m1) - 1) * var(m1) + (length(m0) - 1) * var(m0)) /
             (length(m1) + length(m0) - 2))
  dd <- (mean(m1) - mean(m0)) / sp
  # Adjusted: does the association survive controlling for post length? Long posts differ
  # systematically in register between these communities.
  glmfit <- glm(grp ~ scale(rate_1sg) + scale(log(n_tok)), data = d, family = binomial)
  or <- exp(coef(glmfit)[["scale(rate_1sg)"]])
  data.table(window = label, n = nrow(d), r = r,
             ci_lo = ct$conf.int[1], ci_hi = ct$conf.int[2],
             d = dd, or_adj_1sg = or)
}

run_contrast <- function(ctrl, label) {
  d <- copy(feat)[subreddit %in% c(DEPRESSION, ctrl)]
  d[, grp := as.integer(subreddit %in% DEPRESSION)]
  out <- rbindlist(lapply(c("2019", "2018", "post"),
                          function(w) fit_window(d[window == w], w)))
  out[, contrast := label][]
}

topical <- run_contrast(CTRL_TOPIC, "vs topical subreddits (confounded)")
genre   <- run_contrast(CTRL_GENRE, "vs other mental-health subreddits (genre-matched)")
res     <- rbind(topical, genre)

cat("=== Tier 1 results ===\n")
print(res[, .(contrast, window, n, r = round(r, 4),
              ci = sprintf("[%.3f, %.3f]", ci_lo, ci_hi),
              d = round(d, 3), OR_adj = round(or_adj_1sg, 3))])
cat("\np-values omitted deliberately: at n > 100k everything is significant and the",
    "p-value carries no information.\n")
cat("SESOI was declared at |d| >=", SESOI, "before estimation.\n\n")

fwrite(res, "out/tier1_results.csv")

# --- Leak gate, applied only to the genre-matched contrast ---------------------------
# The topical contrast is retained as a demonstration of the confound, not as an
# estimate, so gating it would just re-report a conclusion we already drew. The
# genre-matched contrast is the one making a claim, so it is the one that must pass.
gmax <- max(abs(genre$r))
if (gmax > LEAK_GATE)
  stop("ABORT: genre-matched |r| = ", round(gmax, 3), " exceeds the ", LEAK_GATE,
       " gate. Still a leak. Check dedup, author overlap, and the pronoun pattern.")
cat("Leak gate passed on the genre-matched contrast (max |r| =", round(gmax, 3), ").\n\n")

# --- Robustness: authors who appear in BOTH arms -------------------------------------
# The release ships one post per author per subreddit-window, but nothing stops a person
# posting in r/depression AND r/anxiety. Those authors sit in both arms of the
# genre-matched contrast, which is a correlated-observations problem that does not exist
# in the topical contrast. If the estimate depends on them, it is partly a within-person
# artifact. Dropping them is the blunt, honest check.
both <- feat[subreddit %in% c(DEPRESSION, CTRL_GENRE),
             .(in_dep = any(subreddit %in% DEPRESSION),
               in_ctl = any(subreddit %in% CTRL_GENRE)), by = author][in_dep & in_ctl, author]
cat("Authors appearing in both arms:", length(both),
    sprintf("(%.1f%% of authors in the contrast)\n",
            100 * length(both) / uniqueN(feat[subreddit %in% c(DEPRESSION, CTRL_GENRE)]$author)))

clean <- copy(feat)[subreddit %in% c(DEPRESSION, CTRL_GENRE) & !author %in% both]
clean[, grp := as.integer(subreddit %in% DEPRESSION)]
rb <- rbindlist(lapply(c("2019", "2018", "post"),
                       function(w) fit_window(clean[window == w], w)))
cat("Genre-matched contrast with cross-arm authors removed:\n")
print(rb[, .(window, n, r = round(r, 4), d = round(d, 3))])

fwrite(rbind(res, rb[, contrast := "genre-matched, cross-arm authors removed"]),
       "out/tier1_results.csv")
cat("\nWrote out/tier1_results.csv\n")

# --- The figure that carries the argument --------------------------------------------
# Subreddits ordered by 1SG rate, coloured by arm. The depression subreddits sit at the
# top, but the other mental-health subreddits sit right underneath them and the topical
# ones fall away below. That vertical structure is the whole Tier 1 story: most of the
# naive effect is the gap between confessional and topical register, not between
# depression and not-depression.
suppressMessages(library(ggplot2))
pd <- feat[, .(mean_1sg = mean(rate_1sg), se = sd(rate_1sg) / sqrt(.N),
               arm = arm(subreddit[1])), by = subreddit]
p <- ggplot(pd, aes(reorder(subreddit, mean_1sg), mean_1sg, colour = arm)) +
  geom_pointrange(aes(ymin = mean_1sg - 1.96 * se, ymax = mean_1sg + 1.96 * se)) +
  coord_flip() +
  labs(x = NULL, y = "First-person singular pronouns per token",
       colour = NULL,
       title = "I-talk separates confessional from topical register",
       subtitle = "Depression subreddits lead, but other mental-health subreddits sit just below them") +
  theme_minimal(base_size = 11) + theme(legend.position = "bottom")
ggsave("out/fig_1sg_by_subreddit.png", p, width = 7, height = 5, dpi = 150)
cat("Wrote out/fig_1sg_by_subreddit.png\n")

# --- Tier 3 feasibility, reported here because it changes the plan --------------------
# The release ships ONE post per author per window. Tier 3 as originally specified
# (>= 5 posts spanning >= 30 days) is therefore impossible on this data. The most any
# author can contribute is one observation per window.
pa <- feat[, .N, by = .(author, window)]
cat("\n--- Tier 3 feasibility ---\n")
cat("Max posts per author per window:", max(pa$N), "\n")
panel <- feat[, .(n_windows = uniqueN(window)), by = author]
cat("Authors in >=2 windows:", sum(panel$n_windows >= 2), "\n")
cat("Authors in all 3 windows:", sum(panel$n_windows >= 3), "\n")
