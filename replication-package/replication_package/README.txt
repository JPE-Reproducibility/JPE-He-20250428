==============================================================================
Replication package for
"Aggregative Efficiency of Bayesian Learning in Networks"
Krishna Dasaratha and Kevin He, Journal of Political Economy
==============================================================================


1. Overview
===========

The paper is theoretical. This package reproduces all of its computed
exhibits:

Exhibit                         Content                             Randomness
------------------------------  ----------------------------------  ----------
Figure 4 (Section 4.1) and the  number of signals aggregated in     none
related in-text claim           maximal generations networks

Figure 5 (Section 4.3) and two  simulations of random generations   seeded
in-text claims                  networks

Figure 7 (Section 6)            expected utility as a function of   none
                                the number of signals

Table 1, Figure 8 and in-text   rational sequential learning on     seeded
numbers in Appendix B.2         100 collegiate Facebook networks
(including footnote 22),
Section 3.4 and the
Introduction

Figures 1, 2, 3 and 6 are diagrams and involve no computation.

The code is written in R (with a small C routine that R compiles
automatically) and Python. The only data, the Facebook100 data set, are
publicly available but are not redistributed here. Once the data file has been
downloaded (free; about a minute), the master script run_all.R produces all of
these exhibits from the raw data, in about 4.5 hours on the authors' machine
with 8 parallel workers (about 18 hours with a single worker). Almost all of
this time is spent on 1000 random orderings of each of the 100 Facebook
networks (step 05). The package therefore also includes the results of that
step, so that all exhibits can be checked in a few minutes (see "Partial
reproduction" below); with 10 orderings per network (FACEBOOK_ORDERINGS=10), a
complete run takes 6 minutes and gives results close to those in the paper
(but replaces the included results of step 05). The folder reference_output/
contains the figures, tables and numbers from the authors' run, for comparison
(see "Comparison with the authors' results" below).


2. Data availability and provenance statements
==============================================

2.1 Summary of availability
---------------------------

[x] All data are publicly available (through an archived copy; see below).
[ ] Some data cannot be made publicly available.
[ ] No data can be made publicly available.

2.2 Details on each data source
-------------------------------

Facebook100 (Traud, Mucha, and Porter 2011, 2012). An anonymized snapshot,
from a day in September 2005, of the Facebook friendship networks within each
of the first 100 US colleges and universities on Facebook, provided to the
original authors by Facebook. Each school's file contains the (undirected)
friendship adjacency matrix and, for each user, a student/faculty status flag,
gender, major, second major, dorm, class year and high school, coded as
integers (0 = missing).

- Version and source: The data were released by Amanda L. Traud, Peter J.
  Mucha and Mason A. Porter as the file facebook100.zip, with a readme dated
  February 11, 2011. An archived copy is publicly available from the Internet
  Archive at

      https://archive.org/details/oxford-2005-facebook-matrix

  with a direct link to the file at

      https://archive.org/download/oxford-2005-facebook-matrix/facebook100.zip

- Access: Free, with no registration. The file is 207 MB (206,740,075 bytes).
  Save it as data/raw/facebook100.zip. The file has MD5
  a7687ec2362d369803a3463e2884dbe8 and SHA-1
  7024eb583b1fcab08754e9b74826a64b92b33c99, the values the Internet Archive
  lists for its copy; code/04_facebook_extract.py verifies the checksums and
  size and stops if they do not match. The authors first obtained the file on
  November 17, 2025, and downloaded it again to verify this package on
  October 19, 2026.

- Format: The 100 school files are MATLAB .mat files (version 5 format,
  readable with open-source software such as Python's scipy).
  code/04_facebook_extract.py converts the data used in the paper to plain CSV
  files (see the dataset list).

- The zip file also contains the original authors' readme
  (facebook100_readme_021011.txt), which asks users to cite Traud, Mucha, and
  Porter (2012) and Traud, Kelsic, Mucha, and Porter (2011), and a copy of the
  first paper.


3. Dataset list
===============

data/raw/facebook100.zip
    Source:   Facebook100 (see above)
    Notes:    100 school files <school>.mat (variables A and local_info),
              schools.mat, readme, paper
    Provided: No; download as described

data/derived/facebook100/<school>_students.csv
    Source:   created by code/04_facebook_extract.py
    Notes:    one row per kept student, with columns student (1..N, order in
              the raw file) and class_year
    Provided: No; created by the code

data/derived/facebook100/<school>_edges.csv
    Source:   created by code/04_facebook_extract.py
    Notes:    one row per friendship among kept students, with columns i and j
              (student numbers, i < j)
    Provided: No; created by the code

data/derived/facebook100/schools.csv
    Source:   created by code/04_facebook_extract.py
    Notes:    per school: name, file name stem, users in the raw data, kept
              students, friendships, students per class year
    Provided: No; created by the code

data/derived/facebook100/extraction_info.csv
    Source:   created by code/04_facebook_extract.py
    Notes:    class years kept, MD5 checksum of the input file, number of
              schools
    Provided: No; created by the code

output/intermediate/facebook_orderings.csv
    Source:   created by code/05_facebook_random_orderings.R
    Notes:    intermediate results: one row per school and random ordering,
              with columns school, ordering, n (students), frac_potential and
              frac_reachable (the two measures of Appendix B.2),
              n_nonempty_indirect (students with a nonempty indirect
              neighbourhood) and min_pivot (smallest Cholesky pivot, a
              numerical check)
    Provided: Yes

output/intermediate/facebook_orderings_info.csv
    Source:   created by code/05_facebook_random_orderings.R
    Notes:    settings behind the file above, in columns facebook_seed,
              facebook_orderings, first_year and last_year (class years kept),
              implementation (compiled or pure-R), code_md5 (MD5 checksums of
              code/lib/signal_counting.c, code/lib/signal_counting.R,
              code/lib/utils.R and code/05_facebook_random_orderings.R,
              separated by semicolons) and data_md5 (MD5 checksums of each
              school's _students.csv and _edges.csv files, schools in
              alphabetical order of their names in the C locale)
    Provided: Yes

reference_output/
    Source:   created by the code in the authors' run
    Notes:    the authors' results, for comparison only (not read by the
              code): the files in output/figures/, output/tables/ and
              output/numbers/ and the data behind Figures 4, 5 and 7
              (output/intermediate/figure4_ri.csv, figure5_summary.csv,
              figure7_expected_utility.csv), under the same names;
              tables/facebook_results_by_school.csv has, for each school, the
              averages and standard deviations of the two measures across
              orderings and the number of students, average degree and
              clustering coefficients
    Provided: Yes

Kept students are users with status flag 1 (student) and class year 2006 to
2009. The derived files take about 10 seconds to create. Schools are
identified as in the raw data, by a short name followed by Facebook's school
number from 1 to 100 (e.g. Caltech36); in file names, spaces are replaced by
underscores (Johns_Hopkins55, Notre_Dame57). The paper refers to Caltech36 as
Caltech, Penn94 as Penn State University, Mich67 as Michigan Technological
University, Harvard1 as Harvard University and Haverford76 as Haverford
College.


4. Computational requirements
=============================

4.1 Software requirements
-------------------------

- R, tested with R 4.6.0, with the package igraph (tested with 2.3.4;
  install.packages("igraph"); on Linux, installing it from source needs a C++
  compiler and, for full functionality, the GLPK, GMP and libxml2 development
  libraries; a binary repository such as Posit Package Manager avoids this)
  and the base packages parallel, tools and utils.

- A C compiler set up for R, strongly recommended: Xcode Command Line Tools on
  macOS (xcode-select --install), the Rtools version matching your R version
  on Windows, or gcc and make on Linux (e.g. the Debian/Ubuntu package
  r-base-dev, which also installs build-essential). code/lib/signal_counting.c
  is compiled automatically on first use (log in
  output/build/compile_log.txt), with R's default compiler settings plus
  -ffp-contract=off, first ignoring and, if that fails, using a personal
  ~/.R/Makevars. Without a compiler, the scripts use an equivalent pure-R
  implementation, which agrees with the compiled one up to rounding error
  (relative differences below 1e-8 in the tests) but is much slower in
  step 05: for the largest school, about 33 seconds per ordering instead of 4,
  so that step 05 would take days.

- Python, tested with Python 3.14.5, numpy 2.5.2, scipy 1.18.0 and matplotlib
  3.10.8 (pip install -r requirements.txt). These pinned versions need Python
  3.12 or later; with an older Python, install the most recent versions of the
  three packages available for it (the code was tested only with the versions
  above).

run_all.R checks for igraph, Python and its packages and the data file before
it starts, and records the software and hardware used in
output/logs/environment.txt.

4.2 Controlled randomness
-------------------------

The random draws behind the exhibits use R's L'Ecuyer-CMRG generator with
seeds set in config.R, through rng_streams() in code/lib/utils.R:

- Figure 5: seed random_regular_seed = 20261019. Each of the 8 degree
  configurations uses its own stream (code/03_figure5_random_regular.R).

- Facebook application: seed facebook_seed = 20261020. The school with
  Facebook number s (the number at the end of its name) uses stream s, and its
  k-th random ordering uses substream k (code/05_facebook_random_orderings.R).

Because each job has its own stream, results do not depend on the number of
parallel workers, on the order in which parallel jobs finish or on which
schools are run, and increasing the number of orderings leaves the earlier
orderings unchanged. The tests in step 00 use their own fixed seeds. Nothing
else is random. Rerunning the package with run_all.R reproduces all figures,
tables, numbers and intermediate results exactly on the same machine (apart
from the creation dates embedded in the PDF figures; the logs record times).
On other machines, intermediate floating-point results may differ in the last
digits (for example through a different linear-algebra library in step 03, or
because R averages in extended precision on x86-64 processors), but no
reported number should change: every number reported in the paper is at least
9e-7 away from a rounding boundary, and every one-generation gain behind the
thresholds in Section 4.3 differs from 2 by at least 3e-5. run_all.R limits
multithreaded math libraries (OpenBLAS, MKL, Accelerate) to one thread per
process, since the scripts already run several processes in parallel.

4.3 Memory, runtime and storage requirements
--------------------------------------------

The package was last run on a MacBook Pro with an Apple M5 Pro processor
(15 cores) and 48 GB of memory, running macOS 27.0.1, with R 4.6.0 and Apple
clang 21.0.0 (no GPU is used), starting from an empty output/ folder and using
the compiled implementation. Measured wall-clock times:

Step  Program                               8 workers    1 worker
                                            (default)    (N_CORES=1)
----  ------------------------------------  -----------  -----------------
00    tests of the signal-counting code     2 seconds    2 seconds
01    Figure 4                              1 second     1 second
02    Figure 7                              1 second     1 second
03    Figure 5                              2.3 minutes  13.1 minutes
04    Facebook data extraction              10 seconds   10 seconds
05    Facebook random orderings (1000 per   4.5 hours    about 17.5 hours
      school)                                            (estimated)
06    Table 1, Figure 8, Facebook numbers   10 seconds   9 seconds
      total                                 4.5 hours    about 18 hours

The single-worker times for steps 00 to 04 and 06 were measured; for step 05,
the single-worker time is extrapolated from a run with 10 orderings per
school, which took 10.5 minutes with one worker and 3.0 minutes with
8 workers. Step 05 scales linearly in the number of orderings per school. With
10 orderings per school, the runs with 8 workers and with 1 worker produced
identical outputs. Its memory use is dominated by one N x N matrix per running
job, about 8.2 N^2 bytes for a school with N students: the largest school
(Penn94, N = 26,748) needs about 6 GB (measured peak: 6.1 GB), 90 of the 100
schools need under 2 GB and 77 under 1 GB. A job is started only if the jobs
running at the same time fit into the memory budget mem_budget_gb in config.R,
by default 60% of physical memory; a single job larger than the budget runs
alone. At least 8 GB of memory is needed with one worker, and 16 GB is
recommended. Disk space: 0.2 GB for the raw data, 0.3 GB for the derived data
(twice that briefly while step 04 runs), under 0.1 GB for outputs, plus the R
and Python installations.


5. Description of programs
==========================

run_all.R
    master script; checks requirements, records the environment, runs steps 00
    to 06 below in separate processes, logs each to output/logs/ and appends
    timings to output/logs/run_all_timings.csv

config.R
    settings (see below)

code/lib/signal_counting.R, code/lib/signal_counting.c
    Algorithm 1 of Appendix B.1 (signal counts r_i in any network where agents
    move in order) and exact indirect-neighbourhood sizes; compiled C version
    and pure-R reference version

code/lib/generations.R
    signal counts in generations networks: closed form for maximal generations
    networks (Figure 4) and the covariance recursion for random generations
    networks (Figure 5)

code/lib/utils.R
    paths, logging, recording of in-text numbers, random-number streams,
    memory-aware parallel job scheduler

code/tests/test_signal_counting.R (step 00)
    checks the code against results in the paper (Examples 1 and 2, the closed
    form behind Figure 4), checks that the compiled and pure-R versions agree
    (skipped if no compiler is available), tests the helper functions, and
    checks that the package's code and documentation files are plain ASCII

code/01_figure4_maximal_generations.R
    Figure 4 and the in-text claim that r_i decreases in K

code/02_figure7_utility_vs_signals.py
    Figure 7

code/03_figure5_random_regular.R
    Figure 5 and the in-text claims of Section 4.3

code/04_facebook_extract.py
    checks facebook100.zip and creates the derived data

code/05_facebook_random_orderings.R
    for every school and random ordering, r_i for every student and the two
    efficiency measures of Appendix B.2

code/06_facebook_results.R
    Table 1, Figure 8 and the in-text numbers of Appendix B.2 (including
    footnote 22), Section 3.4 and the Introduction

Steps 05 and 06 use the output of step 04, and step 06 also that of step 05;
the other steps are independent.

Settings in config.R (environment variables that override them in brackets):

Setting                Default                Meaning
---------------------  ---------------------  --------------------------------
python [PYTHON]        python3 (python on     Python interpreter with the
                       Windows)               packages in requirements.txt

n_cores [N_CORES]      number of physical     parallel worker processes (macOS
                       cores minus 1, at      and Linux only)
                       most 8

mem_budget_gb          NA = 60% of physical   memory budget in GB for
                       memory (8 GB if it     simultaneous Facebook jobs; set
                       cannot be determined)  it explicitly in a container,
                                              where the detected memory may be
                                              the host's

use_compiled           TRUE                   use the compiled implementation
                                              if a C compiler is available

random_regular_reps    1000                   replications per configuration
[RANDOM_REGULAR_REPS]                         in Figure 5

random_regular_seed    20261019               seed for Figure 5

facebook_orderings     1000                   random orderings per school
[FACEBOOK_ORDERINGS]

facebook_seed          20261020               seed for the Facebook orderings

facebook_cohorts       2006:2009              class years kept

Runs with fewer replications or orderings than the defaults are useful as
quick tests but do not reproduce the paper; like any run of step 05, they
replace the included results of step 05 (see "Partial reproduction"). For
example, the following quick test takes about 2 minutes:

    N_CORES=1 FACEBOOK_ORDERINGS=1 RANDOM_REGULAR_REPS=20 Rscript run_all.R

Step 05 splits the work into jobs of one school and up to 50 consecutive
orderings (this affects only how the work is scheduled, not the results). It
saves each job's results in output/intermediate/facebook_orderings/ (R data
files) and, if interrupted and rerun, reuses those whose orderings, seed,
school data files, class years, implementation (compiled or pure R) and code
(signal_counting.c, signal_counting.R, utils.R and step 05 itself) are
unchanged. To force a complete recomputation of step 05 (for example after
moving a partly run package to a different machine), delete the folder
output/intermediate/facebook_orderings/.


