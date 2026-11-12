# Figure 5 (Section 4.3): signal aggregation by generation in random
# generations networks with K = 100 positions. In each of 1000 replications,
# position k's observation set (d_k positions of the previous generation,
# sampled without replacement) is drawn once and kept for all generations;
# we compute r for every position up to generation 100 and record the largest
# one-generation increase across positions. Panel (a): d_k = d for all k.
# Panel (b): d_k = d1 for positions 1-50 and d2 for positions 51-100.
# Also computes the in-text claims about the generation after which no
# position gains more than 2 signals in a generation.
# Runtime: about 2.5 minutes with 8 workers (the 8 configurations run in
# parallel); see README.txt for single-core times.
source(file.path("code", "lib", "utils.R"))
source(file.path(paths$lib, "generations.R"))

K <- 100L
G <- 100L
reps <- config$random_regular_reps
pairs <- list(
  a = list(c(2, 2), c(4, 4), c(8, 8), c(16, 16)),
  b = list(c(2, 4), c(2, 8), c(4, 8), c(4, 16))
)
all_pairs <- c(pairs$a, pairs$b)
streams <- rng_streams(config$random_regular_seed, length(all_pairs))

# max_gain[rep, t - 1] = max over positions k of r_{t,k} - r_{t-1,k}, t = 2..G
simulate_pair <- function(k) {
  d <- all_pairs[[k]]
  use_rng_state(streams[[k]][[1]])
  max_gain <- matrix(NA_real_, nrow = reps, ncol = G - 1)
  for (rr in seq_len(reps)) {
    psi <- draw_observation_sets(K, d[1], d[2])
    r <- generations_ri(K, G, psi)
    max_gain[rr, ] <- apply(r[-1, , drop = FALSE] - r[-G, , drop = FALSE], 1, max)
  }
  max_gain
}

log_msg("Simulating ", length(all_pairs), " degree configurations x ", reps,
        " replications on ", effective_cores(), " core(s)")
t0 <- proc.time()[["elapsed"]]
gains <- run_jobs(seq_along(all_pairs), simulate_pair, n_cores = config$n_cores)
log_msg(sprintf("Done in %.1f minutes", (proc.time()[["elapsed"]] - t0) / 60))
names(gains) <- vapply(all_pairs, function(d) sprintf("d1=%d,d2=%d", d[1], d[2]), "")
saveRDS(list(K = K, G = G, reps = reps, pairs = all_pairs, seed = config$random_regular_seed,
             max_gain = gains),
        file.path(paths$intermediate, "figure5_max_gain.rds"))

summarise <- function(mg) {
  list(t = 2:G, mean = colMeans(mg), min = apply(mg, 2, min), max = apply(mg, 2, max))
}
summ <- lapply(gains, summarise)
write.csv(do.call(rbind, lapply(seq_along(summ), function(i) {
  data.frame(configuration = names(summ)[i], generation = summ[[i]]$t,
             mean = summ[[i]]$mean, min = summ[[i]]$min, max = summ[[i]]$max)
})), file.path(paths$intermediate, "figure5_summary.csv"), row.names = FALSE)

