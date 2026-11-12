# Appendix B.2: rational sequential social learning on the 100 collegiate
# Facebook networks, with the students moving in random orders.
#
# For each school and each of config$facebook_orderings random orderings, a
# student observes her Facebook friends who move before her. We compute r_i
# for every student with Algorithm 1 (Appendix B.1) and the size of her
# indirect neighbourhood N^ind(i) (students reachable by a path), and store
#   frac_potential = (1/N)  sum_i r_i / i
#   frac_reachable = (1/N') sum_{i: N^ind(i) nonempty} (r_i - 1) / |N^ind(i)|,
# where N' is the number of students with a nonempty indirect neighbourhood.
#
# Orderings are drawn with L'Ecuyer-CMRG streams: the school with Facebook
# number s (the number at the end of its name, 1-100) uses stream s, and its
# k-th ordering uses substream k. Results therefore do not depend on the
# number of cores or on which schools are run, and raising the number of
# orderings keeps the earlier ones. Each parallel job handles one school and a
# block of up to `block_size` consecutive orderings (this affects only
# scheduling, not results). Each block's results are saved in
# output/intermediate/facebook_orderings/ and reused on a rerun only if the
# orderings, seed, school's data files, class years, implementation (compiled
# or pure R) and code (signal_counting.c/.R, utils.R and this script) are
# unchanged. Runtime and memory: see README.md.
source(file.path("code", "lib", "utils.R"))
source(file.path(paths$lib, "signal_counting.R"))

block_size <- 50L

data_dir <- file.path(paths$derived, "facebook100")
out_dir <- file.path(paths$intermediate, "facebook_orderings")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
if (!file.exists(file.path(data_dir, "extraction_info.csv"))) {
  stop("Run code/04_facebook_extract.py first.")
}
info <- read.csv(file.path(data_dir, "extraction_info.csv"))
cohorts <- as.integer(config$facebook_cohorts)
if (!identical(c(info$first_year, info$last_year), range(cohorts)) ||
    !identical(cohorts, seq(min(cohorts), max(cohorts)))) {
  stop("The derived data contain class years ", info$first_year, "-", info$last_year,
       " but config.R sets ", paste(range(cohorts), collapse = "-"),
       "; rerun code/04_facebook_extract.py with the years in config.R.")
}
schools_tab <- read.csv(file.path(data_dir, "schools.csv"), stringsAsFactors = FALSE)
schools_tab <- schools_tab[order(schools_tab$school, method = "radix"), ]
schools <- schools_tab$school
stems <- setNames(schools_tab$file_stem, schools)
school_number <- setNames(as.integer(regmatches(schools, regexpr("[0-9]+$", schools))), schools)
if (anyNA(school_number) || anyDuplicated(school_number)) stop("could not parse unique school numbers")
n_orderings <- as.integer(config$facebook_orderings)

# Students are numbered by class year (oldest cohort first) and then by their
# order in the raw data; a random permutation of this list gives the ordering.
school_files <- function(s) file.path(data_dir, paste0(stems[[s]], c("_students.csv", "_edges.csv")))
read_school <- function(s) {
  f <- school_files(s)
  st <- read.csv(f[1])
  ed <- read.csv(f[2])
  stopifnot(all(st$class_year %in% cohorts))
  node <- integer(nrow(st))
  node[order(st$class_year, st$student)] <- seq_len(nrow(st))
  list(n = nrow(st), from = node[ed$i], to = node[ed$j], md5 = unname(tools::md5sum(f)))
}
log_msg("Reading ", length(schools), " schools")
school_data <- setNames(lapply(schools, read_school), schools)

core <- if (isTRUE(config$use_compiled)) load_signal_counting_core(paths$lib, paths$build) else NULL
implementation <- if (is.null(core)) "pure-R" else "compiled"
code_md5 <- unname(tools::md5sum(c(file.path(paths$lib, c("signal_counting.c", "signal_counting.R", "utils.R")),
                                   file.path("code", "05_facebook_random_orderings.R"))))
streams <- rng_streams(config$facebook_seed, max(school_number), n_orderings)

# one job per school and block of consecutive orderings
jobs <- list()
for (s in schools) {
  for (first in seq(1L, n_orderings, by = block_size)) {
    ords <- first:min(first + block_size - 1L, n_orderings)
    jobs[[length(jobs) + 1]] <- list(school = s, orderings = ords,
                                     rng = streams[[school_number[[s]]]][ords])
  }
}
n_job <- vapply(jobs, function(j) school_data[[j$school]]$n, 0)
jobs <- jobs[order(-n_job)]
n_job <- sort(n_job, decreasing = TRUE)
# covariance matrix + bitsets + R process (the pure-R version needs more temporary memory)
mem_gb <- (if (is.null(core)) 9 else 8.2) * n_job^2 / 1e9 + 0.3

