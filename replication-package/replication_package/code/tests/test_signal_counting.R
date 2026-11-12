# Tests of the signal-counting code against results stated in the paper,
# across implementations, and of the helpers used by the main scripts.
# Run from the package root:  Rscript code/tests/test_signal_counting.R
source(file.path("code", "lib", "utils.R"))
source(file.path(paths$lib, "signal_counting.R"))
source(file.path(paths$lib, "generations.R"))

core <- if (isTRUE(config$use_compiled)) load_signal_counting_core(paths$lib, paths$build) else NULL
impls <- list(R = NULL)
if (!is.null(core)) impls$compiled <- core

n_fail <- 0L
check <- function(name, ok) {
  cat(sprintf("%-78s %s\n", name, if (isTRUE(ok)) "PASS" else "FAIL"))
  if (!isTRUE(ok)) n_fail <<- n_fail + 1L
}
close_to <- function(x, y, tol = 1e-9) {
  length(x) == length(y) && all(abs(x - y) <= tol * pmax(1, abs(y)))
}
seed_tests <- function(seed) {
  set.seed(seed, kind = "L'Ecuyer-CMRG", normal.kind = "Inversion", sample.kind = "Rejection")
}
random_graph <- function(n, m) {
  from <- sample.int(n, m, replace = TRUE)
  to <- sample.int(n, m, replace = TRUE)
  list(from = from, to = to)
}

# ---- results stated in the paper -------------------------------------------------
for (impl in names(impls)) {
  cr <- impls[[impl]]
  # Example 1 (Section 3.3): shield r_4 = 4, diamond r_4 = 11/3
  shield <- list_to_csr(list(integer(0), 1L, 1L, c(1L, 2L, 3L)))
  diamond <- list_to_csr(list(integer(0), 1L, 1L, c(2L, 3L)))
  check(sprintf("[%s] Example 1: shield network r = (1, 2, 2, 4)", impl),
        close_to(as.vector(signal_counts(shield, cr)), c(1, 2, 2, 4)))
  check(sprintf("[%s] Example 1: diamond network r_4 = 11/3", impl),
        close_to(as.vector(signal_counts(diamond, cr)), c(1, 2, 2, 11 / 3)))

  # Example 2: K1 agents, then K2 agents observing all of them, then one agent
  # observing the K2 agents: r = 1 + K1 in generation 2 and
  # 1 + (K2 + K1 K2) / (1 + K1 K2) * (1 + K1) for the last agent.
  ok <- TRUE
  for (K1 in c(1, 2, 5)) for (K2 in c(1, 3, 10)) {
    nb <- c(rep(list(integer(0)), K1), rep(list(seq_len(K1)), K2), list(K1 + seq_len(K2)))
    r <- signal_counts(list_to_csr(nb), cr)
    ok <- ok && close_to(r[K1 + 1], 1 + K1) &&
      close_to(r[K1 + K2 + 1], 1 + (K2 + K1 * K2) / (1 + K1 * K2) * (1 + K1))
  }
  check(sprintf("[%s] Example 2: three-generation network formula", impl), ok)

  # Maximal generations network: Algorithm 1 vs the closed form behind Figure 4
  ok <- TRUE
  for (K in 2:5) {
    G <- ceiling(40 / K) + 1
    nb <- generations_neighbour_list(K, G, rep(list(seq_len(K)), K))
    ok <- ok && close_to(as.vector(signal_counts(list_to_csr(nb), cr)), maximal_generations_ri(K, G))
  }
  check(sprintf("[%s] maximal generations network matches closed form (Fig. 4)", impl), ok)

  # Random generations networks: covariance recursion used for Figure 5 vs
  # Algorithm 1 on the same network written out agent by agent
  seed_tests(1)
  ok <- TRUE
  for (dd in list(c(2, 2), c(2, 4), c(4, 8))) {
    psi <- draw_observation_sets(20, dd[1], dd[2])
    r_gen <- generations_ri(20, 8, psi)
    r_alg <- signal_counts(list_to_csr(generations_neighbour_list(20, 8, psi)), cr)
    ok <- ok && close_to(as.vector(t(r_gen)), as.vector(r_alg), tol = 1e-8)
  }
  check(sprintf("[%s] generations recursion (Fig. 5) matches Algorithm 1", impl), ok)
}

# ---- observation network construction ----------------------------------------------
# Brute force as in the authors' original code: dense adjacency matrix,
# reordered by perm, lower triangle kept. Inputs include duplicated and
# reversed edges and self-loops.
seed_tests(3)
ok <- TRUE
for (n in c(1, 2, 30, 200)) {
  g <- random_graph(n, 5 * n)
  from <- c(g$from, g$to[1:min(10, n)])           # some reversed duplicates
  to <- c(g$to, g$from[1:min(10, n)])
  perm <- sample.int(n)
  A <- matrix(0L, n, n)
  A[cbind(from, to)] <- 1L
  A[cbind(to, from)] <- 1L
  A_obs <- A[perm, perm, drop = FALSE]
  A_obs[upper.tri(A_obs, diag = TRUE)] <- 0L
  brute <- lapply(seq_len(n), function(i) which(A_obs[i, ] == 1L))
  ok <- ok && identical(csr_to_list(observation_csr(n, from, to, perm)), brute)
}
check("observation_csr matches dense-matrix construction (dups, reversals, loops)", ok)