# ---- figures (generations 2-31; the y-axis covers all generations) ----------
plot_gains <- function(file, S_list, main, legend_labels) {
  band_colors <- c("firebrick3", "steelblue", "goldenrod2", "mediumpurple1")
  line_colors <- c("darkred", "navy", "darkgoldenrod3", "purple4")
  ltys <- c(1, 2, 4, 5)
  lwd <- 2
  idx <- 1:30
  pdf(file, width = 7, height = 5)
  par(mar = c(4.5, 4.5, 3.5, 1.5), mgp = c(2.3, 0.8, 0), las = 1)
  y_lo <- min(sapply(S_list, function(S) min(S$min)))
  y_hi <- max(sapply(S_list, function(S) max(S$max)))
  plot(S_list[[1]]$t[idx], S_list[[1]]$mean[idx], type = "n",
       xlab = "Generation", ylab = "Max gain in signals across all positions",
       ylim = c(y_lo, y_hi), main = main)
  for (i in seq_along(S_list)) {
    S <- S_list[[i]]
    polygon(c(S$t[idx], rev(S$t[idx])), c(S$max[idx], rev(S$min[idx])),
            col = adjustcolor(band_colors[i], alpha.f = 0.15), border = NA)
    lines(S$t[idx], S$mean[idx], col = line_colors[i], lwd = lwd, lty = ltys[i])
  }
  legend("topright", legend = legend_labels, col = line_colors, lwd = lwd, lty = ltys,
         bty = "n", cex = 0.9)
  invisible(dev.off())
}
plot_gains(file.path(paths$figures, "gains_regular_d_bw.pdf"), summ[1:4],
           main = expression("Signal Aggregation in Random " * italic(d) * "-Regular Networks"),
           legend_labels = sprintf("d = %d", sapply(pairs$a, `[`, 1)))
plot_gains(file.path(paths$figures, "gains_regular_d1d2_bw.pdf"), summ[5:8],
           main = expression("Signal Aggregation in Random Networks with Degrees (" * d[1] * ", " * d[2] * ")"),
           legend_labels = as.expression(lapply(pairs$b, function(d) {
             bquote(d[1] == .(d[1]) ~ ", " ~ d[2] == .(d[2]))
           })))

# ---- in-text numbers -----------------------------------------------------------
# First generation T such that, in every replication and configuration of the
# panel, no position gains more than 2 signals in any simulated generation
# t = T, ..., G (NA if a gain above 2 occurs in the last generation G).
cutoff <- function(S_list) {
  worst <- do.call(pmax, lapply(S_list, function(S) S$max))
  above <- which(worst > 2)
  if (length(above) == 0) return(2L)
  last <- S_list[[1]]$t[max(above)]
  if (last == G) NA_integer_ else last + 1L
}
late <- function(S_list, from = 50) {
  range(unlist(lapply(S_list, function(S) S$max[S$t >= from])))
}
fmt <- function(x) sprintf("%.4f", x)
nums <- write_numbers(list(
  list("Section 4.3", "positions per generation K; generations; replications", sprintf("%d; %d; %d", K, G, reps)),
  list("Section 4.3 (Figure 5a text)", "first generation T such that no position gains > 2 signals in any generation t = T, ..., 100, in any replication (d = 2, 4, 8, 16)", cutoff(summ[1:4])),
  list("Section 4.3 (Figure 5b text)", "first generation T such that no position gains > 2 signals in any generation t = T, ..., 100, in any replication ((d1,d2) = (2,4), (2,8), (4,8), (4,16))", cutoff(summ[5:8])),
  list("Section 4.3", "same, by configuration", paste(sprintf("%s: %s", names(summ), sapply(summ, function(S) cutoff(list(S)))), collapse = "; ")),
  list("Section 4.3", "range of the largest one-generation gain over all replications, generations 50-100, panel (a)", paste(fmt(late(summ[1:4])), collapse = " to ")),
  list("Section 4.3", "range of the largest one-generation gain over all replications, generations 50-100, panel (b)", paste(fmt(late(summ[5:8])), collapse = " to ")),
  list("Section 4.3", "average largest gain in generation 30, panel (a) (d = 2, 4, 8, 16)", paste(fmt(sapply(summ[1:4], function(S) S$mean[S$t == 30])), collapse = ", ")),
  list("Section 4.3", "average largest gain in generation 30, panel (b)", paste(fmt(sapply(summ[5:8], function(S) S$mean[S$t == 30])), collapse = ", ")),
  list("Figure 5", "generation with the highest average largest gain, per configuration",
       paste(sprintf("%s: t=%d", names(summ), sapply(summ, function(S) S$t[which.max(S$mean)])), collapse = "; "))
), "figure5_numbers.csv")
print(nums, right = FALSE)
log_msg("Figure 5 written to ", paths$figures)
