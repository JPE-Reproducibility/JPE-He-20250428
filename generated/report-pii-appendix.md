## Appendix: Detailed PII Detection Results

*Generated on 2026-11-12 19:21:13*

This appendix lists all detected instances of potential personally identifiable information (PII) in the project files. Each entry shows the matched PII terms and, for data files, sample values to help verify whether the flagged content is indeed sensitive.

### Full Summary Table

| File Type | File | Variables/References | PII Categories |
|-----------|------|----------------------|----------------|
| Data | `facebook_numbers.csv` | 1 | loc, location |
| Data | `facebook_orderings.csv` | 1 | school |
| Data | `facebook_results_by_school.csv` | 2 | school, degree |
| Data | `figure4_numbers.csv` | 1 | loc, location |
| Data | `figure5_numbers.csv` | 1 | loc, location |
| Code | `01_figure4_maximal_generations.R` | 5 | network, lat, second, lname, name |
| Code | `02_figure7_utility_vs_signals.py` | 3 | zip, loc, name |
| Code | `03_figure5_random_regular.R` | 18 | network, minute, lat, degree, lon, name |
| Code | `04_facebook_extract.py` | 35 | zip, name, school, loc, lat |
| Code | `05_facebook_random_orderings.R` | 55 | social, network, school, name, block, loc, second, lon, minute |
| Code | `06_facebook_results.R` | 44 | network, second, school, name, zip, degree, lname, lat |
| Code | `config.R` | 8 | name, lat, school, lon, network |
| Code | `generations.R` | 4 | network |
| Code | `run_all.R` | 20 | zip, name, minute |
| Code | `signal_counting.R` | 31 | network, lat, name, son, second |
| Code | `signal_counting.c` | 16 | network, lat, sex, loc |
| Code | `table1.tex` | 1 | school |
| Code | `test_signal_counting.R` | 16 | name, network, lat |
| Code | `utils.R` | 10 | loc, location, name, lat, lon, minute |

### Data Files

**/replication-package/replication_package/output/intermediate/facebook_orderings.csv**

- Variable: `school`
  - Matched terms: school
  - Sample values: American75

**/replication-package/replication_package/reference_output/numbers/facebook_numbers.csv**

- Variable: `location`
  - Matched terms: loc, location
  - Sample values: Appendix B.2, Table 1, Section 3.4

**/replication-package/replication_package/reference_output/numbers/figure4_numbers.csv**

- Variable: `location`
  - Matched terms: loc, location
  - Sample values: Section 4.1 (text before Figure 4), Corollary 1 (check)

**/replication-package/replication_package/reference_output/numbers/figure5_numbers.csv**

- Variable: `location`
  - Matched terms: loc, location
  - Sample values: Section 4.3, Section 4.3 (Figure 5a text), Section 4.3 (Figure 5b text)

**/replication-package/replication_package/reference_output/tables/facebook_results_by_school.csv**

- Variable: `average_degree`
  - Matched terms: degree
  - Sample values: 64.9235697940503, 73.9512525389303, 83.1692334770747
- Variable: `school`
  - Matched terms: school
  - Sample values: American75, Amherst41, Auburn71

### Code Files

**/replication-package/replication_package/code/01_figure4_maximal_generations.R**

- Line 2: network
  ```
  # maximal generations networks with generation sizes K = 2, 3, 4, 5, and the
  ```
- Line 3: lat
  ```
  # in-text claim that r_i is strictly decreasing in K for all later agents
  ```
- Line 5: second
  ```
  # Deterministic; runs in about a second.
  ```
- Line 14: lname, name
  ```
  colnames(r) <- paste0("K", Ks)
  ```
- Line 16: name
  ```
  file.path(paths$intermediate, "figure4_ri.csv"), row.names = FALSE)
  ```

**/replication-package/replication_package/code/02_figure7_utility_vs_signals.py**

- Line 67: zip
  ```
  for s2, (ls, color) in zip(SIGMA2, STYLES):
  ```
- Line 76: loc
  ```
  ax.legend(fontsize=15, loc="lower right")
  ```
- Line 82: name
  ```
  if __name__ == "__main__":
  ```

**/replication-package/replication_package/code/03_figure5_random_regular.R**

- Line 2: network
  ```
  # generations networks with K = 100 positions. In each of 1000 replications,
  ```
- Line 10: minute
  ```
  # Runtime: about 2.5 minutes with 8 workers (the 8 configurations run in
  ```
