# Signal counting in arbitrary finite networks (Appendix B of the paper).
#
# Agents 1, ..., n move in order and agent i observes a subset N(i) of
# {1, ..., i-1}. With sigma^2 = 4, Var(lambda_i) = 1 and r_i = Var(l_i).
# Algorithm 1 (Appendix B.1) keeps the conditional covariance matrix C of
# log-actions and, for each agent, sets
#   beta_i = C[N(i), N(i)]^{-1} r_{N(i)},   r_i = 1 + beta_i' r_{N(i)},
#   C[k, i] = sum_{j in N(i)} beta_ij C[k, j]   (k < i).
#
# Two interchangeable implementations are provided:
#   * a compiled one (signal_counting.c, built with R CMD SHLIB), and
#   * a pure-R reference implementation, used automatically if no C compiler
#     is available (much slower for the largest networks).
# Both solve the linear systems by Cholesky factorisation and stop if a pivot
# falls below 0.5: with neighbours in increasing order, each pivot is the
# conditional variance of a neighbour's log-action given the earlier
# neighbours' actions, which is at least 1 in exact arithmetic.
# code/tests/test_signal_counting.R checks that the two implementations agree.

MIN_PIVOT <- 0.5

# ---- observation network ---------------------------------------------------

# Observation network induced by an ordering of an undirected network.
# from, to : undirected edges between nodes 1..n (each pair listed once or
#            twice, in either direction; self-loops are ignored)
# perm     : perm[p] is the node that moves in position p
# Returns the network in CSR form on positions: for p = 1..n, position p
# observes the earlier positions idx[ptr[p] + seq_len(ptr[p + 1] - ptr[p])] + 1.
observation_csr <- function(n, from, to, perm) {
  n <- as.integer(n)
  is_index <- function(x) is.numeric(x) && !anyNA(x) && all(x == round(x)) && all(x >= 1 & x <= n)
  stopifnot(
    length(from) == length(to), is_index(from), is_index(to),
    length(perm) == n, is_index(perm), identical(sort.int(as.integer(perm)), seq_len(n))
  )
  from <- as.integer(from)
  to <- as.integer(to)
  pos <- integer(n)
  pos[perm] <- seq_len(n)
  a <- pos[from]
  b <- pos[to]
  later <- pmax(a, b)
  earlier <- pmin(a, b)
  keep <- later != earlier
  later <- later[keep]
  earlier <- earlier[keep]
  dup <- duplicated((as.double(later) - 1) * n + earlier)  # exact while n^2 < 2^53
  later <- later[!dup]
  earlier <- earlier[!dup]
  o <- order(later, earlier)
  list(
    n = n,
    ptr = c(0L, cumsum(tabulate(later, nbins = n))),
    idx = as.integer(earlier[o] - 1L)
  )
}

# CSR -> list of neighbour vectors (1-based)
csr_to_list <- function(csr) {
  agent <- rep.int(seq_len(csr$n), diff(csr$ptr))
  nb <- split(csr$idx + 1L, factor(agent, levels = seq_len(csr$n)))
  unname(lapply(nb, as.integer))
}

# Observation network given directly as a list of neighbour vectors (1-based)
list_to_csr <- function(nb) {
  n <- length(nb)
  for (i in seq_len(n)) {
    x <- nb[[i]]
    if (anyNA(x) || any(x != round(x)) || (length(x) && (min(x) < 1 || max(x) >= i))) {
      stop("agent ", i, " may only observe agents 1..", i - 1L)
    }
  }
  nb <- lapply(nb, function(x) sort(unique(as.integer(x))))
  list(n = as.integer(n), ptr = c(0L, cumsum(lengths(nb))),
       idx = as.integer(unlist(nb, use.names = FALSE) - 1L))
}

# ---- compiled core -----------------------------------------------------------

