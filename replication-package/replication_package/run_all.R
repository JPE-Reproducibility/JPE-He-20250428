# Master script: reproduces every computed figure, table and in-text number,
# once data/raw/facebook100.zip has been downloaded (see README.txt).
#
#   Rscript run_all.R            # all steps
#   Rscript run_all.R 05 06      # only the listed steps (see `steps` below)
#
# Run from the root of the replication package. Settings (parallel workers,
# memory budget, seeds, number of random orderings, Python interpreter) are in
# config.R. Each step runs in its own R or Python process and writes a log to
# output/logs/. Steps depend on earlier ones: 05 needs 04, and 06 needs 04 and 05.
source(file.path("code", "lib", "utils.R"))

steps <- list(
  list(id = "00", name = "tests of the signal-counting code", lang = "R",
       script = "code/tests/test_signal_counting.R"),
  list(id = "01", name = "Figure 4", lang = "R", script = "code/01_figure4_maximal_generations.R"),
  list(id = "02", name = "Figure 7", lang = "python", script = "code/02_figure7_utility_vs_signals.py"),
  list(id = "03", name = "Figure 5", lang = "R", script = "code/03_figure5_random_regular.R"),
  list(id = "04", name = "Facebook data extraction", lang = "python", script = "code/04_facebook_extract.py",
       args = as.character(range(config$facebook_cohorts))),
  list(id = "05", name = "Facebook random orderings", lang = "R", script = "code/05_facebook_random_orderings.R"),
  list(id = "06", name = "Table 1, Figure 8, Facebook in-text numbers", lang = "R",
       script = "code/06_facebook_results.R")
)
selected <- commandArgs(trailingOnly = TRUE)
if (length(selected)) {
  unknown <- setdiff(selected, vapply(steps, `[[`, "", "id"))
  if (length(unknown)) stop("unknown step(s): ", paste(unknown, collapse = ", "))
  steps <- Filter(function(s) s$id %in% selected, steps)
}
ids <- vapply(steps, `[[`, "", "id")

master_log <- file.path(paths$logs, "run_all.log")
say <- function(...) {
  line <- paste0(format(Sys.time(), "[%Y-%m-%d %H:%M:%S] "), ...)
  cat(line, "\n", sep = "")
  cat(line, "\n", sep = "", file = master_log, append = TRUE)
}

# ---- pre-flight checks -------------------------------------------------------------
problems <- character(0)
python_ok <- function() {
  if (!nzchar(Sys.which(config$python))) return(FALSE)
  status <- suppressWarnings(system2(config$python, c("-c", shQuote("import numpy, scipy, matplotlib")),
                                     stdout = FALSE, stderr = FALSE))
  identical(status, 0L)
}
if (any(c("02", "04") %in% ids) && !python_ok()) {
  problems <- c(problems, sprintf(paste0("Python interpreter '%s' not found or missing numpy/scipy/matplotlib; ",
                                         "install requirements.txt and set PYTHON (see README.txt)"), config$python))
}
if (any(c("00", "05", "06") %in% ids) && !requireNamespace("igraph", quietly = TRUE)) {
  problems <- c(problems, "R package igraph is not installed: install.packages(\"igraph\")")
}
if ("04" %in% ids && !file.exists(file.path(paths$raw, "facebook100.zip"))) {
  problems <- c(problems, "data/raw/facebook100.zip not found; download it as described in README.txt")
}
if (length(problems)) stop("cannot start:\n  - ", paste(problems, collapse = "\n  - "))

# one thread per process for multithreaded math libraries: the scripts already
# run up to config$n_cores processes in parallel
Sys.setenv(OMP_NUM_THREADS = "1", OPENBLAS_NUM_THREADS = "1", MKL_NUM_THREADS = "1",
           VECLIB_MAXIMUM_THREADS = "1")

# ---- record the computing environment before running -----------------------------
safe <- function(expr, default = "not available") tryCatch(expr, error = function(e) default)
cpu <- safe(switch(Sys.info()[["sysname"]],
                   Darwin = system("sysctl -n machdep.cpu.brand_string", intern = TRUE),
                   Linux = sub(".*: ", "", grep("model name", readLines("/proc/cpuinfo"), value = TRUE)[1]),
                   Sys.getenv("PROCESSOR_IDENTIFIER")))
compiler <- safe(suppressWarnings(system2(file.path(R.home("bin"), "R"), c("CMD", "config", "CC"),
                                          stdout = TRUE, stderr = TRUE))[1])
py_versions <- safe(suppressWarnings(system2(config$python, c("-c", shQuote(paste0(
  "import sys, numpy, scipy, matplotlib; print('Python', sys.version.split()[0], '| numpy', numpy.__version__, ",
  "'| scipy', scipy.__version__, '| matplotlib', matplotlib.__version__)"))), stdout = TRUE, stderr = FALSE)))
env_lines <- c(
  paste("Run started:", format(Sys.time())), paste("Steps:", paste(ids, collapse = " ")),
  paste("CPU:", cpu), paste("CPU cores:", parallel::detectCores()),
  sprintf("Physical memory: %.1f GB", physical_memory_gb()),
  paste("Parallel workers used:", effective_cores()), sprintf("Memory budget: %.1f GB", memory_budget_gb()),
  paste("C compiler (R CMD config CC):", compiler),
  paste("igraph", safe(as.character(utils::packageVersion("igraph")))),
  paste("Python:", config$python, "|", paste(py_versions, collapse = " ")),
  "", "config:", capture.output(str(config)), "", capture.output(sessionInfo())
)
writeLines(env_lines, file.path(paths$logs, "environment.txt"))

# ---- run the steps -----------------------------------------------------------------
rscript <- file.path(R.home("bin"), "Rscript")
timings_file <- file.path(paths$logs, "run_all_timings.csv")
run_id <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
say("Starting steps ", paste(ids, collapse = " "), " with ", effective_cores(), " parallel worker(s)")
for (s in steps) {
  log_file <- file.path(paths$logs, sub("\\.(R|py)$", ".log", basename(s$script)))
  cmd <- if (s$lang == "R") rscript else config$python
  say("Step ", s$id, ": ", s$name, " (log: ", log_file, ")")
  t0 <- proc.time()[["elapsed"]]
  status <- system2(cmd, c(shQuote(s$script), s$args), stdout = log_file, stderr = log_file)
  minutes <- (proc.time()[["elapsed"]] - t0) / 60
  row <- data.frame(run = run_id, step = s$id, name = s$name, minutes = round(minutes, 2),
                    status = if (identical(status, 0L)) "ok" else paste("failed:", status))
  write.table(row, timings_file, sep = ",", row.names = FALSE,
              col.names = !file.exists(timings_file), append = file.exists(timings_file))
  if (!identical(status, 0L)) {
    say("Step ", s$id, " FAILED (status ", status, "). Last lines of ", log_file, ":")
    tail_lines <- tryCatch(tail(readLines(log_file), 20), error = function(e) character(0))
    cat(paste0("    ", tail_lines), sep = "\n")
    stop("step ", s$id, " failed; see ", log_file)
  }
  say(sprintf("  done in %.1f minutes", minutes))
}
say("All selected steps finished. Outputs are in output/; timings in ", timings_file)
