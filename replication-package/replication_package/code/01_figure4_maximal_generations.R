# Figure 4 (Section 4.1): number of signals aggregated r_i by agent i in
# maximal generations networks with generation sizes K = 2, 3, 4, 5, and the
# in-text claim that r_i is strictly decreasing in K for all later agents
# (checked numerically for agents up to 6000; Corollary 1 gives the limit).
# Deterministic; runs in about a second.
source(file.path("code", "lib", "utils.R"))
source(file.path(paths$lib, "generations.R"))

Ks <- 2:5
up_to <- 40       # agents shown in the figure
n_check <- 6000   # agents used to check the comparative statics in K

r <- sapply(Ks, function(K) maximal_generations_ri(K, ceiling(n_check / K))[seq_len(n_check)])
colnames(r) <- paste0("K", Ks)
write.csv(data.frame(agent = seq_len(up_to), r[seq_len(up_to), ]),
          file.path(paths$intermediate, "figure4_ri.csv"), row.names = FALSE)

# ---- figure ------------------------------------------------------------------
cols <- c("#D55E00", "#0072B2", "#000000", "#E69F00")
ltys <- c(6, 2, 1, 4)
pdf(file.path(paths$figures, "gen_size_K_speed_bw.pdf"), width = 7, height = 5)
par(bg = NA)
plot(seq_len(up_to), r[seq_len(up_to), 1], type = "l",
     main = "Aggregative Efficiency and Generation Size K",
     xlab = "agent", xlim = c(1, 40),
     ylab = "number of signals aggregated",
     col = cols[1], lty = ltys[1], lwd = 2,
     cex.main = 1.3, cex.lab = 1.1, cex.axis = 1.1)
for (k in 2:length(Ks)) {
  lines(seq_len(up_to), r[seq_len(up_to), k], col = cols[k], lty = ltys[k], lwd = 2)
}
legend("topleft", bty = "n", legend = paste("K =", Ks), lty = ltys, lwd = 3, col = cols)
invisible(dev.off())

# ---- in-text numbers -----------------------------------------------------------
strictly_decreasing <- apply(r, 1, function(x) all(diff(x) < 0))
first_agent <- max(which(!strictly_decreasing)) + 1
nums <- write_numbers(list(
  list("Section 4.1 (text before Figure 4)",
       sprintf("smallest i such that r_j is strictly decreasing in K in {2,3,4,5} for every agent j = i, ..., %d", n_check),
       first_agent),
  list("Section 4.1 (text before Figure 4)",
       "agents j < that i at which the ordering fails",
       paste(which(!strictly_decreasing), collapse = " ")),
  list("Corollary 1 (check)", "r_i(K=2) - r_{i-K}(K=2) for the last agent checked (limit 2 - 1/K = 1.5)",
       sprintf("%.6f", r[n_check, 1] - r[n_check - 2, 1]))
), "figure4_numbers.csv")
print(nums, right = FALSE)
log_msg("Figure 4 written to ", file.path(paths$figures, "gen_size_K_speed_bw.pdf"))
