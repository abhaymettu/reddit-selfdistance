#!/usr/bin/env Rscript
# Fetch the subset of the Reddit Mental Health Dataset this project uses.
#
#   Rscript 00_download.R
#
# The Zenodo record holds 108 files (~5 GB). This pulls the 47 needed here (~1.2 GB):
# 16 subreddits x 3 time windows. Skips anything already downloaded, so it is safe to
# re-run after an interrupted transfer.
#
# Data: Low DM, Rumker L, Talkar T, Torous J, Cecchi G, Ghosh SS. Natural Language
# Processing Reveals Vulnerable Mental Health Support Groups and Heightened Health Anxiety
# on Reddit During COVID-19. J Med Internet Res 2020;22(10):e22635. Public domain (CC0).

RECORD <- "https://zenodo.org/api/records/3941387"

# The three arms of the analysis. Tier 1 needs the topical controls; the genre-matched
# contrast and all of Tier 2 need the other mental-health subreddits.
DEPRESSION <- c("depression", "lonely", "suicidewatch")
AGITATION  <- c("anxiety", "socialanxiety", "healthanxiety")
OTHER_MH   <- c("adhd", "autism", "ptsd", "bipolarreddit", "bpd", "EDAnonymous")
TOPICAL    <- c("fitness", "jokes", "personalfinance", "teaching")
WINDOWS    <- c("2018", "2019", "post")

want <- c(DEPRESSION, AGITATION, OTHER_MH, TOPICAL)
dir.create("data", showWarnings = FALSE)
dir.create("out",  showWarnings = FALSE)

# jsonlite is the only dependency here and is not needed by any other script, so it is
# installed on demand rather than declared as a project requirement.
if (!requireNamespace("jsonlite", quietly = TRUE))
  install.packages("jsonlite", repos = "https://cloud.r-project.org", quiet = TRUE)

cat("Reading the Zenodo record...\n")
rec <- jsonlite::fromJSON(RECORD, simplifyVector = FALSE)

todo <- list()
for (f in rec$files) {
  base <- sub("_features_tfidf_256\\.csv$", "", f$key)
  for (w in WINDOWS) {
    if (grepl(paste0("_", w, "$"), base) && sub(paste0("_", w, "$"), "", base) %in% want)
      todo[[length(todo) + 1]] <- list(url = f$links$self,
                                       dest = file.path("data", paste0(base, ".csv")),
                                       mb = f$size / 1e6)
  }
}
cat("Matched", length(todo), "files,",
    sprintf("%.0f MB total\n", sum(vapply(todo, function(x) x$mb, 0))))

for (i in seq_along(todo)) {
  t <- todo[[i]]
  if (file.exists(t$dest) && file.size(t$dest) > 0) {
    cat(sprintf("[%2d/%d] have   %s\n", i, length(todo), basename(t$dest)))
    next
  }
  cat(sprintf("[%2d/%d] get    %s (%.0f MB)\n", i, length(todo), basename(t$dest), t$mb))
  # A partial file left by an interrupted download would silently truncate the corpus, so
  # write to a temp name and only move it into place once curl reports success.
  tmp <- paste0(t$dest, ".part")
  ok <- tryCatch({ download.file(t$url, tmp, mode = "wb", quiet = TRUE); TRUE },
                 error = function(e) { message("  failed: ", conditionMessage(e)); FALSE })
  if (ok && file.size(tmp) > 0) file.rename(tmp, t$dest) else unlink(tmp)
}

got <- list.files("data", pattern = "\\.csv$")
cat("\ndata/ now holds", length(got), "of", length(todo), "files.\n")
# Braces are load-bearing: at top level R parses `if (...) expr` as complete and then
# chokes on a bare `else` on the next line.
if (length(got) < length(todo)) {
  cat("Some downloads failed. Re-run this script; it skips what is already present.\n")
} else {
  cat("Next: Rscript 01_audit.R\n")
}