- Line 26: lat
  ```
  simulate_pair <- function(k) {
  ```
- Line 38: degree, lat
  ```
  log_msg("Simulating ", length(all_pairs), " degree configurations x ", reps,
  ```
- Line 41: lat, lon
  ```
  gains <- run_jobs(seq_along(all_pairs), simulate_pair, n_cores = config$n_cores)
  ```
- Line 42: minute
  ```
  log_msg(sprintf("Done in %.1f minutes", (proc.time()[["elapsed"]] - t0) / 60))
  ```
- Line 43: name
  ```
  names(gains) <- vapply(all_pairs, function(d) sprintf("d1=%d,d2=%d", d[1], d[2]), "")
  ```
- Line 52: lon
  ```
  write.csv(do.call(rbind, lapply(seq_along(summ), function(i) {
  ```
- Line 53: name
  ```
  data.frame(configuration = names(summ)[i], generation = summ[[i]]$t,
  ```
- Line 55: name
  ```
  })), file.path(paths$intermediate, "figure5_summary.csv"), row.names = FALSE)
  ```
- Line 71: lon
  ```
  for (i in seq_along(S_list)) {
  ```
- Line 82: network
  ```
  main = expression("Signal Aggregation in Random " * italic(d) * "-Regular Networks"),
  ```
- Line 85: degree, network
  ```
  main = expression("Signal Aggregation in Random Networks with Degrees (" * d[1] * ", " * d[2] * ")")
  ```
- Line 92: lat
  ```
  # panel, no position gains more than 2 signals in any simulated generation
  ```
- Line 109: name
  ```
  list("Section 4.3", "same, by configuration", paste(sprintf("%s: %s", names(summ), sapply(summ, func
  ```
- Line 110: lat
  ```
  list("Section 4.3", "range of the largest one-generation gain over all replications, generations 50-
  ```
- Line 111: lat
  ```
  list("Section 4.3", "range of the largest one-generation gain over all replications, generations 50-
  ```
- Line 115: name
  ```
  paste(sprintf("%s: t=%d", names(summ), sapply(summ, function(S) S$t[which.max(S$mean)])), collapse =
  ```

**/replication-package/replication_package/code/04_facebook_extract.py**

- Line 4: zip
  ```
  Input:  data/raw/facebook100.zip, as distributed at
  ```
- Line 6: name, school
  ```
  Output, in data/derived/facebook100/ (file names use the school name with
  ```
- Line 8: school
  ```
  <school>_students.csv   columns: student, class_year
  ```
- Line 9: school
  ```
  <school>_edges.csv      columns: i, j  (friendships, i < j)
  ```
- Line 10: school
  ```
  schools.csv             one row per school
  ```
- Line 13: school
  ```
  Each school's .mat file holds a sparse symmetric adjacency matrix A (Facebook
  ```
- Line 14: loc, school
  ```
  friendships within the school) and a matrix local_info with one row per user;
  ```
- Line 53: school
  ```
  return school.replace(" ", "_")
  ```
- Line 63: zip
  ```
  zip_path = ROOT / "data" / "raw" / "facebook100.zip"
  ```
- Line 65: zip
  ```
  if not zip_path.exists():
  ```
- Line 66: zip
  ```
  raise SystemExit(f"{zip_path} not found. Download facebook100.zip as described in README.txt.")
  ```
- Line 68: zip
  ```
  found = checksums(zip_path)
  ```
- Line 70: zip
  ```
  raise SystemExit(f"{zip_path} does not match the expected file:\n  expected {EXPECTED}\n  found    {
  ```
- Line 71: zip
  ```
  print(f"facebook100.zip verified (MD5 {found['md5']})")
  ```
- Line 75: name
  ```
  tmp_dir = out_dir.with_name(out_dir.name + ".tmp")
  ```
- Line 79: zip
  ```
  with zipfile.ZipFile(zip_path) as zf:
  ```
- Line 80: name
  ```
  members = sorted(n for n in zf.namelist()
  ```
- Line 82: school
  ```
  and not n.endswith("/schools.mat"))
  ```
- Line 84: school
  ```
  raise SystemExit(f"expected 100 school files, found {len(members)}")
  ```
- Line 85: name
  ```
  for name in members:
  ```
- Line 86: name, school
  ```
  school = name[len("facebook100/"):-len(".mat")]
  ```
