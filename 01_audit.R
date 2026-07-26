#!/usr/bin/env Rscript
# Step 0: go/no-go on the Reddit Mental Health Dataset (Low et al., 2020; Zenodo 3941387).
#
# The Zenodo landing page advertises "{subreddit}_{timeframe}_features_tfidf_256.csv"
# and never documents the columns. Two of them are load-bearing for this project:
#   post   -> absent means every Tier 2 feature is impossible. TF-IDF columns cannot be
#             reverse-engineered back into pronoun rates. Project dead.
#   author -> absent means Tier 3 (within-person over time) is dead. Tiers 1/2/4 survive
#             as a between-post design.
# So we check before writing a single feature.
#
#   Rscript 01_audit.R

suppressMessages(library(data.table))

dir <- "data"
files <- list.files(dir, pattern = "\\.csv$", full.names = TRUE)
if (!length(files)) stop("No CSVs in data/. See README for the download step.")

f <- files[which.min(file.size(files))]  # cheapest file for a structural check
cat("Auditing:", basename(f), sprintf("(%.1f MB)\n\n", file.size(f) / 1e6))

hdr <- names(fread(f, nrows = 0))
cat("Total columns:", length(hdr), "\n")
cat("First 25:", paste(head(hdr, 25), collapse = ", "), "\n\n")

has <- function(x) x %in% hdr
cat("HAS_TEXT   =", has("post"), "\n")
cat("HAS_AUTHOR =", has("author"), "\n")
cat("HAS_DATE   =", has("date"), "\n")
cat("HAS_NWORDS =", has("n_words"), "\n\n")

if (!has("post")) stop("No `post` column. Stop here: the project cannot be built on this release.")

# Only ever read the columns we use. 231 columns x ~1M rows would be pointless I/O.
keep <- intersect(c("subreddit", "author", "date", "post", "n_words", "liwc_1st_pers"), hdr)
d <- fread(f, select = keep, showProgress = FALSE)
cat("Rows:", nrow(d), "| kept columns:", paste(keep, collapse = ", "), "\n\n")

str(d, give.attr = FALSE)
cat("\n")

# Structural facts that decide the Tier 1 guardrails, not just nice-to-know.
if (has("author")) {
  a <- d[, .N, by = author][order(-N)]
  cat("Unique authors:", nrow(a), "\n")
  cat("Top author share of posts:", sprintf("%.2f%%\n", 100 * a$N[1] / nrow(d)))
  cat("Posts by [deleted]/[removed] authors:",
      sum(d$author %in% c("[deleted]", "[removed]")), "\n")
}
if (has("date")) cat("Date range:", as.character(min(d$date)), "to", as.character(max(d$date)), "\n")
cat("Exact-duplicate post bodies:", sum(duplicated(d$post)), "\n")
cat("Posts with <25 words:", sum(d$n_words < 25, na.rm = TRUE), "\n\n")

# Redacted sample: first 120 chars only. Full post text never gets printed or committed.
cat("Sample post (truncated):\n  ", substr(d$post[which(d$n_words > 40)[1]], 1, 120), "...\n\n")

cat("VERDICT: Tier 1/2/4 GO.", if (has("author") && has("date")) "Tier 3 GO." else "Tier 3 BLOCKED.", "\n")