# Compile (if needed) and load signal_counting.c. Returns NULL if this fails,
# in which case the pure-R implementations are used.
load_signal_counting_core <- function(lib_dir, build_dir) {
  src <- file.path(lib_dir, "signal_counting.c")
  so <- file.path(build_dir, paste0("signal_counting", .Platform$dynlib.ext))
  # Compile with R's default compiler settings plus -ffp-contract=off (no fused
  # multiply-add, so results do not depend on whether the processor has it).
  # The first attempt ignores a personal ~/.R/Makevars (which could add flags
  # such as -ffast-math); if that fails, the second attempt uses it, since on
  # some systems it is needed to find a working compiler.
  compile <- function(isolated) {
    tryCatch({
      if (file.exists(so)) {
        try(dyn.unload(so), silent = TRUE)
        unlink(so)
      }
      if (file.exists(so)) return(FALSE)          # an old library could not be removed
      unlink(file.path(build_dir, "signal_counting.o"))
      file.copy(src, build_dir, overwrite = TRUE)
      old <- Sys.getenv(c("PKG_CFLAGS", "R_MAKEVARS_USER"), unset = NA)
      on.exit(for (v in names(old)) {
        if (is.na(old[[v]])) Sys.unsetenv(v) else do.call(Sys.setenv, as.list(old[v]))
      })
      Sys.setenv(PKG_CFLAGS = "-ffp-contract=off")
      if (isolated) {
        makevars <- file.path(build_dir, "Makevars")
        writeLines("# intentionally empty: use R's default compiler settings", makevars)
        Sys.setenv(R_MAKEVARS_USER = normalizePath(makevars))
      }
      log_txt <- suppressWarnings(system2(
        file.path(R.home("bin"), "R"),
        c("CMD", "SHLIB", "-o", shQuote(so), shQuote(file.path(build_dir, "signal_counting.c"))),
        stdout = TRUE, stderr = TRUE
      ))
      header <- if (isolated) "## build ignoring personal Makevars" else "## build with personal Makevars"
      cat(c(header, log_txt, ""), file = file.path(build_dir, "compile_log.txt"), sep = "\n", append = TRUE)
      file.exists(so)
    }, error = function(e) FALSE)
  }
  load <- function() {
    dll <- tryCatch(dyn.load(so), error = function(e) NULL)
    if (is.null(dll)) return(NULL)
    tryCatch(
      list(signal_counts = getNativeSymbolInfo("fb_signal_counts", dll),
           reachable_counts = getNativeSymbolInfo("fb_reachable_counts", dll)),
      error = function(e) { try(dyn.unload(so), silent = TRUE); NULL }
    )
  }
  # reuse an existing library only if it was built from the current source
  built_src <- file.path(build_dir, "signal_counting.c")
  fresh <- file.exists(so) && file.exists(built_src) &&
    identical(unname(tools::md5sum(src)), unname(tools::md5sum(built_src)))
  core <- if (fresh) load() else NULL
  if (is.null(core)) unlink(file.path(build_dir, "compile_log.txt"))
  dir_ok <- tryCatch({ dir.create(build_dir, recursive = TRUE, showWarnings = FALSE); TRUE },
                     error = function(e) FALSE)
  if (is.null(core) && dir_ok && compile(isolated = TRUE)) core <- load()
  if (is.null(core) && dir_ok && compile(isolated = FALSE)) core <- load()
  if (is.null(core)) {
    message("NOTE: could not compile or load code/lib/signal_counting.c (see ",
            file.path(build_dir, "compile_log.txt"), "). Using the pure-R ",
            "implementation instead, which gives the same results but is several ",
            "times slower for the largest networks.")
  }
  core
}

# ---- signal counts r_i ---------------------------------------------------------

# Pure-R reference implementation of Algorithm 1 (nb: list of neighbour vectors,
# each sorted increasingly)
signal_counts_R <- function(nb) {
  n <- length(nb)
  C <- matrix(0, n, n)
  r <- numeric(n)
  min_pivot <- Inf
  for (i in seq_len(n)) {
    ni <- nb[[i]]
    if (length(ni) == 0L) {
      r[i] <- 1
      C[i, i] <- 1
      next
    }
    rN <- r[ni]
    U <- chol(C[ni, ni, drop = FALSE])     # C[ni, ni] = U'U; pivots are diag(U)^2
    piv <- min(diag(U)^2)
    if (!is.finite(piv) || piv < MIN_PIVOT) {
      stop("numerical breakdown for agent ", i, ": a Cholesky pivot is below ", MIN_PIVOT)
    }
    min_pivot <- min(min_pivot, piv)
    beta <- backsolve(U, backsolve(U, rN, transpose = TRUE))
    r[i] <- 1 + sum(beta * rN)
    prev <- seq_len(i - 1L)
    ci <- as.vector(C[prev, ni, drop = FALSE] %*% beta)
    C[prev, i] <- ci
    C[i, prev] <- ci
    C[i, i] <- r[i]
  }
  attr(r, "min_pivot") <- min_pivot
  r
}

# r_i for every agent in an observation network given in CSR form. The result
# has attribute "min_pivot" (smallest Cholesky pivot; at least 1 in exact
# arithmetic, Inf if no agent has neighbours).
signal_counts <- function(csr, core = NULL) {
  if (!is.null(core)) {
    .Call(core$signal_counts, csr$n, csr$ptr, csr$idx)
  } else {
    signal_counts_R(csr_to_list(csr))
  }
}

# ---- indirect neighbourhoods ---------------------------------------------------

# |N^ind(i)|: number of agents reachable from i by a directed path
reachable_counts <- function(csr, core = NULL) {
  if (!is.null(core)) {
    .Call(core$reachable_counts, csr$n, csr$ptr, csr$idx)
  } else {
    g <- igraph::make_graph(
      rbind(rep.int(seq_len(csr$n), diff(csr$ptr)), csr$idx + 1L),
      n = csr$n, directed = TRUE
    )
    as.integer(igraph::ego_size(g, order = csr$n, mode = "out", mindist = 1))
  }
}

# ---- sanity checks ---------------------------------------------------------------

# Bounds that hold in every network: an agent who observes j can do at least
# as well as combining l_j with her own signal, so r_i >= 1 + r_j; and she can
# aggregate at most her own signal and those of agents reachable from her, so
# r_i <= 1 + |N^ind(i)|. Stops if either bound is violated.
check_signal_counts <- function(csr, r, reach, tol = 1e-8) {
  if (length(r) != csr$n || length(reach) != csr$n || !all(is.finite(r)) || anyNA(reach)) {
    stop("signal counts or reachability counts have the wrong length or non-finite values")
  }
  agent <- rep.int(seq_len(csr$n), diff(csr$ptr))
  lower <- rep(1, csr$n)
  if (length(agent)) {
    m <- tapply(r[csr$idx + 1L], agent, max)
    lower[as.integer(names(m))] <- 1 + m
  }
  ok <- all(r >= lower * (1 - tol)) && all(r <= (1 + reach) * (1 + tol))
  if (!ok) stop("signal counts violate 1 + max_j r_j <= r_i <= 1 + |N^ind(i)|")
  invisible(TRUE)
}
