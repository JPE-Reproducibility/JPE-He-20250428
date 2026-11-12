## Potential Personal Identifiable Information (PII)

⚠️ We found the following instances of potentially personally identifying information. This may be completely legitimate but might be worth checking. *As a reminder, privacy legislation in many countries (e.g. GDPR in EU) prohibits the dissemination of personal identifiable information without prior (and documented) consent of individuals.* If indeed you want to publish such information with your replication package, you should probably have obtained IRB approval for this - please check!

**Summary:**

- Data files with PII indicators: 5
- Variables flagged in data: 6
- Code files with PII references: 14
- PII references in code: 266

### Summary of Flagged Files

| File Type | File | Variables/References | PII Categories |
|-----------|------|----------------------|----------------|
| Data | `facebook_numbers.csv` | 1 | loc, location |
| Data | `facebook_orderings.csv` | 1 | school |
| Data | `facebook_results_by_school.csv` | 2 | school, degree |
| Data | `figure4_numbers.csv` | 1 | loc, location |
| Data | `figure5_numbers.csv` | 1 | loc, location |
| Code | `01_figure4_maximal_generations.R` | 5 | network, lat, second, lname, name |
| Code | `02_figure7_utility_vs_signals.py` | 3 | zip, loc, name |
| Code | `03_figure5_random_regular.R` | 18 | network, minute, lat, degree, lon, name |
| Code | `04_facebook_extract.py` | 35 | zip, name, school, loc, lat |
| Code | `05_facebook_random_orderings.R` | 55 | social, network, school, name, block, loc, second, lon, minute |
| Code | `06_facebook_results.R` | 44 | network, second, school, name, zip, degree, lname, lat |
| Code | `config.R` | 8 | name, lat, school, lon, network |
| Code | `generations.R` | 4 | network |
| Code | `run_all.R` | 20 | zip, name, minute |
| Code | `signal_counting.R` | 31 | network, lat, name, son, second |
| Code | `signal_counting.c` | 16 | network, lat, sex, loc |
| Code | `table1.tex` | 1 | school |
| Code | `test_signal_counting.R` | 16 | name, network, lat |
| Code | `utils.R` | 10 | loc, location, name, lat, lon, minute |

*See [Appendix](report-pii-appendix.md) for detailed listing of all flagged instances.*
