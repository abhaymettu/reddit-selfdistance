#!/usr/bin/env Rscript
# Dictionary validation sample, required by PREREG.md before H2 results are reported.
#
#   Rscript 05_validate.R
#
# Produces out/validation_sample.csv: 200 posts, stratified so that both the precision
# and the recall questions can be answered.
#   - 50 posts the OUGHT dictionary flagged      -> precision
#   - 50 posts it did not flag but that contain a modal verb somewhere -> recall (these
#     are the hard negatives; unflagged posts with no modal at all are trivially correct
#     and would inflate any agreement statistic)
#   - 50 flagged by SELFCRIT, 50 hard negatives for SELFCRIT
#
# The file contains raw post text, so it is gitignored and never committed.
# Coding instructions are written into the file header so the task is reproducible by
# someone who has not read this script.

suppressMessages({library(data.table); library(stringi)})

# --- Scoring mode ---------------------------------------------------------------------
# This runs BEFORE the sample is built, and exits. Scoring used to fall through the
# generation code first, which overwrote out/validation_sample.csv and destroyed the
# coding it was about to score. Anyone who coded 200 rows and then ran --score lost them.
if ("--score" %in% commandArgs(TRUE)) {
  v <- fread("out/validation_sample.csv")
  # Which coding to score. true_label is the human column and stays the default, so
  # the preregistered check is unchanged. machine_label holds an LLM coding of the same
  # 200 rows, kept in a separate column precisely so it cannot be mistaken for the
  # human pass, and so the two can be compared once both exist.
  a <- commandArgs(TRUE)
  col <- if (length(i <- which(a == "--col"))) a[i + 1] else "true_label"
  if (!col %in% names(v)) stop("no such column: ", col)
  if (all(is.na(v[[col]])))
    stop(col, " is empty. Code the sample first (see NEXT_STEPS.md step 2).")
  v <- v[!is.na(get(col))]
  cat("Scoring column:", col,
      if (col != "true_label") "  [NOT an independent human coding]" else "", "\n\n")
  for (mk in unique(v$marker)) {
    s <- v[marker == mk]
    tp <- s[flagged == 1 & get(col) == 1, .N]; fp <- s[flagged == 1 & get(col) == 0, .N]
    fn <- s[flagged == 0 & get(col) == 1, .N]
    cat(sprintf("%-9s n=%3d  precision=%.2f  recall(vs hard negatives)=%.2f\n",
                mk, nrow(s), tp / (tp + fp), tp / (tp + fn)))
    if (mk == "ought" && tp / (tp + fp) < 0.70)
      cat("  ** precision < .70: PREREG requires H2a be downgraded to exploratory **\n")
  }
  # Agreement between the two codings, once the human column is filled in. This is the
  # number that says whether the LLM pass was worth anything.
  if (all(c("true_label", "machine_label") %in% names(v)) &&
      !all(is.na(v$true_label)) && !all(is.na(v$machine_label))) {
    b <- v[!is.na(true_label) & !is.na(machine_label)]
    po <- mean(b$true_label == b$machine_label)
    pe <- mean(b$true_label) * mean(b$machine_label) +
          (1 - mean(b$true_label)) * (1 - mean(b$machine_label))
    cat(sprintf("\nHuman vs machine on %d rows: agreement %.3f, Cohen's kappa %.3f\n",
                nrow(b), po, (po - pe) / (1 - pe)))
  }
  quit(status = 0)
}

source("lexicons.R")

set.seed(20260726)
N_PER_CELL <- 50
CONTEXT    <- 70   # chars either side of the match

feat <- readRDS("out/features.rds")
files <- list.files("data", pattern = "\\.csv$", full.names = TRUE)

# Validate on the communities the Tier 2 claim is made about. A dictionary validated on
# r/fitness would describe a measure nobody is using.
TIER2 <- c("anxiety", "socialanxiety", "healthanxiety", "depression", "lonely", "suicidewatch")

