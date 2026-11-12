# Signal counts in generations networks (Section 4 of the paper).
#
# Agents move in generations of size K; the agent in position k of generation
# t >= 2 observes the positions psi[[k]] of generation t - 1.

# ---- maximal generations network (Figure 4) ---------------------------------

# Every agent in generation t >= 2 observes all K agents of generation t - 1.
# By symmetry all agents of a generation put equal weight on their neighbours,
# so we only need to track the conditional mean and variance of the sum of a
# generation's log-actions (var_signal = sigma^2; r_i does not depend on it).
# Returns r_i for agents 1, ..., K * n_gen.
maximal_generations_ri <- function(K, n_gen, var_signal = 10) {
  r_gen <- numeric(n_gen)
  r_gen[1] <- 1
  mu_sum <- K * (2 / var_signal)   # E[sum of log-actions | omega = 1]
  var_sum <- K * (4 / var_signal)  # Var[sum of log-actions | omega = 1]
  if (n_gen >= 2) {
    for (t in 2:n_gen) {
      r_gen[t] <- (2 * mu_sum^2 / var_sum) / (2 / var_signal) + 1
      new_mu <- 2 * K * (mu_sum^2 / var_sum + 1 / var_signal)
      new_var <- K * (4 * mu_sum^2 / var_sum + 4 / var_signal) +
        K * (K - 1) * 4 * mu_sum^2 / var_sum
      mu_sum <- new_mu
      var_sum <- new_var
    }
  }
  rep(r_gen, each = K)
}

# ---- generations networks with fixed observation sets (Figure 5) ------------

# Observation sets: positions 1..K/2 observe d1 random positions of the
# previous generation and positions K/2+1..K observe d2 (sampled without
# replacement, independently across positions).
draw_observation_sets <- function(K, d1, d2) {
  psi <- vector("list", K)
  half <- K / 2
  for (k in 1:K) {
    dk <- if (k <= half) d1 else d2
    psi[[k]] <- sample.int(K, size = dk, replace = FALSE)
  }
  psi
}

# r_{t,k} for generations t = 1..G and positions k = 1..K (a G x K matrix),
# using the covariance recursion V_t = I + B_t V_{t-1} B_t' (sigma^2 = 4).
# Each neighbour covariance matrix V_{t-1}[psi_k, psi_k] is the identity
# (the neighbours' own private signals) plus a positive semidefinite matrix,
# so its eigenvalues are at least 1 and its condition number is at most its
# trace, the sum of the neighbours' r's (a few thousand here).
generations_ri <- function(K, G, psi) {
  V_prev <- diag(1, K, K)
  r_out <- matrix(NA_real_, nrow = G, ncol = K)
  r_out[1, ] <- diag(V_prev)
  if (G == 1) return(r_out)
  for (t in 2:G) {
    B <- matrix(0, nrow = K, ncol = K)
    for (k in 1:K) {
      nb <- psi[[k]]
      Sigma <- V_prev[nb, nb, drop = FALSE]
      B[k, nb] <- solve(Sigma, diag(Sigma))
    }
    V_t <- diag(1, K, K) + B %*% V_prev %*% t(B)
    V_t <- (V_t + t(V_t)) / 2  # remove rounding asymmetry
    r_out[t, ] <- diag(V_t)
    V_prev <- V_t
  }
  r_out
}

# The same generations network written out agent by agent (agent (t-1)K + k),
# e.g. to cross-check generations_ri() against Algorithm 1.
generations_neighbour_list <- function(K, G, psi) {
  nb <- vector("list", K * G)
  for (t in seq_len(G)) {
    for (k in seq_len(K)) {
      nb[[(t - 1) * K + k]] <- if (t == 1) integer(0) else as.integer((t - 2) * K + psi[[k]])
    }
  }
  nb
}
