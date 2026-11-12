# Shared helpers: settings, paths, logging, in-text numbers, random-number
# streams, and parallel jobs. Every script is run from the root of the
# replication package.

if (!file.exists("config.R")) {
  stop("Run the scripts from the root of the replication package (the folder containing config.R).")
}
source("config.R")

paths <- list(
  lib = file.path("code", "lib"),
  raw = file.path("data", "raw"),
  derived = file.path("data", "derived"),
  figures = file.path("output", "figures"),
  tables = file.path("output", "tables"),
  numbers = file.path("output", "numbers"),
  intermediate = file.path("output", "intermediate"),
  logs = file.path("output", "logs"),
  build = file.path("output", "build")
)
for (p in paths[c("raw", "derived", "figures", "tables", "numbers", "intermediate", "logs", "build")]) {
  dir.create(p, recursive = TRUE, showWarnings = FALSE)
  if (!dir.exists(p) || file.access(p, 2) != 0) {
    stop("cannot create or write to the folder ", p, "; run the package from a writable location")
  }
}

log_msg <- function(...) {
  cat(format(Sys.time(), "[%Y-%m-%d %H:%M:%S] "), ..., "\n", sep = "")
}

# In-text numbers are written to output/numbers/<file> as rows of
# (location in paper, description, value); values are formatted by the caller.
write_numbers <- function(rows, file) {
  df <- data.frame(
    location = vapply(rows, function(x) as.character(x[[1]]), ""),
    description = vapply(rows, function(x) as.character(x[[2]]), ""),
    value = vapply(rows, function(x) as.character(x[[3]]), ""),
    stringsAsFactors = FALSE
  )
  utils::write.csv(df, file.path(paths$numbers, file), row.names = FALSE)
  df
}

# ---- random numbers ------------------------------------------------------------

# All random draws use L'Ecuyer-CMRG streams (see ?parallel::nextRNGStream),
# assigned to jobs before they run, so results do not depend on the number of
# cores or on the order in which jobs finish. rng_streams(seed, n_streams,
# n_substreams) returns a list of n_streams lists, each holding n_substreams
# .Random.seed vectors: stream s, substream j is the state reached from
# set.seed(seed) by s - 1 calls to nextRNGStream and j - 1 calls to
# nextRNGSubStream. Adding substreams later leaves the earlier ones unchanged.
rng_streams <- function(seed, n_streams, n_substreams = 1L) {
  restore <- preserve_rng_state()
  on.exit(restore())
  RNGkind("L'Ecuyer-CMRG", "Inversion", "Rejection")
  set.seed(seed)
  s <- get(".Random.seed", envir = globalenv())
  out <- vector("list", n_streams)
  for (i in seq_len(n_streams)) {
    sub <- vector("list", n_substreams)
    x <- s
    for (j in seq_len(n_substreams)) {
      sub[[j]] <- x
      x <- parallel::nextRNGSubStream(x)
    }
    out[[i]] <- sub
    s <- parallel::nextRNGStream(s)
  }
  out
}

# Returns a function that restores the current RNG kind and state (or the
# absence of a state), so helpers can draw random numbers without side effects.
preserve_rng_state <- function() {
  had_seed <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  old_seed <- if (had_seed) get(".Random.seed", envir = globalenv()) else NULL
  old_kind <- RNGkind()
  function() {
    RNGkind(old_kind[1], old_kind[2], old_kind[3])
    if (had_seed) {
      assign(".Random.seed", old_seed, envir = globalenv())
    } else if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) {
      rm(".Random.seed", envir = globalenv())
    }
  }
}

# Make `state` (an element returned by rng_streams) the current RNG state.
use_rng_state <- function(state) {
  RNGkind("L'Ecuyer-CMRG", "Inversion", "Rejection")
  assign(".Random.seed", state, envir = globalenv())
  invisible(NULL)
}

# ---- memory and parallel jobs --------------------------------------------------

# Physical memory in GB (NA if it cannot be determined).
physical_memory_gb <- function() {
  bytes <- tryCatch(switch(
    Sys.info()[["sysname"]],
    Darwin = as.numeric(system("sysctl -n hw.memsize", intern = TRUE)),
    Linux = as.numeric(sub("^MemTotal:\\s+(\\d+).*$", "\\1",
                           grep("^MemTotal:", readLines("/proc/meminfo"), value = TRUE))) * 1024,
    NA_real_
  ), error = function(e) NA_real_, warning = function(w) NA_real_)
  bytes / 1e9
}

