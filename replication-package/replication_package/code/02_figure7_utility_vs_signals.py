"""Figure 7 (Section 6): expected utility as a function of the number of
signals r_i, for signal variances sigma^2 in {0.5, 2, 5, 10}.

Agent i's log-action is distributed N(2 r / sigma^2, 4 r / sigma^2) in state
omega = 1 (Definition 1), her action is a = 1 / (1 + exp(-l)), and her utility
is -(a - omega)^2. By symmetry between the states, expected utility is
    EU(r) = -E[(1 - a)^2 | omega = 1],
computed here by adaptive quadrature over a standard normal variable z,
split at the point where the log-action is zero (the integrand is largest
below it). EU(0) = -1/4. Deterministic.

Usage: python3 code/02_figure7_utility_vs_signals.py
Writes output/figures/utilityvssignalcounts.png and
output/intermediate/figure7_expected_utility.csv.
"""
from pathlib import Path

import numpy as np
from scipy import integrate, special

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

SIGMA2 = [0.5, 2, 5, 10]
STYLES = [("-", "tab:blue"), ("--", "tab:red"), ("-.", "tab:green"), (":", "tab:purple")]
R_GRID = np.linspace(0.0, 10.0, 1001)


def expected_utility(r, sigma2):
    """-E[(1 - a)^2 | omega = 1] when the log-action is N(2r/sigma2, 4r/sigma2)."""
    if r == 0:
        return -0.25
    mean = 2.0 * r / sigma2
    sd = np.sqrt(4.0 * r / sigma2)

    def integrand(z):
        return special.expit(-(mean + sd * z)) ** 2 * np.exp(-0.5 * z * z) / np.sqrt(2.0 * np.pi)

    z0 = -mean / sd
    total, total_err = 0.0, 0.0
    for lo, hi in ((-np.inf, z0), (z0, np.inf)):
        value, err = integrate.quad(integrand, lo, hi, epsabs=1e-14, epsrel=1e-12, limit=200)
        total += value
        total_err += err
    if total_err > 1e-10:
        raise RuntimeError(f"quadrature error {total_err:g} too large at r={r}, sigma2={sigma2}")
    return -total


def main():
    root = Path(__file__).resolve().parents[1]
    fig_dir = root / "output" / "figures"
    tab_dir = root / "output" / "intermediate"
    fig_dir.mkdir(parents=True, exist_ok=True)
    tab_dir.mkdir(parents=True, exist_ok=True)

    eu = {s2: np.array([expected_utility(r, s2) for r in R_GRID]) for s2 in SIGMA2}

    header = "r," + ",".join(f"sigma2_{s2:g}" for s2 in SIGMA2)
    table = np.column_stack([R_GRID] + [eu[s2] for s2 in SIGMA2])
    np.savetxt(tab_dir / "figure7_expected_utility.csv", table, delimiter=",",
               header=header, comments="", fmt="%.10g")

    fig, ax = plt.subplots(figsize=(9, 5.5))
    for s2, (ls, color) in zip(SIGMA2, STYLES):
        ax.plot(R_GRID, eu[s2], linestyle=ls, color=color, linewidth=2.25,
                label=rf"$\sigma^2 = {s2:g}$")
    ax.axhline(0, color="gray", linewidth=0.6)
    ax.set_xlim(0, 10)
    ax.set_xlabel(r"$r_i$", fontsize=18)
    ax.set_ylabel("Expected Utility", fontsize=18)
    ax.tick_params(labelsize=14)
    ax.grid(True, alpha=0.3)
    ax.legend(fontsize=15, loc="lower right")
    fig.tight_layout()
    fig.savefig(fig_dir / "utilityvssignalcounts.png", dpi=150)
    print("Figure 7 written to", fig_dir / "utilityvssignalcounts.png")


if __name__ == "__main__":
    main()