6. Instructions to replicators
==============================

1. Download facebook100.zip (see "Details on each data source") and save it,
   still zipped, as data/raw/facebook100.zip, for example from the package
   root with

       curl -L -o data/raw/facebook100.zip https://archive.org/download/oxford-2005-facebook-matrix/facebook100.zip

   (Some browsers, such as Safari, unpack downloaded zip files by default; the
   code needs the zip file itself.)

2. Install R and the package igraph, a C compiler for R if possible, and
   Python with the packages in requirements.txt, for example in a virtual
   environment:

   macOS/Linux:
       python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
   Windows:
       python -m venv .venv
       .venv\Scripts\pip install -r requirements.txt

3. Optionally edit config.R (see the settings table above).

4. From the root of the package (the folder containing this README), in a
   terminal, run

   macOS/Linux:
       PYTHON=.venv/bin/python Rscript run_all.R
   Windows (Command Prompt):
       set PYTHON=.venv\Scripts\python.exe
       Rscript run_all.R

   On Windows, if Rscript is not on the path, use its full path, e.g.

       "C:\Program Files\R\R-4.6.0\bin\Rscript.exe" run_all.R

   Individual steps can be run with, e.g.,

       Rscript run_all.R 05 06

   run_all.R can also be run with source("run_all.R") from an R session such
   as RStudio whose working directory is the package root, since it starts
   each step as a separate process; a step script can also be run on its own
   from the package root (e.g. Rscript code/06_facebook_results.R, or inside
   RStudio, where it then uses a single worker), but then multithreaded math
   libraries are not limited to one thread (see "Controlled randomness").