# ---- compiled vs pure-R implementation, including dense networks -------------
if (!is.null(core)) {
  seed_tests(2)
  ok_r <- TRUE
  ok_reach <- TRUE
  ok_pivot <- TRUE
  ok_bounds <- TRUE
  for (spec in list(c(50, 6), c(300, 6), c(800, 6), c(400, 180))) {   # (n, edges per node)
    n <- spec[1]
    g <- random_graph(n, round(n * spec[2]))
    csr <- observation_csr(n, g$from, g$to, sample.int(n))
    r_c <- signal_counts(csr, core)
    r_R <- signal_counts(csr, NULL)
    reach <- reachable_counts(csr, core)
    ok_r <- ok_r && close_to(as.vector(r_c), as.vector(r_R), tol = 1e-8)
    ok_reach <- ok_reach && identical(reach, reachable_counts(csr, NULL))
    ok_pivot <- ok_pivot && attr(r_c, "min_pivot") >= 1 - 1e-9 && attr(r_R, "min_pivot") >= 1 - 1e-9
    ok_bounds <- ok_bounds && isTRUE(check_signal_counts(csr, r_c, reach))
  }
  check("compiled and pure-R Algorithm 1 agree (incl. dense network, d up to ~380)", ok_r)
  check("compiled and igraph reachability counts agree", ok_reach)
  check("all Cholesky pivots are at least 1 (as in exact arithmetic)", ok_pivot)
  check("1 + max_j r_j <= r_i <= 1 + |N^ind(i)| on random networks", ok_bounds)
} else {
  cat("Compiled core not available: skipped cross-implementation tests.\n")
}

# ---- random-number streams -------------------------------------------------------------
s1 <- rng_streams(42, 3, 2)
s2 <- rng_streams(42, 3, 5)
check("rng_streams: adding substreams leaves earlier ones unchanged",
      identical(s1, lapply(s2, function(x) x[1:2])))
seed_tests(99); before <- .Random.seed
invisible(rng_streams(1, 2, 2))
check("rng_streams: leaves the caller's RNG state unchanged", identical(before, .Random.seed))
invisible(run_jobs(list(1, 2), function(x) runif(1), n_cores = 1))
check("run_jobs (sequential): leaves the caller's RNG state unchanged", identical(before, .Random.seed))
draw <- function(state) { use_rng_state(state); sample.int(1000, 5) }
check("rng_streams: distinct streams and substreams give different draws",
      !identical(draw(s2[[1]][[1]]), draw(s2[[1]][[2]])) && !identical(draw(s2[[1]][[1]]), draw(s2[[2]][[1]])))

# ---- parallel job runner ---------------------------------------------------------------
if (.Platform$OS.type != "windows") {
  states <- rng_streams(7, 6)
  jobs <- lapply(seq_len(6), function(k) list(k = k, state = states[[k]][[1]]))
  f <- function(job) { use_rng_state(job$state); Sys.sleep(runif(1, 0, 0.2)); c(job$k, sample.int(1e6, 1)) }
  seq_res <- run_jobs(jobs, f, n_cores = 1)
  par_res <- run_jobs(jobs, f, n_cores = 3, mem_gb = c(5, 1, 1, 5, 1, 1), budget_gb = 6)
  check("run_jobs: parallel results equal sequential results, in job order", identical(seq_res, par_res))
  check("run_jobs: NULL results are returned as NULL",
        is.null(run_jobs(list(1, 2), function(x) NULL, n_cores = 2)[[2]]))
  err <- tryCatch(run_jobs(list(1, 2, 3), function(x) if (x == 2) stop("boom") else x, n_cores = 2),
                  error = function(e) conditionMessage(e))
  check("run_jobs: an error in a job stops the run", is.character(err) && grepl("boom", err))
  err <- tryCatch(run_jobs(list(1, 2), function(x) {
    if (x == 2) tools::pskill(Sys.getpid(), tools::SIGKILL)
    x
  }, n_cores = 2), error = function(e) conditionMessage(e))
  check("run_jobs: a worker killed by the OS stops the run", is.character(err) && grepl("without a result", err))
}

# ---- package files are plain ASCII (avoids encoding problems across systems) --------
# (config.R is not checked, since replicators may edit it, e.g. to set a path)
text_files <- c(list.files("code", recursive = TRUE, full.names = TRUE, pattern = "\\.(R|py|c)$"),
                "run_all.R", "requirements.txt", "README.txt", "LICENSE",
                file.path("data", "raw", "README.txt"))
text_files <- text_files[file.exists(text_files)]
non_ascii <- text_files[vapply(text_files, function(f) {
  any(as.integer(readBin(f, "raw", file.size(f))) > 127L)
}, logical(1))]
check("package source and documentation files are plain ASCII", length(non_ascii) == 0)
if (length(non_ascii)) cat("  non-ASCII characters in:", paste(non_ascii, collapse = ", "), "\n")

if (n_fail > 0) stop(n_fail, " test(s) failed")
cat("All tests passed.\n")
