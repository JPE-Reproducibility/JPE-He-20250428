# Appendix B.2 (and the summary in Section 3.4 and the Introduction): Table 1,
# Figure 8 and the in-text numbers for the collegiate Facebook networks.
# Uses output/intermediate/facebook_orderings.csv from 05_facebook_random_orderings.R
# and the derived network data. Runtime: about 10 seconds.
source(file.path("code", "lib", "utils.R"))

data_dir <- file.path(paths$derived, "facebook100")
if (!file.exists(file.path(data_dir, "schools.csv"))) {
  stop("Run code/04_facebook_extract.py first.")
}
schools_tab <- read.csv(file.path(data_dir, "schools.csv"), stringsAsFactors = FALSE)
schools_tab <- schools_tab[order(schools_tab$school, method = "radix"), ]
schools <- schools_tab$school
stems <- setNames(schools_tab$file_stem, schools)
ord <- read.csv(file.path(paths$intermediate, "facebook_orderings.csv"), stringsAsFactors = FALSE)
n_orderings <- as.integer(config$facebook_orderings)
prov <- read.csv(file.path(paths$intermediate, "facebook_orderings_info.csv"), stringsAsFactors = FALSE)
if (prov$facebook_seed != config$facebook_seed || prov$facebook_orderings != n_orderings ||
    prov$first_year != min(config$facebook_cohorts) || prov$last_year != max(config$facebook_cohorts)) {
  stop("output/intermediate/facebook_orderings.csv was produced with other settings than config.R; ",
       "rerun code/05_facebook_random_orderings.R")
}
# the derived data must be the ones step 05 used (they are, if step 04 was run on the same zip file)
data_md5 <- unlist(lapply(schools, function(s) {
  unname(tools::md5sum(file.path(data_dir, paste0(stems[[s]], c("_students.csv", "_edges.csv")))))
}))
if (!identical(paste(data_md5, collapse = ";"), prov$data_md5)) {
  stop("the derived data in data/derived/facebook100 differ from those used for ",
       "output/intermediate/facebook_orderings.csv; rerun code/04_facebook_extract.py on the ",
       "verified data file or, if the derived data were changed on purpose, code/05_facebook_random_orderings.R")
}
# the step-05 code should be the code that produced the results; a difference (edited
# files, or converted line endings) is reported but does not stop the script
code_md5 <- unname(tools::md5sum(c(file.path(paths$lib, c("signal_counting.c", "signal_counting.R", "utils.R")),
                                   file.path("code", "05_facebook_random_orderings.R"))))
if (!identical(paste(code_md5, collapse = ";"), prov$code_md5)) {
  log_msg("Note: the step-05 code differs from the code that produced ",
          "output/intermediate/facebook_orderings.csv; rerun code/05_facebook_random_orderings.R ",
          "to recompute the results with the current code.")
}
log_msg("Using ", n_orderings, " orderings per school from step 05 (", prov$implementation, " implementation)")
# every school must have exactly the orderings 1..n_orderings set in config.R
expected <- expand.grid(ordering = seq_len(n_orderings), school = schools, stringsAsFactors = FALSE)
if (nrow(ord) != nrow(expected) || anyDuplicated(ord[, c("school", "ordering")]) ||
    nrow(merge(ord, expected)) != nrow(expected)) {
  stop("output/intermediate/facebook_orderings.csv does not contain orderings 1..", n_orderings,
       " for every school; rerun code/05_facebook_random_orderings.R")
}
# and valid values: 1 <= r_i <= i (Appendix B.1), so both measures lie in (0, 1] (up to rounding)
valid <- with(ord, is.finite(frac_potential) & frac_potential > 0 & frac_potential <= 1 + 1e-9 &
                is.finite(frac_reachable) & frac_reachable > 0 & frac_reachable <= 1 + 1e-9 &
                is.finite(n) & n == schools_tab$students_kept[match(school, schools)] &
                is.finite(n_nonempty_indirect) & n_nonempty_indirect == round(n_nonempty_indirect) &
                n_nonempty_indirect >= 1 & n_nonempty_indirect <= n & is.finite(min_pivot) & min_pivot >= 0.5)