5. Outputs are written to output/figures/, output/tables/ and output/numbers/;
   logs, timings and the environment record to output/logs/. The authors'
   versions of the outputs are in reference_output/ (see "Comparison with the
   authors' results").

Run the package from a local folder rather than a cloud-synced one (Dropbox,
OneDrive), since step 05 writes and renames many small files. Parallel workers
are used on macOS and Linux; on Windows all steps run on a single core.

6.1 Partial reproduction
------------------------

Step 05 takes about 4.5 hours with 8 workers (about 17.5 hours with one). Its
results, output/intermediate/facebook_orderings.csv and
facebook_orderings_info.csv, are included in the package, so the exhibits can
be checked without it:

    Rscript run_all.R 04 06
        (after downloading the data) reproduces Table 1, Figure 8 and the
        Facebook in-text numbers from the included results in about
        20 seconds;

    Rscript run_all.R 00 01 02 03
        reproduces Figures 4, 5 and 7 and their in-text numbers in about
        3 minutes;

    Rscript run_all.R
        (or Rscript run_all.R 05 06 after step 04) recomputes the included
        results from scratch, overwriting them; on the authors' machine they
        come out byte-identical, and on other machines they should differ at
        most in the last digits (see "Controlled randomness").

Step 06 checks that the results it reads match the settings in config.R (seed,
number of orderings, class years) and the derived data they were computed from
(MD5 checksums), and that every school has all orderings with valid values;
its log notes if the code of step 05 has changed since. Any run of step 05,
including quick tests with fewer orderings, replaces the included files. To
restore them, extract them again from the package; their MD5 checksums are:

    8ad6028f9557d426f3dcbd63fa6d904d  facebook_orderings.csv
    8e89143e9794d3ecb2a3008a8de50e78  facebook_orderings_info.csv

6.2 Comparison with the authors' results
----------------------------------------

The folder reference_output/ contains the files that the authors' run wrote to
output/figures/, output/tables/ and output/numbers/, and the data behind
Figures 4, 5 and 7 (output/intermediate/figure4_ri.csv, figure5_summary.csv
and figure7_expected_utility.csv), in the same subfolders and under the same
names as in output/. The code neither reads nor changes them. After a run,
they can be compared with the new outputs, for example on macOS or Linux with
the command below (and likewise for the other subfolders; output/intermediate/
also contains other files):

    diff -r reference_output/numbers output/numbers

On the authors' machine, a rerun reproduces all of these files exactly, except
that the PDF figures embed their creation dates (so diff reports them as
different). On other machines, files with full-precision values
(figure5_summary.csv, figure4_ri.csv, figure7_expected_utility.csv,
facebook_results_by_school.csv) may differ in the last digits, but the numbers
reported in the paper should not change (see "Controlled randomness").


7. List of tables, figures and in-text numbers
==============================================

Exhibit                       Program and output file
----------------------------  ------------------------------------------------
Figure 4                      code/01_figure4_maximal_generations.R
                              output/figures/gen_size_K_speed_bw.pdf

Figure 5(a)                   code/03_figure5_random_regular.R
                              output/figures/gains_regular_d_bw.pdf

Figure 5(b)                   code/03_figure5_random_regular.R
                              output/figures/gains_regular_d1d2_bw.pdf

Figure 7                      code/02_figure7_utility_vs_signals.py
                              output/figures/utilityvssignalcounts.png

Table 1                       code/06_facebook_results.R
                              output/tables/table1.tex (also table1.csv)

Figure 8 (left)               code/06_facebook_results.R
                              output/figures/clustering_potential_signals.pdf

Figure 8 (right)              code/06_facebook_results.R
                              output/figures/clustering_reachable_signals.pdf

In-text numbers, Section 4.1  code/01_figure4_maximal_generations.R
                              output/numbers/figure4_numbers.csv

In-text numbers, Section 4.3  code/03_figure5_random_regular.R
                              output/numbers/figure5_numbers.csv

In-text numbers,              code/06_facebook_results.R
Introduction, Section 3.4,    output/numbers/facebook_numbers.csv
Appendix B.2 and footnote 22

Figures 1, 2, 3 and 6         none (diagrams)

The figure files have the same names as in the paper's LaTeX source. Each file
in output/numbers/ lists, for every number, its location in the paper, a
description and its value. The authors' versions of all of these output files
are in reference_output/. Step 06 builds on the intermediate results
output/intermediate/facebook_orderings.csv and facebook_orderings_info.csv
(see the dataset list). Supporting files, not needed for the exhibits: in
output/intermediate/, figure4_ri.csv (r_i behind Figure 4),
figure7_expected_utility.csv (curves of Figure 7), figure5_summary.csv (curves
and bands of Figure 5), figure5_max_gain.rds (largest gain by replication and
generation; R data file) and the folder facebook_orderings/ (cached results of
step 05, one file per school and block of 50 orderings);
output/tables/facebook_results_by_school.csv (per-school averages and network
statistics); and output/logs/facebook_job_times.csv (computing time of every
ordering).


8. References
=============

Csardi, Gabor, and Tamas Nepusz. 2006. "The igraph Software Package for
    Complex Network Research." InterJournal, Complex Systems 1695.

L'Ecuyer, Pierre, Richard Simard, E. Jack Chen, and W. David Kelton. 2002. "An
    Object-Oriented Random-Number Package with Many Long Streams and
    Substreams." Operations Research 50 (6): 1073-1075.

Traud, Amanda L., Eric D. Kelsic, Peter J. Mucha, and Mason A. Porter. 2011.
    "Comparing Community Structure to Characteristics in Online Collegiate
    Social Networks." SIAM Review 53 (3): 526-543.

Traud, Amanda L., Peter J. Mucha, and Mason A. Porter. 2011. "Facebook100"
    [data set]. facebook100.zip, readme dated February 11, 2011. Archived copy
    at the Internet Archive,
    https://archive.org/details/oxford-2005-facebook-matrix. Accessed
    November 17, 2025 and October 19, 2026.

Traud, Amanda L., Peter J. Mucha, and Mason A. Porter. 2012. "Social Structure
    of Facebook Networks." Physica A 391 (16): 4165-4180.
