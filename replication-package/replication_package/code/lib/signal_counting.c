/*
 * signal_counting.c -- compiled core for the collegiate Facebook application
 * (Appendix B of Dasaratha and He, "Aggregative Efficiency of Bayesian
 * Learning in Networks"). Built by code/lib/signal_counting.R with
 * R CMD SHLIB and -ffp-contract=off (no fused multiply-add; all arithmetic is
 * done in a fixed order with IEEE operations, so results should not depend on
 * the platform, though this was verified only on macOS arm64) and called with
 * .Call.
 *
 * Agents 0, ..., n-1 move in this order. The observation network is passed in
 * compressed sparse row form: agent i observes the agents
 *     idx[ptr[i]], ..., idx[ptr[i+1] - 1],
 * which must be 0-based, strictly increasing, and all smaller than i.
 *
 * fb_signal_counts(n, ptr, idx)
 *     Algorithm 1 of Appendix B.1. Keeps the conditional covariance matrix C
 *     of log-actions given omega = 1 under the normalisation sigma^2 = 4, so
 *     that Var(lambda_i) = 1 and r_i = Var(l_i) = C[i, i]. For agent i with
 *     neighbours N(i):
 *         beta_i = C[N(i), N(i)]^{-1} r_{N(i)},
 *         r_i    = 1 + beta_i' r_{N(i)},
 *         C[k, i] = C[i, k] = sum_{j in N(i)} beta_ij C[k, j]   for k < i.
 *     The linear system is solved by Cholesky factorisation. With neighbours
 *     in increasing order, the j-th Cholesky pivot is the conditional variance
 *     of the j-th neighbour's log-action given the earlier neighbours' actions,
 *     which is at least Var(lambda) = 1 in exact arithmetic (that neighbour's
 *     private signal is independent of everything earlier). A pivot below 0.5
 *     therefore signals numerical breakdown and stops the computation. Returns
 *     r (length n) with attribute "min_pivot", the smallest pivot encountered.
 *     Memory: one n x n double matrix (8 n^2 bytes).
 *
 * fb_reachable_counts(n, ptr, idx)
 *     |N^ind(i)|, the number of agents reachable from i by a directed path in
 *     the observation network (i -> j when i observes j), computed exactly by
 *     bitset dynamic programming over the DAG. Memory: about n^2 / 8 bytes.
 */
#define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>
#include <math.h>
#include <stdint.h>
#include <string.h>

#define MIN_PIVOT 0.5

#if defined(__GNUC__) || defined(__clang__)
#define POPCOUNT64(x) __builtin_popcountll(x)
#else
static int POPCOUNT64(uint64_t x)
{
    int c = 0;
    while (x) { x &= x - 1; c++; }
    return c;
}
#endif

/* Check the CSR arrays and return the largest number of neighbours. */
static int check_csr(int n, SEXP ptr_, SEXP idx_)
{
    if (n < 1) Rf_error("n must be positive");
    if (TYPEOF(ptr_) != INTSXP || TYPEOF(idx_) != INTSXP)
        Rf_error("ptr and idx must be integer vectors");
    if (XLENGTH(ptr_) != (R_xlen_t) n + 1) Rf_error("ptr must have length n + 1");
    const int *ptr = INTEGER(ptr_);
    const int *idx = INTEGER(idx_);
    const R_xlen_t nnz = XLENGTH(idx_);
    if (ptr[0] != 0 || (R_xlen_t) ptr[n] != nnz)
        Rf_error("ptr is inconsistent with idx");
    /* validate all pointers before reading idx, so malformed input cannot read out of bounds */
    for (int i = 0; i < n; i++)
        if (ptr[i + 1] < ptr[i] || (R_xlen_t) ptr[i + 1] > nnz)
            Rf_error("ptr must be non-decreasing and at most length(idx)");
    int dmax = 0;
    for (int i = 0; i < n; i++) {
        const int d = ptr[i + 1] - ptr[i];
        if (d > dmax) dmax = d;
        for (int k = ptr[i]; k < ptr[i + 1]; k++) {
            if (idx[k] < 0 || idx[k] >= i)
                Rf_error("agent %d cannot observe agent %d", i + 1, idx[k] + 1);
            if (k > ptr[i] && idx[k] <= idx[k - 1])
                Rf_error("neighbour list of agent %d is not strictly increasing", i + 1);
        }
    }
    return dmax;
}