valid[is.na(valid)] <- FALSE
if (!all(valid)) {
  stop("output/intermediate/facebook_orderings.csv contains invalid values (first on line ",
       which(!valid)[1] + 1L, " of the file); rerun code/05_facebook_random_orderings.R")
}

# ---- per-school averages over the random orderings ------------------------------
per_school <- do.call(rbind, lapply(schools, function(s) {
  x <- ord[ord$school == s, ]
  data.frame(school = s,
             frac_potential = mean(x$frac_potential), frac_reachable = mean(x$frac_reachable),
             sd_potential = sd(x$frac_potential), sd_reachable = sd(x$frac_reachable))
}))

# ---- network statistics (undirected friendship network of the kept students) -----
net <- do.call(rbind, lapply(schools, function(s) {
  st <- read.csv(file.path(data_dir, paste0(stems[[s]], "_students.csv")))
  ed <- read.csv(file.path(data_dir, paste0(stems[[s]], "_edges.csv")))
  g <- igraph::make_graph(rbind(ed$i, ed$j), n = nrow(st), directed = FALSE)
  data.frame(school = s, size = nrow(st), average_degree = 2 * nrow(ed) / nrow(st),
             C_global = igraph::transitivity(g, type = "global"),
             C_avg = igraph::transitivity(g, type = "average"))   # average over degree >= 2
}))
res <- merge(per_school, net, by = "school")
res <- res[match(schools, res$school), ]
write.csv(res, file.path(paths$tables, "facebook_results_by_school.csv"), row.names = FALSE)

# ---- Table 1 ---------------------------------------------------------------------
stats7 <- function(x) c(quantile(x, c(0, 0.25, 0.5)), mean(x), quantile(x, c(0.75, 1)), sd(x))
tab <- rbind(potential = stats7(res$frac_potential), reachable = stats7(res$frac_reachable))
colnames(tab) <- c("Min", "1st Qu.", "Median", "Mean", "3rd Qu.", "Max", "Sd.")
write.csv(round(tab, 4), file.path(paths$tables, "table1.csv"))
panel <- function(title, x) {
  c("\\begin{tabular}{|c|c|c|c|c|c|c|}", "\\hline",
    sprintf("\\multicolumn{7}{|c|}{%s}\\tabularnewline", title), "\\hline",
    "Min & 1st Qu. & Median & Mean & 3rd Qu. & Max & Sd.\\tabularnewline", "\\hline", "\\hline",
    paste0(paste(sprintf("%.4f", x), collapse = " & "), "\\tabularnewline"), "\\hline", "\\end{tabular}")
}
writeLines(c(
  sprintf("%% Table 1, generated by code/06_facebook_results.R (%d random orderings per school)", n_orderings),
  "\\begin{centering}", panel("Fraction of potential signals aggregated", tab["potential", ]),
  "\\par\\end{centering}", "\\begin{centering}",
  panel("Fraction of reachable signals aggregated", tab["reachable", ]), "\\par\\end{centering}"
), file.path(paths$tables, "table1.tex"))

# ---- Figure 8 ----------------------------------------------------------------------
fig8 <- function(file, y, main, ylab) {
  pdf(file, width = 446 / 72, height = 288 / 72)
  plot(y = y, x = res$C_global, main = main, ylab = ylab, xlab = "Global clustering coefficient")
  invisible(dev.off())
}
fig8(file.path(paths$figures, "clustering_potential_signals.pdf"), res$frac_potential,
     "Fraction of potential signals aggregated vs. global clustering",
     "Fraction of potential signals aggregated")
fig8(file.path(paths$figures, "clustering_reachable_signals.pdf"), res$frac_reachable,
     "Fraction of reachable signals aggregated vs. global clustering",
     "Fraction of reachable signals aggregated")