# Re-read text for the sampled posts only. features.rds deliberately does not carry full
# text; dup_key (first 200 chars of the normalised post) is the join key back to source.
# Only the six Tier 2 communities are read — loading all 47 files to sample 200 posts meant
# a multi-minute pass over 1.2 GB every run, which made this the flakiest script here.
files <- files[grepl(paste0("^(", paste(TIER2, collapse = "|"), ")_"), basename(files))]
raw <- rbindlist(lapply(files, function(f)
  fread(f, select = c("subreddit", "post"), showProgress = FALSE)))
raw[, dup_key := stri_sub(normalise(post), 1, 200)]
raw <- raw[!duplicated(dup_key)]
d <- merge(feat[n_tok >= 25 & subreddit %in% TIER2, .(dup_key, n_ought, n_crit, subreddit)],
           raw[, .(dup_key, post)], by = "dup_key")
d[, norm := normalise(post)]
cat("Pool for sampling:", nrow(d), "posts\n")

# A "hard negative" contains the surface form but was not counted — usually because the
# subject is second-person, or because it is a discourse filler. These are precisely the
# cases the dictionary is claiming to get right, so they are where recall is won or lost.
d[, has_modal := stri_detect_regex(norm, "\\b(should|ought to|have to|need to|must|gotta)\\b")]
d[, has_critword := stri_detect_regex(norm,
    "\\b(worthless|useless|pathetic|stupid|failure|hopeless|burden|hate)\\b")]

# Pull the matched span plus context so a coder sees the evidence, not a wall of text.
span <- function(txt, pat) {
  m <- stri_locate_first_regex(txt, pat)
  ifelse(is.na(m[, 1]), "",
         stri_sub(txt, pmax(1, m[, 1] - CONTEXT), pmin(nchar(txt), m[, 2] + CONTEXT)))
}

take <- function(dt, n) dt[sample(.N, min(n, .N))]
cells <- rbindlist(list(
  take(d[n_ought > 0], N_PER_CELL)[, .(marker = "ought", flagged = 1L, dup_key, subreddit,
        evidence = span(norm, OUGHT))],
  take(d[n_ought == 0 & has_modal], N_PER_CELL)[, .(marker = "ought", flagged = 0L, dup_key,
        subreddit, evidence = span(norm, "\\b(should|ought to|have to|need to|must|gotta)\\b"))],
  take(d[n_crit > 0], N_PER_CELL)[, .(marker = "selfcrit", flagged = 1L, dup_key, subreddit,
        evidence = span(norm, SELFCRIT))],
  take(d[n_crit == 0 & has_critword], N_PER_CELL)[, .(marker = "selfcrit", flagged = 0L,
        dup_key, subreddit,
        evidence = span(norm, "\\b(worthless|useless|pathetic|stupid|failure|hopeless|burden|hate)\\b"))]
))
cells <- cells[sample(.N)]                 # shuffle so the coder cannot infer the cell
cells[, true_label := NA_integer_]         # <- the column a human fills in

fwrite(cells, "out/validation_sample.csv")
cat("Wrote out/validation_sample.csv:", nrow(cells), "rows\n\n")

cat("CODING INSTRUCTIONS (also apply to whoever codes this, including me):\n")
cat("  marker = ought    -> true_label = 1 if the writer expresses an obligation or\n")
cat("     requirement they feel bound by, about THEMSELVES. 0 if it is advice to someone\n")
cat("     else, a discourse filler ('I have to say'), a hypothetical, or a quotation.\n")
cat("  marker = selfcrit -> true_label = 1 if the writer negatively evaluates THEMSELVES\n")
cat("     as a person. 0 if they criticise a situation, another person, or their symptoms\n")
cat("     rather than their worth.\n\n")

cat("Once true_label is filled in, precision/recall come from:\n")
cat("  Rscript 05_validate.R --score\n")
