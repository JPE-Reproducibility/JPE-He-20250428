# Settings for the replication package. Edit here; all scripts read this file.
# Some settings can also be overridden with environment variables (shown in
# brackets), e.g. for a quick test run:
#   N_CORES=1 FACEBOOK_ORDERINGS=1 RANDOM_REGULAR_REPS=20 Rscript run_all.R
# Runs with fewer orderings or replications than the defaults below do NOT
# reproduce the paper.

detected_cores <- parallel::detectCores(logical = FALSE)
if (is.na(detected_cores)) detected_cores <- 1L
env_int <- function(name, default) {
  x <- Sys.getenv(name, unset = NA)
  if (is.na(x)) return(as.integer(default))
  if (!grepl("^[0-9]+$", x) || as.integer(x) < 1) stop("environment variable ", name, " must be a positive integer")
  as.integer(x)
}

config <- list(
  # Python interpreter with numpy, scipy and matplotlib (see requirements.txt)
  # [PYTHON], e.g. PYTHON=.venv/bin/python (macOS/Linux) or
  # .venv\Scripts\python.exe (Windows).
  python = Sys.getenv("PYTHON", unset = "/files/JPE-He-20250428/replication-package/replication_package/.venv/bin/python"),

  # Parallel worker processes [N_CORES]. Workers are forked processes, so they
  # are used on macOS and Linux only; on Windows everything runs on one core.
  n_cores = env_int("N_CORES", 15L),

  # Memory budget in GB for Facebook jobs running at the same time. A school
  # with N students needs about 8.2 * N^2 bytes (6 GB for the largest school,
  # Penn94); a school larger than the budget runs alone. NA means 60% of the
  # physical memory (8 GB if it cannot be determined).
  mem_budget_gb = 38,

  # Use the compiled implementation of Algorithm 1 (code/lib/signal_counting.c)
  # if a C compiler is available; otherwise the pure-R version is used.
  use_compiled = TRUE,

  # Figure 5: random generations networks (Section 4.3)
  random_regular_reps = env_int("RANDOM_REGULAR_REPS", 1000L),   # [RANDOM_REGULAR_REPS]
  random_regular_seed = 20261019L,

  # Facebook application (Appendix B.2)
  facebook_orderings = env_int("FACEBOOK_ORDERINGS", 1000L),     # [FACEBOOK_ORDERINGS]
  facebook_seed = 20261020L,
  facebook_cohorts = 2006:2009
)
rm(detected_cores, env_int)