/* In-place Cholesky factorisation A = L L' of a d x d symmetric matrix stored
 * column-major (lower triangle used and overwritten by L). Left-looking and
 * column-oriented, so the inner loops run over contiguous memory. Returns the
 * smallest pivot (diagonal of the Schur complements), or -1 if a pivot is
 * below MIN_PIVOT or not finite, in which case A is left partly factorised. */
static double chol_lower(double *A, int d)
{
    double min_piv = R_PosInf;
    for (int j = 0; j < d; j++) {
        double *Aj = A + (size_t) j * d;
        for (int k = 0; k < j; k++) {
            const double *Ak = A + (size_t) k * d;
            const double ljk = Ak[j];
            if (ljk != 0.0)
                for (int i = j; i < d; i++) Aj[i] -= Ak[i] * ljk;
        }
        const double piv = Aj[j];
        if (!R_FINITE(piv) || !(piv >= MIN_PIVOT)) return -1.0;
        if (piv < min_piv) min_piv = piv;
        const double s = sqrt(piv);
        Aj[j] = s;
        for (int i = j + 1; i < d; i++) Aj[i] /= s;
    }
    return min_piv;
}

/* Solve L L' x = b in place (x holds b on entry). */
static void chol_solve(const double *L, int d, double *x)
{
    for (int i = 0; i < d; i++) {            /* L y = b */
        const double *Li = L + (size_t) i * d;
        x[i] /= Li[i];
        const double xi = x[i];
        for (int k = i + 1; k < d; k++) x[k] -= Li[k] * xi;
    }
    for (int i = d - 1; i >= 0; i--) {       /* L' x = y */
        const double *Li = L + (size_t) i * d;
        double s = x[i];
        for (int k = i + 1; k < d; k++) s -= Li[k] * x[k];
        x[i] = s / Li[i];
    }
}