- Line 87: school
  ```
  stem = file_stem(school)
  ```
- Line 90: name
  ```
  mat = scipy.io.loadmat(io.BytesIO(zf.read(name)))
  ```
- Line 92: loc
  ```
  info = np.asarray(mat["local_info"])
  ```
- Line 94: school
  ```
  raise SystemExit(f"{school}: inconsistent dimensions")
  ```
- Line 96: school
  ```
  raise SystemExit(f"{school}: adjacency matrix is not symmetric")
  ```
- Line 98: lat
  ```
  keep = np.flatnonzero((status == 1) & (year >= first_year) & (year <= last_year))
  ```
- Line 108: zip
  ```
  w.writerows(zip(range(1, len(keep) + 1), years.tolist()))
  ```
- Line 114: school
  ```
  rows.append([school, stem, A.shape[0], len(keep), len(edges)] + counts)
  ```
- Line 117: name, school
  ```
  raise SystemExit("two schools map to the same file name")
  ```
- Line 118: school
  ```
  with open(tmp_dir / "schools.csv", "w", newline="", encoding="utf-8") as f:
  ```
- Line 120: school
  ```
  w.writerow(["school", "file_stem", "users_in_raw_data", "students_kept", "friendships_kept"]
  ```
- Line 125: school, zip
  ```
  w.writerow(["first_year", "last_year", "zip_md5", "schools"])
  ```
- Line 128: name
  ```
  tmp_dir.rename(out_dir)
  ```
- Line 132: name
  ```
  if __name__ == "__main__":
  ```

**/replication-package/replication_package/code/05_facebook_random_orderings.R**

- Line 1: social
  ```
  # Appendix B.2: rational sequential social learning on the 100 collegiate
  ```
- Line 2: network
  ```
  # Facebook networks, with the students moving in random orders.
  ```
- Line 4: school
  ```
  # For each school and each of config$facebook_orderings random orderings, a
  ```
- Line 12: school
  ```
  # Orderings are drawn with L'Ecuyer-CMRG streams: the school with Facebook
  ```
- Line 13: name
  ```
  # number s (the number at the end of its name, 1-100) uses stream s, and its
  ```
- Line 15: school
  ```
  # number of cores or on which schools are run, and raising the number of
  ```
- Line 16: school
  ```
  # orderings keeps the earlier ones. Each parallel job handles one school and a
  ```
- Line 17: block, loc
  ```
  # block of up to `block_size` consecutive orderings (this affects only
  ```
- Line 18: block, loc
  ```
  # scheduling, not results). Each block's results are saved in
  ```
- Line 26: block, loc
  ```
  block_size <- 50L
  ```
- Line 42: school
  ```
  schools_tab <- read.csv(file.path(data_dir, "schools.csv"), stringsAsFactors = FALSE)
  ```
- Line 43: school
  ```
  schools_tab <- schools_tab[order(schools_tab$school, method = "radix"), ]
  ```
- Line 44: school
  ```
  schools <- schools_tab$school
  ```
- Line 45: name, school
  ```
  stems <- setNames(schools_tab$file_stem, schools)
  ```
- Line 46: name, school
  ```
  school_number <- setNames(as.integer(regmatches(schools, regexpr("[0-9]+$", schools))), schools)
  ```
- Line 47: school
  ```
  if (anyNA(school_number) || anyDuplicated(school_number)) stop("could not parse unique school number
  ```
- Line 52: school
  ```
  school_files <- function(s) file.path(data_dir, paste0(stems[[s]], c("_students.csv", "_edges.csv"))
  ```
- Line 53: school
  ```
  read_school <- function(s) {
  ```
- Line 54: school
  ```
  f <- school_files(s)
  ```
- Line 62: school
  ```
  log_msg("Reading ", length(schools), " schools")
  ```
- Line 63: name, school
  ```
  school_data <- setNames(lapply(schools, read_school), schools)
  ```
- Line 67: name
  ```
  code_md5 <- unname(tools::md5sum(c(file.path(paths$lib, c("signal_counting.c", "signal_counting.R", 
  ```
- Line 69: school
  ```
  streams <- rng_streams(config$facebook_seed, max(school_number), n_orderings)
  ```
- Line 71: block, loc, school
  ```
  # one job per school and block of consecutive orderings
  ```
- Line 73: school
  ```
  for (s in schools) {
  ```
- Line 74: block, loc
  ```
  for (first in seq(1L, n_orderings, by = block_size)) {
  ```
