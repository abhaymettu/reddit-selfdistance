#!/usr/bin/env Rscript
# Text -> per-post feature table. The only expensive pass over the corpus; every tier
# reads its output, nothing re-parses the text.
#
#   Rscript 02_features.R
#
# NOTE ON THE BUNDLED LIWC COLUMNS: the release ships liwc_1st_pers / liwc_2nd_pers /
# liwc_3rd_pers, which look like they would do this job for free. They do not. On a
# r/depression post containing four unambiguous first-person singular pronouns,
# liwc_1st_pers reads 0, and its corpus mean is 0.47 per post against a median post
# length of 140 words. Whatever that column counts, it is not first-person singular
# pronoun use. We compute our own and keep the audit trail.

suppressMessages({library(data.table); library(stringi)})

# stringi over a lowercased copy. No tokenizer, no NLP dependency.
# Written to a file rather than passed via `Rscript -e`: backslash escapes in these
# patterns do not survive the shell reliably, and they fail *silently* by matching
# nothing, which looks exactly like a real null result. Cost me a debugging cycle.
PRON_1SG <- "\\b(i|me|my|mine|myself|i'm|i've|i'll|i'd)\\b"
TOKEN    <- "[a-z0-9']+"

files <- list.files("data", pattern = "\\.csv$", full.names = TRUE)
if (!length(files)) stop("No CSVs in data/. See README.")

feat <- rbindlist(lapply(files, function(f) {
  base <- sub("\\.csv$", "", basename(f))
  win  <- sub("^.*_", "", base)
  d <- fread(f, select = c("subreddit", "author", "date", "post", "n_words"),
             showProgress = FALSE)
  p <- stri_trans_tolower(d$post)
  p <- stri_replace_all_regex(p, "https?://\\S+|www\\.\\S+", " ")  # URLs are not language
  p <- stri_replace_all_regex(p, "&amp;#x200b;|&amp;|&gt;|&lt;", " ")  # reddit html entities
  data.table(
    subreddit = d$subreddit,
    author    = d$author,
    date      = as.IDate(d$date, format = "%Y/%m/%d"),
    window    = win,
    # Our own denominator: numerator and denominator must come from the same tokenizer,
    # otherwise the rate is a ratio of two different definitions of "word".
    n_tok     = stri_count_regex(p, TOKEN),
    n_words_ds = d$n_words,          # dataset's textacy count, kept only to cross-check
    n_1sg     = stri_count_regex(p, PRON_1SG),
    dup_key   = stri_sub(p, 1, 200)  # for dedup; full text never leaves this script
  )
}))

cat("Posts read:", nrow(feat), "across", uniqueN(feat$subreddit), "subreddits\n")

# Cross-check our tokenizer against the dataset's. These measure slightly different
# things (ours keeps contractions whole) so exact equality is not expected, but a
# correlation below ~.98 would mean one of them is broken.
ok <- feat[n_tok > 0 & n_words_ds > 0]
cat("Token count agreement with dataset n_words: r =",
    sprintf("%.4f\n", cor(ok$n_tok, ok$n_words_ds)))

feat[, rate_1sg := n_1sg / n_tok]

saveRDS(feat, "out/features.rds")
cat("Wrote out/features.rds\n")

# --- Hand-checkable spot check -------------------------------------------------------
# Ten posts printed with their counts so a reader can verify the counter by eye rather
# than trusting it. This is the cheapest possible defense of a dictionary method.
set.seed(1)
d <- fread(files[which.min(file.size(files))],
           select = c("post", "n_words"), showProgress = FALSE)
i <- sample(which(d$n_words > 30 & d$n_words < 60), 10)
cat("\n--- spot check (verify these by hand) ---\n")
for (k in i) {
  p <- stri_trans_tolower(d$post[k])
  m <- stri_extract_all_regex(p, PRON_1SG)[[1]]
  cat(sprintf("n_1sg=%2d  tok=%3d  matched: %s\n",
              length(m[!is.na(m)]), stri_count_regex(p, TOKEN),
              paste(m[!is.na(m)], collapse = " ")))
}