SEXP fb_signal_counts(SEXP n_, SEXP ptr_, SEXP idx_)
{
    const int n = Rf_asInteger(n_);
    const int dmax = check_csr(n, ptr_, idx_);
    const int *ptr = INTEGER(ptr_);
    const int *idx = INTEGER(idx_);
    const size_t nn = (size_t) n;

    /* C is an R vector, so it is released if an error or interrupt occurs.
     * It is not zero-initialised: when agent i is processed, every entry that
     * is read (C[m, j] for j in N(i), m < i) has already been written, because
     * column j rows 0..j-1 are written when agent j is processed, C[j, j] too,
     * and rows j+1..i-1 of column j are written as row entries when agents
     * j+1..i-1 are processed (as zeros for agents without neighbours). */
    SEXP C_ = PROTECT(Rf_allocVector(REALSXP, (R_xlen_t) nn * (R_xlen_t) nn));
    double *C = REAL(C_);
    SEXP out = PROTECT(Rf_allocVector(REALSXP, n));
    double *r = REAL(out);
    const size_t dm = dmax > 0 ? (size_t) dmax : 1;
    double *S = (double *) R_alloc(dm * dm, sizeof(double));
    double *rhs = (double *) R_alloc(dm, sizeof(double));
    double *beta = (double *) R_alloc(dm, sizeof(double));
    double *ci = (double *) R_alloc(nn, sizeof(double));
    double min_pivot = R_PosInf;

    for (int i = 0; i < n; i++) {
        const int d = ptr[i + 1] - ptr[i];
        const int *nb = idx + ptr[i];
        double *Ci = C + (size_t) i * nn;

        if (d == 0) {
            /* no observations: l_i = lambda_i, independent of all earlier agents */
            memset(Ci, 0, (size_t) i * sizeof(double));
            for (int m = 0; m < i; m++) C[(size_t) m * nn + i] = 0.0;
            Ci[i] = 1.0;
            r[i] = 1.0;
        } else {
            /* S = C[nb, nb], rhs = r[nb] = diag(S) */
            for (int b = 0; b < d; b++) {
                const double *col = C + (size_t) nb[b] * nn;
                double *Sb = S + (size_t) b * d;
                for (int a = 0; a < d; a++) Sb[a] = col[nb[a]];
                rhs[b] = Sb[b];
                beta[b] = Sb[b];
            }
            const double piv = chol_lower(S, d);
            if (piv < 0.0)
                Rf_error("numerical breakdown for agent %d: a Cholesky pivot of the neighbours' "
                         "covariance matrix is below %g (it is at least 1 in exact arithmetic)",
                         i + 1, MIN_PIVOT);
            if (piv < min_pivot) min_pivot = piv;
            chol_solve(S, d, beta);
            double ri = 1.0;
            for (int k = 0; k < d; k++) ri += beta[k] * rhs[k];

            /* ci[m] = Cov(l_i, l_m) = sum_k beta_k C[m, nb_k],  m < i */
            memset(ci, 0, (size_t) i * sizeof(double));
            for (int k = 0; k < d; k++) {
                const double *col = C + (size_t) nb[k] * nn;
                const double bk = beta[k];
                for (int m = 0; m < i; m++) ci[m] += bk * col[m];
            }
            memcpy(Ci, ci, (size_t) i * sizeof(double));             /* column i */
            for (int m = 0; m < i; m++) C[(size_t) m * nn + i] = ci[m]; /* row i */
            Ci[i] = ri;
            r[i] = ri;
        }
        if ((i & 63) == 0) R_CheckUserInterrupt();
    }

    SEXP mp = PROTECT(Rf_ScalarReal(min_pivot));
    Rf_setAttrib(out, Rf_install("min_pivot"), mp);
    UNPROTECT(3);
    return out;
}

SEXP fb_reachable_counts(SEXP n_, SEXP ptr_, SEXP idx_)
{
    const int n = Rf_asInteger(n_);
    check_csr(n, ptr_, idx_);
    const int *ptr = INTEGER(ptr_);
    const int *idx = INTEGER(idx_);
    const size_t words = ((size_t) n + 63) / 64;

    /* row i holds the bitset of agents reachable from i; only its first
     * (i >> 6) + 1 words are used, and they are zeroed before use */
    SEXP bits_ = PROTECT(Rf_allocVector(RAWSXP, (R_xlen_t) (words * (size_t) n * sizeof(uint64_t))));
    uint64_t *bits = (uint64_t *) RAW(bits_);
    SEXP out = PROTECT(Rf_allocVector(INTSXP, n));
    int *count = INTEGER(out);

    for (int i = 0; i < n; i++) {
        uint64_t *Ri = bits + (size_t) i * words;
        const size_t wi = (size_t) (i >> 6) + 1;
        memset(Ri, 0, wi * sizeof(uint64_t));
        for (int k = ptr[i]; k < ptr[i + 1]; k++) {
            const int j = idx[k];
            const uint64_t *Rj = bits + (size_t) j * words;
            const size_t wj = (size_t) (j >> 6) + 1;
            for (size_t w = 0; w < wj; w++) Ri[w] |= Rj[w];
            Ri[j >> 6] |= (uint64_t) 1 << (j & 63);
        }
        int c = 0;
        for (size_t w = 0; w < wi; w++) c += POPCOUNT64(Ri[w]);
        count[i] = c;
        if ((i & 1023) == 0) R_CheckUserInterrupt();
    }
    UNPROTECT(2);
    return out;
}