block_file <- function(job) {
  file.path(out_dir, sprintf("%s__orderings%04d-%04d.rds", stems[[job$school]],
                             min(job$orderings), max(job$orderings)))
}

one_ordering <- function(x, state, ordering, school) {
  t0 <- proc.time()[["elapsed"]]
  use_rng_state(state)
  perm <- sample.int(x$n)
  csr <- observation_csr(x$n, x$from, x$to, perm)
  r <- signal_counts(csr, core)
  reach <- reachable_counts(csr, core)
  check_signal_counts(csr, r, reach)
  have <- reach > 0
  data.frame(
    school = school, ordering = ordering, n = x$n,
    frac_potential = mean(r / seq_len(x$n)),
    frac_reachable = mean(((r - 1) / reach)[have]),
    n_nonempty_indirect = sum(have),
    min_pivot = attr(r, "min_pivot"),
    seconds = proc.time()[["elapsed"]] - t0,
    stringsAsFactors = FALSE
  )
}

run_block <- function(job) {
  f <- block_file(job)
  x <- school_data[[job$school]]
  key <- list(orderings = job$orderings, rng = job$rng, data_md5 = x$md5, code_md5 = code_md5,
              implementation = implementation, cohorts = cohorts)
  if (file.exists(f)) {
    old <- tryCatch(readRDS(f), error = function(e) NULL)
    if (is.list(old) && identical(old$key, key)) return(cbind(old$res, cached = TRUE))
  }
  rows <- vector("list", length(job$orderings))
  for (j in seq_along(job$orderings)) {
    rows[[j]] <- one_ordering(x, job$rng[[j]], job$orderings[j], job$school)
    invisible(gc(verbose = FALSE))  # free the n x n matrix before the next ordering
  }
  res <- do.call(rbind, rows)
  tmp <- paste0(f, ".", Sys.getpid(), ".tmp")
  saveRDS(list(res = res, key = key), tmp)
  if (!file.rename(tmp, f)) {          # renaming onto an existing file can fail on Windows
    unlink(f)
    if (!file.rename(tmp, f)) stop("could not write ", f)
  }
  cbind(res, cached = FALSE)
}

budget <- memory_budget_gb()
log_msg(sprintf("%d schools x %d orderings in %d jobs of up to %d orderings, on %d core(s), memory budget %.0f GB, %s implementation",
                length(schools), n_orderings, length(jobs), block_size, effective_cores(), budget, implementation))
if (max(mem_gb) > budget) {
  log_msg(sprintf("note: the largest school needs about %.1f GB and will run alone", max(mem_gb)))
}
t0 <- proc.time()[["elapsed"]]
res <- do.call(rbind, run_jobs(jobs, run_block, n_cores = config$n_cores, mem_gb = mem_gb,
                               budget_gb = budget, progress = TRUE))
res <- res[order(match(res$school, schools), res$ordering), ]
write.csv(res[, setdiff(names(res), c("seconds", "cached"))],
          file.path(paths$intermediate, "facebook_orderings.csv"), row.names = FALSE)
write.csv(res[, c("school", "ordering", "n", "seconds", "cached")],
          file.path(paths$logs, "facebook_job_times.csv"), row.names = FALSE)
# provenance of facebook_orderings.csv, checked by 06_facebook_results.R
write.csv(data.frame(facebook_seed = config$facebook_seed, facebook_orderings = n_orderings,
                     first_year = min(cohorts), last_year = max(cohorts), implementation = implementation,
                     code_md5 = paste(code_md5, collapse = ";"),
                     data_md5 = paste(unlist(lapply(school_data, `[[`, "md5")), collapse = ";")),
          file.path(paths$intermediate, "facebook_orderings_info.csv"), row.names = FALSE)
computed <- !res$cached
log_msg(sprintf("Done in %.1f minutes: %d orderings computed (sum of their times %.1f minutes), %d reused; smallest Cholesky pivot %.6f",
                (proc.time()[["elapsed"]] - t0) / 60, sum(computed), sum(res$seconds[computed]) / 60,
                sum(!computed), min(res$min_pivot)))
