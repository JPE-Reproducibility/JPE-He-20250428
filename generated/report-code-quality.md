## Code Quality

### R

[ADVISORY] `filter(` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (run_all.R, line 29)
  → steps <- Filter(function(s) s$id %in% selected, steps)

[ADVISORY] `merge()` called without explicit `all=`, `all.x=`, or `all.y=` argument — defaults to inner join, which may silently drop rows. (06_facebook_results.R, line 45)
  → nrow(merge(ord, expected)) != nrow(expected)) {

[ADVISORY] `merge()` called without explicit `all=`, `all.x=`, or `all.y=` argument — defaults to inner join, which may silently drop rows. (06_facebook_results.R, line 78)
  → res <- merge(per_school, net, by = "school")