# ---- in-text numbers -----------------------------------------------------------------
# (implementation used in step 05: see output/intermediate/facebook_orderings_info.csv)
f2 <- function(x) sprintf("%.2f", x)
f4 <- function(x) sprintf("%.4f", x)
pct <- function(x) sprintf("%.0f%% (%.4f)", 100 * x, x)
who <- function(v, fun) paste(res$school[which(v == fun(v))], collapse = "/")
rank_desc <- function(v, s) match(s, res$school[order(-v)])
top2 <- res$school[order(-res$C_global)][1:2]
nums <- write_numbers(list(
  list("Appendix B.2", "number of networks; random orderings per network",
       sprintf("%d; %d", nrow(res), n_orderings)),
  list("Appendix B.2", "network size: min (school), max (school), mean, sd",
       sprintf("%d (%s), %d (%s), %.0f, %.0f", min(res$size), who(res$size, min), max(res$size),
               who(res$size, max), mean(res$size), sd(res$size))),
  list("Appendix B.2", "average degree: min (school), max (school), mean, sd",
       sprintf("%.0f (%s), %.0f (%s), %.0f, %.0f", min(res$average_degree), who(res$average_degree, min),
               max(res$average_degree), who(res$average_degree, max),
               mean(res$average_degree), sd(res$average_degree))),
  list("Appendix B.2", "sd across orderings as % of the mean across orderings, averaged over schools: potential, reachable (paper: on average no larger than 2%)",
       sprintf("%.2f%%, %.2f%%", 100 * mean(res$sd_potential / res$frac_potential),
               100 * mean(res$sd_reachable / res$frac_reachable))),
  list("Appendix B.2", "same, largest value over schools: potential (school), reachable (school)",
       sprintf("%.2f%% (%s), %.2f%% (%s)",
               100 * max(res$sd_potential / res$frac_potential), who(res$sd_potential / res$frac_potential, max),
               100 * max(res$sd_reachable / res$frac_reachable), who(res$sd_reachable / res$frac_reachable, max))),
  list("Table 1", "fraction of potential signals aggregated: Min, 1st Qu., Median, Mean, 3rd Qu., Max, Sd.",
       paste(f4(tab["potential", ]), collapse = ", ")),
  list("Table 1", "fraction of reachable signals aggregated: Min, 1st Qu., Median, Mean, 3rd Qu., Max, Sd.",
       paste(f4(tab["reachable", ]), collapse = ", ")),
  list("Section 3.4", "fraction of signals aggregated ranges from ... to ... across campuses",
       paste(pct(min(res$frac_potential)), "to", pct(max(res$frac_potential)))),
  list("Introduction", "losses ranging from ... to ... of available signals",
       paste(pct(1 - max(res$frac_potential)), "to", pct(1 - min(res$frac_potential)))),
  list("Appendix B.2", "average share of potential signals lost (paper: more than half)", pct(1 - mean(res$frac_potential))),
  list("Appendix B.2", "average loss of reachable signals due to confounding (paper: 30%)", pct(1 - mean(res$frac_reachable))),
  list("Appendix B.2 / Figure 8", "correlation of global clustering with fraction of potential signals aggregated",
       f2(cor(res$C_global, res$frac_potential))),
  list("Appendix B.2 / Figure 8", "correlation of global clustering with fraction of reachable signals aggregated",
       f2(cor(res$C_global, res$frac_reachable))),
  list("Footnote 22", "correlations using average local clustering instead: potential, reachable",
       paste(f2(cor(res$C_avg, res$frac_potential)), f2(cor(res$C_avg, res$frac_reachable)), sep = ", ")),
  list("Appendix B.2", "two schools with the highest global clustering, and their ranks (out of 100) in the potential and reachable measures",
       paste(sprintf("%s (clustering %.3f; ranks %d and %d)", top2, res$C_global[match(top2, res$school)],
                     rank_desc(res$frac_potential, top2), rank_desc(res$frac_reachable, top2)), collapse = "; "))
), "facebook_numbers.csv")
print(nums, right = FALSE)
log_msg("Table 1, Figure 8 and in-text numbers written")
