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

# Patterns live in lexicons.R so the test suite and this pipeline share one definition.
source("lexicons.R")

files <- list.files("data", pattern = "\\.csv$", full.names = TRUE)
if (!length(files)) stop("No CSVs in data/. See README.")

feat <- rbindlist(lapply(files, function(f) {
  base <- sub("\\.csv$", "", basename(f))
  win  <- sub("^.*_", "", base)
  d <- fread(f, select = c("subreddit", "author", "date", "post", "n_words"),
             showProgress = FALSE)
  p <- normalise(d$post)   # shared with the validation sampler, so precision describes this
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
    # Tier 2. Ought is net of fillers: a filler match is also an OUGHT match by
    # construction, so it is subtracted rather than counted separately.
    n_ought   = stri_count_regex(p, OUGHT) - stri_count_regex(p, OUGHT_FILLER),
    n_advice  = stri_count_regex(p, ADVICE),
    n_ideal   = stri_count_regex(p, IDEAL),
    n_crit    = stri_count_regex(p, SELFCRIT),
    n_2nd     = stri_count_regex(p, PRON_2ND),
    n_3rd     = stri_count_regex(p, PRON_3RD),
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

stopifnot(feat$n_ought >= 0)  # fillers are a strict subset of OUGHT; negatives = bad regex

for (v in c("1sg", "ought", "advice", "ideal", "crit", "2nd", "3rd"))
  set(feat, j = paste0("rate_", v), value = feat[[paste0("n_", v)]] / feat$n_tok)

cat("\nMarker base rates (per token) and share of posts with >=1 hit:\n")
print(data.table(marker = c("ought", "advice", "ideal", "crit"),
                 mean_rate = round(c(mean(feat$rate_ought), mean(feat$rate_advice),
                                     mean(feat$rate_ideal), mean(feat$rate_crit)), 5),
                 pct_posts_with_hit = round(100 * c(mean(feat$n_ought > 0),
                   mean(feat$n_advice > 0), mean(feat$n_ideal > 0),
                   mean(feat$n_crit > 0)), 1)))

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