- Line 75: block, loc
  ```
  ords <- first:min(first + block_size - 1L, n_orderings)
  ```
- Line 76: school
  ```
  jobs[[length(jobs) + 1]] <- list(school = s, orderings = ords,
  ```
- Line 77: school
  ```
  rng = streams[[school_number[[s]]]][ords])
  ```
- Line 80: school
  ```
  n_job <- vapply(jobs, function(j) school_data[[j$school]]$n, 0)
  ```
- Line 86: block, loc
  ```
  block_file <- function(job) {
  ```
- Line 87: school
  ```
  file.path(out_dir, sprintf("%s__orderings%04d-%04d.rds", stems[[job$school]],
  ```
- Line 91: school
  ```
  one_ordering <- function(x, state, ordering, school) {
  ```
- Line 101: school
  ```
  school = school, ordering = ordering, n = x$n,
  ```
- Line 106: second
  ```
  seconds = proc.time()[["elapsed"]] - t0,
  ```
- Line 111: block, loc
  ```
  run_block <- function(job) {
  ```
- Line 112: block, loc
  ```
  f <- block_file(job)
  ```
- Line 113: school
  ```
  x <- school_data[[job$school]]
  ```
- Line 121: lon
  ```
  for (j in seq_along(job$orderings)) {
  ```
- Line 122: school
  ```
  rows[[j]] <- one_ordering(x, job$rng[[j]], job$orderings[j], job$school)
  ```
- Line 128: name
  ```
  if (!file.rename(tmp, f)) {          # renaming onto an existing file can fail on Windows
  ```
- Line 130: name
  ```
  if (!file.rename(tmp, f)) stop("could not write ", f)
  ```
- Line 136: school
  ```
  log_msg(sprintf("%d schools x %d orderings in %d jobs of up to %d orderings, on %d core(s), memory b
  ```
- Line 137: block, loc, school
  ```
  length(schools), n_orderings, length(jobs), block_size, effective_cores(), budget, implementation))
  ```
- Line 139: lon, school
  ```
  log_msg(sprintf("note: the largest school needs about %.1f GB and will run alone", max(mem_gb)))
  ```
- Line 142: block, loc
  ```
  res <- do.call(rbind, run_jobs(jobs, run_block, n_cores = config$n_cores, mem_gb = mem_gb,
  ```
- Line 144: school
  ```
  res <- res[order(match(res$school, schools), res$ordering), ]
  ```
- Line 145: name, second
  ```
  write.csv(res[, setdiff(names(res), c("seconds", "cached"))],
  ```
- Line 146: name
  ```
  file.path(paths$intermediate, "facebook_orderings.csv"), row.names = FALSE)
  ```
- Line 147: school, second
  ```
  write.csv(res[, c("school", "ordering", "n", "seconds", "cached")],
  ```
- Line 148: name
  ```
  file.path(paths$logs, "facebook_job_times.csv"), row.names = FALSE)
  ```