# Memory budget for simultaneously running jobs: config$mem_budget_gb if set,
# otherwise 60% of physical memory (8 GB if that cannot be determined).
memory_budget_gb <- function() {
  if (!is.null(config$mem_budget_gb) && !is.na(config$mem_budget_gb)) return(config$mem_budget_gb)
  ram <- physical_memory_gb()
  if (is.na(ram)) 8 else 0.6 * ram
}

# Number of parallel worker processes actually used: config$n_cores on macOS
# and Linux; 1 on Windows (no forking) and inside an interactive RStudio
# session (forking the RStudio GUI process is unsafe; run_all.R launches each
# step as a separate Rscript process, so it is not affected).
effective_cores <- function(n_cores = config$n_cores) {
  if (.Platform$OS.type == "windows") return(1L)
  if (interactive() && identical(Sys.getenv("RSTUDIO"), "1")) return(1L)
  as.integer(max(1L, n_cores))
}

# Run FUN(jobs[[k]]) for every k and return the results in the order of jobs.
# At most n_cores jobs run at a time, and a job is started only if the memory
# of the running jobs (mem_gb, in GB) plus its own stays within budget_gb; a
# job larger than the budget runs alone. Jobs are considered in the order
# given, but a smaller job may start before a larger one that does not fit
# yet. FUN must not rely on the parent's random-number state (assign each job
# its own stream with rng_streams()). Uses forked processes via
# parallel::mcparallel; jobs run sequentially if effective_cores() is 1.
# A job that fails, or a worker that dies (for example when the operating
# system kills it for lack of memory), stops the whole run, and the remaining
# workers are killed. With progress = TRUE, a line is logged each time another
# 5% of the jobs has finished.
run_jobs <- function(jobs, FUN, n_cores = 1, mem_gb = rep(0, length(jobs)), budget_gb = Inf,
                     progress = FALSE) {
  n_jobs <- length(jobs)
  results <- vector("list", n_jobs)
  n_cores <- effective_cores(n_cores)
  t_start <- proc.time()[["elapsed"]]
  n_done <- 0L
  report <- function() {
    n_done <<- n_done + 1L
    if (progress && floor(20 * n_done / n_jobs) > floor(20 * (n_done - 1L) / n_jobs)) {
      log_msg(sprintf("  %d of %d jobs done (%.0f%%) after %.1f minutes", n_done, n_jobs,
                      100 * n_done / n_jobs, (proc.time()[["elapsed"]] - t_start) / 60))
    }
  }
  if (n_cores <= 1) {
    # as in forked workers, jobs do not change the caller's RNG state
    restore <- preserve_rng_state()
    on.exit(restore(), add = TRUE)
    for (k in seq_len(n_jobs)) {
      results[k] <- list(FUN(jobs[[k]]))
      report()
    }
    return(results)
  }
  pending <- seq_len(n_jobs)
  running <- list()
  on.exit({
    if (length(running)) {
      for (x in running) tools::pskill(x$job$pid, tools::SIGKILL)
      suppressWarnings(parallel::mccollect(lapply(running, function(x) x$job), wait = TRUE))
    }
  }, add = TRUE)
  while (length(pending) > 0 || length(running) > 0) {
    repeat {
      if (length(pending) == 0 || length(running) >= n_cores) break
      used <- sum(vapply(running, function(x) x$mem, numeric(1)))
      fits <- pending[used + mem_gb[pending] <= budget_gb]
      if (length(fits) == 0 && length(running) == 0) fits <- pending[1]
      if (length(fits) == 0) break
      k <- fits[1]
      # wrap the value so that a worker that dies without reporting (NULL) is detected
      job <- parallel::mcparallel(list(value = FUN(jobs[[k]])), mc.set.seed = FALSE)
      running[[length(running) + 1]] <- list(k = k, mem = mem_gb[k], job = job)
      pending <- pending[pending != k]
    }
    done <- suppressWarnings(
      parallel::mccollect(lapply(running, function(x) x$job), wait = FALSE, timeout = 0.5)
    )
    # first take every collected job off the running list, then check results
    collected <- list()
    for (pid in names(done)) {
      i <- which(vapply(running, function(x) as.character(x$job$pid), "") == pid)
      collected[[length(collected) + 1]] <- list(k = running[[i]]$k, res = done[[pid]])
      running[[i]] <- NULL
    }
    for (x in collected) {
      if (inherits(x$res, "try-error")) stop("parallel job ", x$k, " failed: ", x$res)
      if (!is.list(x$res) || !("value" %in% names(x$res))) {
        stop("parallel job ", x$k, " ended without a result (the worker may have run out of memory; ",
             "lower n_cores or mem_budget_gb in config.R)")
      }
      results[x$k] <- list(x$res$value)
      report()
    }
  }
  results
}