- Line 153: school
  ```
  data_md5 = paste(unlist(lapply(school_data, `[[`, "md5")), collapse = ";")),
  ```
- Line 154: name
  ```
  file.path(paths$intermediate, "facebook_orderings_info.csv"), row.names = FALSE)
  ```
- Line 156: minute
  ```
  log_msg(sprintf("Done in %.1f minutes: %d orderings computed (sum of their times %.1f minutes), %d r
  ```
- Line 157: second
  ```
  (proc.time()[["elapsed"]] - t0) / 60, sum(computed), sum(res$seconds[computed]) / 60,
  ```

**/replication-package/replication_package/code/06_facebook_results.R**

- Line 2: network
  ```
  # Figure 8 and the in-text numbers for the collegiate Facebook networks.
  ```
- Line 4: network, second
  ```
  # and the derived network data. Runtime: about 10 seconds.
  ```
- Line 8: school
  ```
  if (!file.exists(file.path(data_dir, "schools.csv"))) {
  ```
- Line 11: school
  ```
  schools_tab <- read.csv(file.path(data_dir, "schools.csv"), stringsAsFactors = FALSE)
  ```
- Line 12: school
  ```
  schools_tab <- schools_tab[order(schools_tab$school, method = "radix"), ]
  ```
- Line 13: school
  ```
  schools <- schools_tab$school
  ```
- Line 14: name, school
  ```
  stems <- setNames(schools_tab$file_stem, schools)
  ```
- Line 23: zip
  ```
  # the derived data must be the ones step 05 used (they are, if step 04 was run on the same zip file)
  ```
- Line 24: school
  ```
  data_md5 <- unlist(lapply(schools, function(s) {
  ```
- Line 25: name
  ```
  unname(tools::md5sum(file.path(data_dir, paste0(stems[[s]], c("_students.csv", "_edges.csv")))))
  ```
- Line 34: name
  ```
  code_md5 <- unname(tools::md5sum(c(file.path(paths$lib, c("signal_counting.c", "signal_counting.R", 
  ```
- Line 42: school
  ```
  # every school must have exactly the orderings 1..n_orderings set in config.R
  ```
- Line 43: school
  ```
  expected <- expand.grid(ordering = seq_len(n_orderings), school = schools, stringsAsFactors = FALSE)
  ```
- Line 44: school
  ```
  if (nrow(ord) != nrow(expected) || anyDuplicated(ord[, c("school", "ordering")]) ||
  ```
- Line 47: school
  ```
  " for every school; rerun code/05_facebook_random_orderings.R")
  ```
- Line 52: school
  ```
  is.finite(n) & n == schools_tab$students_kept[match(school, schools)] &
  ```
- Line 61: school
  ```
  # ---- per-school averages over the random orderings ------------------------------
  ```
- Line 62: school
  ```
  per_school <- do.call(rbind, lapply(schools, function(s) {
  ```
- Line 63: school
  ```
  x <- ord[ord$school == s, ]
  ```
- Line 64: school
  ```
  data.frame(school = s,
  ```
- Line 69: network
  ```
  # ---- network statistics (undirected friendship network of the kept students) -----
  ```
- Line 70: school
  ```
  net <- do.call(rbind, lapply(schools, function(s) {
  ```
- Line 74: degree, school
  ```
  data.frame(school = s, size = nrow(st), average_degree = 2 * nrow(ed) / nrow(st),
  ```
- Line 76: degree
  ```
  C_avg = igraph::transitivity(g, type = "average"))   # average over degree >= 2
  ```
- Line 78: school
  ```
  res <- merge(per_school, net, by = "school")
  ```
- Line 79: school
  ```
  res <- res[match(schools, res$school), ]
  ```
- Line 80: name, school
  ```
  write.csv(res, file.path(paths$tables, "facebook_results_by_school.csv"), row.names = FALSE)
  ```
- Line 85: lname, name
  ```
  colnames(tab) <- c("Min", "1st Qu.", "Median", "Mean", "3rd Qu.", "Max", "Sd.")
  ```
- Line 94: school
  ```
  sprintf("%% Table 1, generated by code/06_facebook_results.R (%d random orderings per school)", n_or
  ```
- Line 118: school
  ```
  who <- function(v, fun) paste(res$school[which(v == fun(v))], collapse = "/")
  ```
- Line 119: school
  ```
  rank_desc <- function(v, s) match(s, res$school[order(-v)])
  ```
- Line 120: school
  ```
  top2 <- res$school[order(-res$C_global)][1:2]
  ```
- Line 122: network
  ```
  list("Appendix B.2", "number of networks; random orderings per network",
  ```
- Line 124: network, school
  ```
  list("Appendix B.2", "network size: min (school), max (school), mean, sd",
  ```
- Line 127: degree, school
  ```
  list("Appendix B.2", "average degree: min (school), max (school), mean, sd",
  ```
- Line 128: degree
  ```
  sprintf("%.0f (%s), %.0f (%s), %.0f, %.0f", min(res$average_degree), who(res$average_degree, min),
  ```
- Line 129: degree
  ```
  max(res$average_degree), who(res$average_degree, max),
  ```
- Line 130: degree
  ```
  mean(res$average_degree), sd(res$average_degree))),
  ```
- Line 131: school
  ```
  list("Appendix B.2", "sd across orderings as % of the mean across orderings, averaged over schools: 
  ```
- Line 134: school
  ```
  list("Appendix B.2", "same, largest value over schools: potential (school), reachable (school)",
  ```
- Line 148: lat
  ```
  list("Appendix B.2 / Figure 8", "correlation of global clustering with fraction of potential signals
  ```
- Line 150: lat
  ```
  list("Appendix B.2 / Figure 8", "correlation of global clustering with fraction of reachable signals
  ```
- Line 154: school
  ```
  list("Appendix B.2", "two schools with the highest global clustering, and their ranks (out of 100) i
  ```
- Line 155: school
  ```
  paste(sprintf("%s (clustering %.3f; ranks %d and %d)", top2, res$C_global[match(top2, res$school)],
  ```

**/replication-package/replication_package/code/lib/generations.R**

- Line 1: network
  ```
  # Signal counts in generations networks (Section 4 of the paper).
  ```
- Line 6: network
  ```
  # ---- maximal generations network (Figure 4) ---------------------------------
  ```
- Line 31: network
  ```
  # ---- generations networks with fixed observation sets (Figure 5) ------------
  ```
- Line 72: network
  ```
  # The same generations network written out agent by agent (agent (t-1)K + k),
  ```

**/replication-package/replication_package/code/lib/signal_counting.R**

- Line 1: network
  ```
  # Signal counting in arbitrary finite networks (Appendix B of the paper).
  ```
- Line 13: network
  ```
  #     is available (much slower for the largest networks).
  ```
- Line 22: network
  ```
  # ---- observation network ---------------------------------------------------
  ```
- Line 24: network
  ```
  # Observation network induced by an ordering of an undirected network.
  ```
- Line 28: network
  ```
  # Returns the network in CSR form on positions: for p = 1..n, position p
  ```
- Line 43: lat
  ```
  later <- pmax(a, b)
  ```
- Line 45: lat
  ```
  keep <- later != earlier
  ```
- Line 46: lat
  ```
  later <- later[keep]
  ```
- Line 48: lat
  ```
  dup <- duplicated((as.double(later) - 1) * n + earlier)  # exact while n^2 < 2^53
  ```
- Line 49: lat
  ```
  later <- later[!dup]
  ```
- Line 51: lat
  ```
  o <- order(later, earlier)
  ```
- Line 54: lat
  ```
  ptr = c(0L, cumsum(tabulate(later, nbins = n))),
  ```
- Line 63: name
  ```
  unname(lapply(nb, as.integer))
  ```
- Line 66: network
  ```
  # Observation network given directly as a list of neighbour vectors (1-based)
  ```
- Line 77: name
  ```
  idx = as.integer(unlist(nb, use.names = FALSE) - 1L))
  ```
- Line 86: lat
  ```
  so <- file.path(build_dir, paste0("signal_counting", .Platform$dynlib.ext))
  ```
- Line 89: son
  ```
  # The first attempt ignores a personal ~/.R/Makevars (which could add flags
  ```
- Line 90: second
  ```
  # such as -ffast-math); if that fails, the second attempt uses it, since on
  ```
- Line 92: lat
  ```
  compile <- function(isolated) {
  ```
- Line 102: name
  ```
  on.exit(for (v in names(old)) {
  ```
- Line 106: lat
  ```
  if (isolated) {
  ```
- Line 116: lat, son
  ```
  header <- if (isolated) "## build ignoring personal Makevars" else "## build with personal Makevars"
  ```
- Line 133: name
  ```
  identical(unname(tools::md5sum(src)), unname(tools::md5sum(built_src)))
  ```
- Line 138: lat
  ```
  if (is.null(core) && dir_ok && compile(isolated = TRUE)) core <- load()
  ```
- Line 139: lat
  ```
  if (is.null(core) && dir_ok && compile(isolated = FALSE)) core <- load()
  ```
- Line 144: network
  ```
  "times slower for the largest networks.")
  ```
- Line 184: network
  ```
  # r_i for every agent in an observation network given in CSR form. The result
  ```
- Line 212: network
  ```
  # Bounds that hold in every network: an agent who observes j can do at least
  ```
- Line 215: lat
  ```
  # r_i <= 1 + |N^ind(i)|. Stops if either bound is violated.
  ```
- Line 224: name
  ```
  lower[as.integer(names(m))] <- 1 + m
  ```
- Line 227: lat
  ```
  if (!ok) stop("signal counts violate 1 + max_j r_j <= r_i <= 1 + |N^ind(i)|")
  ```

**/replication-package/replication_package/code/lib/signal_counting.c**

- Line 4: network
  ```
  * Learning in Networks"). Built by code/lib/signal_counting.R with
  ```
- Line 7: lat
  ```
  * the platform, though this was verified only on macOS arm64) and called with
  ```
- Line 10: network
  ```
  * Agents 0, ..., n-1 move in this order. The observation network is passed in
  ```
- Line 34: network
  ```
  *     the observation network (i -> j when i observes j), computed exactly by
  ```
- Line 58: sex
  ```
  static int check_csr(int n, SEXP ptr_, SEXP idx_)
  ```
- Line 130: sex
  ```
  SEXP fb_signal_counts(SEXP n_, SEXP ptr_, SEXP idx_)
  ```
- Line 144: loc, sex
  ```
  SEXP C_ = PROTECT(Rf_allocVector(REALSXP, (R_xlen_t) nn * (R_xlen_t) nn));
  ```
- Line 146: loc, sex
  ```
  SEXP out = PROTECT(Rf_allocVector(REALSXP, n));
  ```
- Line 149: loc
  ```
  double *S = (double *) R_alloc(dm * dm, sizeof(double));
  ```
- Line 150: loc
  ```
  double *rhs = (double *) R_alloc(dm, sizeof(double));
  ```
- Line 151: loc
  ```
  double *beta = (double *) R_alloc(dm, sizeof(double));
  ```
- Line 152: loc
  ```
  double *ci = (double *) R_alloc(nn, sizeof(double));
  ```
- Line 200: sex
  ```
  SEXP mp = PROTECT(Rf_ScalarReal(min_pivot));
  ```
- Line 206: sex
  ```
  SEXP fb_reachable_counts(SEXP n_, SEXP ptr_, SEXP idx_)
  ```
- Line 216: loc, sex
  ```
  SEXP bits_ = PROTECT(Rf_allocVector(RAWSXP, (R_xlen_t) (words * (size_t) n * sizeof(uint64_t))));
  ```
- Line 218: loc, sex
  ```
  SEXP out = PROTECT(Rf_allocVector(INTSXP, n));
  ```

**/replication-package/replication_package/code/lib/utils.R**

- Line 33: loc, location
  ```
  # (location in paper, description, value); values are formatted by the caller.
  ```
- Line 36: loc, location
  ```
  location = vapply(rows, function(x) as.character(x[[1]]), ""),
  ```
- Line 41: name
  ```
  utils::write.csv(df, file.path(paths$numbers, file), row.names = FALSE)
  ```
- Line 53: lat
  ```
  # nextRNGSubStream. Adding substreams later leaves the earlier ones unchanged.
  ```
- Line 102: name
  ```
  Sys.info()[["sysname"]],
  ```
- Line 124: lat
  ```
  if (.Platform$OS.type == "windows") return(1L)
  ```
- Line 132: lon
  ```
  # job larger than the budget runs alone. Jobs are considered in the order
  ```
- Line 151: minute
  ```
  log_msg(sprintf("  %d of %d jobs done (%.0f%%) after %.1f minutes", n_done, n_jobs,
  ```
- Line 191: name
  ```
  for (pid in names(done)) {
  ```
- Line 198: name
  ```
  if (!is.list(x$res) || !("value" %in% names(x$res))) {
  ```

**/replication-package/replication_package/code/tests/test_signal_counting.R**

- Line 13: name
  ```
  check <- function(name, ok) {
  ```
- Line 14: name
  ```
  cat(sprintf("%-78s %s\n", name, if (isTRUE(ok)) "PASS" else "FAIL"))
  ```
- Line 30: name
  ```
  for (impl in names(impls)) {
  ```
- Line 35: network
  ```
  check(sprintf("[%s] Example 1: shield network r = (1, 2, 2, 4)", impl),
  ```
- Line 37: network
  ```
  check(sprintf("[%s] Example 1: diamond network r_4 = 11/3", impl),
  ```
- Line 50: network
  ```
  check(sprintf("[%s] Example 2: three-generation network formula", impl), ok)
  ```
- Line 52: network
  ```
  # Maximal generations network: Algorithm 1 vs the closed form behind Figure 4
  ```
- Line 59: network
  ```
  check(sprintf("[%s] maximal generations network matches closed form (Fig. 4)", impl), ok)
  ```
- Line 61: network
  ```
  # Random generations networks: covariance recursion used for Figure 5 vs
  ```
- Line 62: network
  ```
  # Algorithm 1 on the same network written out agent by agent
  ```
- Line 74: network
  ```
  # ---- observation network construction ----------------------------------------------
  ```
- Line 95: network
  ```
  # ---- compiled vs pure-R implementation, including dense networks -------------
  ```
- Line 114: network
  ```
  check("compiled and pure-R Algorithm 1 agree (incl. dense network, d up to ~380)", ok_r)
  ```
- Line 117: network
  ```
  check("1 + max_j r_j <= r_i <= 1 + |N^ind(i)| on random networks", ok_bounds)
  ```
- Line 137: lat
  ```
  if (.Platform$OS.type != "windows") {
  ```
- Line 158: name
  ```
  text_files <- c(list.files("code", recursive = TRUE, full.names = TRUE, pattern = "\\.(R|py|c)$"),
  ```

**/replication-package/replication_package/config.R**

- Line 10: name
  ```
  env_int <- function(name, default) {
  ```
- Line 11: name
  ```
  x <- Sys.getenv(name, unset = NA)
  ```
- Line 13: name
  ```
  if (!grepl("^[0-9]+$", x) || as.integer(x) < 1) stop("environment variable ", name, " must be a posi
  ```
- Line 21: lat
  ```
  python = Sys.getenv("PYTHON", unset = if (.Platform$OS.type == "windows") "python" else "python3"),
  ```
- Line 27: school
  ```
  # Memory budget in GB for Facebook jobs running at the same time. A school
  ```
- Line 28: school
  ```
  # with N students needs about 8.2 * N^2 bytes (6 GB for the largest school,
  ```
- Line 29: lon, school
  ```
  # Penn94); a school larger than the budget runs alone. NA means 60% of the
  ```
- Line 37: network
  ```
  # Figure 5: random generations networks (Section 4.3)
  ```

**/replication-package/replication_package/reference_output/tables/table1.tex**

- Line 1: school
  ```
  % Table 1, generated by code/06_facebook_results.R (1000 random orderings per school)
  ```

**/replication-package/replication_package/run_all.R**

- Line 2: zip
  ```
  # once data/raw/facebook100.zip has been downloaded (see README.txt).
  ```
- Line 14: name
  ```
  list(id = "00", name = "tests of the signal-counting code", lang = "R",
  ```
- Line 16: name
  ```
  list(id = "01", name = "Figure 4", lang = "R", script = "code/01_figure4_maximal_generations.R"),
  ```
- Line 17: name
  ```
  list(id = "02", name = "Figure 7", lang = "python", script = "code/02_figure7_utility_vs_signals.py"
  ```
- Line 18: name
  ```
  list(id = "03", name = "Figure 5", lang = "R", script = "code/03_figure5_random_regular.R"),
  ```
- Line 19: name
  ```
  list(id = "04", name = "Facebook data extraction", lang = "python", script = "code/04_facebook_extra
  ```
- Line 21: name
  ```
  list(id = "05", name = "Facebook random orderings", lang = "R", script = "code/05_facebook_random_or
  ```
- Line 22: name
  ```
  list(id = "06", name = "Table 1, Figure 8, Facebook in-text numbers", lang = "R",
  ```
- Line 52: name
  ```
  if (any(c("00", "05", "06") %in% ids) && !requireNamespace("igraph", quietly = TRUE)) {
  ```
- Line 55: zip
  ```
  if ("04" %in% ids && !file.exists(file.path(paths$raw, "facebook100.zip"))) {
  ```
- Line 56: zip
  ```
  problems <- c(problems, "data/raw/facebook100.zip not found; download it as described in README.txt"
  ```
- Line 67: name
  ```
  cpu <- safe(switch(Sys.info()[["sysname"]],
  ```
- Line 69: name
  ```
  Linux = sub(".*: ", "", grep("model name", readLines("/proc/cpuinfo"), value = TRUE)[1]),
  ```
- Line 94: name
  ```
  log_file <- file.path(paths$logs, sub("\\.(R|py)$", ".log", basename(s$script)))
  ```
- Line 96: name
  ```
  say("Step ", s$id, ": ", s$name, " (log: ", log_file, ")")
  ```
- Line 99: minute
  ```
  minutes <- (proc.time()[["elapsed"]] - t0) / 60
  ```
- Line 100: minute, name
  ```
  row <- data.frame(run = run_id, step = s$id, name = s$name, minutes = round(minutes, 2),
  ```
- Line 102: name
  ```
  write.table(row, timings_file, sep = ",", row.names = FALSE,
  ```
- Line 103: name
  ```
  col.names = !file.exists(timings_file), append = file.exists(timings_file))
  ```
- Line 110: minute
  ```
  say(sprintf("  done in %.1f minutes", minutes))
  ```

