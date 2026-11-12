"""Extract the analysis data for the Facebook application (Appendix B.2) from
the Facebook100 data set (Traud, Mucha and Porter 2012).

Input:  data/raw/facebook100.zip, as distributed at
        https://archive.org/details/oxford-2005-facebook-matrix (see README.txt).
Output, in data/derived/facebook100/ (file names use the school name with
spaces replaced by underscores, e.g. Johns_Hopkins55):
        <school>_students.csv   columns: student, class_year
        <school>_edges.csv      columns: i, j  (friendships, i < j)
        schools.csv             one row per school
        extraction_info.csv     class years kept and checksum of the input

Each school's .mat file holds a sparse symmetric adjacency matrix A (Facebook
friendships within the school) and a matrix local_info with one row per user;
column 1 is the student/faculty status flag (1 = student) and column 6 the
class year (0 = missing). We keep users with status flag 1 and class year in
[first_year, last_year] (2006-2009 in the paper), number them 1..N in the
order in which they appear in the .mat file, and write the friendships among
them. Usage (run_all.R passes the years set in config.R):
    python3 code/04_facebook_extract.py [first_year last_year]
"""
import csv
import hashlib
import io
import shutil
import sys
import warnings
import zipfile
from pathlib import Path

import numpy as np
import scipy.io
import scipy.sparse as sp

EXPECTED = {
    "size": 206740075,
    "md5": "a7687ec2362d369803a3463e2884dbe8",
    "sha1": "7024eb583b1fcab08754e9b74826a64b92b33c99",
}
ROOT = Path(__file__).resolve().parents[1]


def checksums(path):
    md5, sha1 = hashlib.md5(), hashlib.sha1()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            md5.update(chunk)
            sha1.update(chunk)
    return {"size": path.stat().st_size, "md5": md5.hexdigest(), "sha1": sha1.hexdigest()}


def file_stem(school):
    return school.replace(" ", "_")


def main():
    if len(sys.argv) == 1:
        first_year, last_year = 2006, 2009
    elif len(sys.argv) == 3:
        first_year, last_year = int(sys.argv[1]), int(sys.argv[2])
    else:
        raise SystemExit("usage: 04_facebook_extract.py [first_year last_year]")
    zip_path = ROOT / "data" / "raw" / "facebook100.zip"
    out_dir = ROOT / "data" / "derived" / "facebook100"
    if not zip_path.exists():
        raise SystemExit(f"{zip_path} not found. Download facebook100.zip as described in README.txt.")

    found = checksums(zip_path)
    if found != EXPECTED:
        raise SystemExit(f"{zip_path} does not match the expected file:\n  expected {EXPECTED}\n  found    {found}")
    print(f"facebook100.zip verified (MD5 {found['md5']})")

    # write into a temporary folder and swap it in at the end, so an interrupted
    # run never leaves a mixture of old and new files
    tmp_dir = out_dir.with_name(out_dir.name + ".tmp")
    shutil.rmtree(tmp_dir, ignore_errors=True)
    tmp_dir.mkdir(parents=True)
    rows = []
    with zipfile.ZipFile(zip_path) as zf:
        members = sorted(n for n in zf.namelist()
                         if n.startswith("facebook100/") and n.endswith(".mat")
                         and not n.endswith("/schools.mat"))
        if len(members) != 100:
            raise SystemExit(f"expected 100 school files, found {len(members)}")
        for name in members:
            school = name[len("facebook100/"):-len(".mat")]
            stem = file_stem(school)
            with warnings.catch_warnings():  # scipy >= 1.15 warns about its sparse return type
                warnings.simplefilter("ignore", DeprecationWarning)
                mat = scipy.io.loadmat(io.BytesIO(zf.read(name)))
            A = sp.csr_matrix(mat["A"])           # works for sparse matrices and sparse arrays
            info = np.asarray(mat["local_info"])
            if A.shape[0] != A.shape[1] or A.shape[0] != info.shape[0]:
                raise SystemExit(f"{school}: inconsistent dimensions")
            if abs(A - A.T).count_nonzero() != 0:
                raise SystemExit(f"{school}: adjacency matrix is not symmetric")
            status, year = info[:, 0], info[:, 5]
            keep = np.flatnonzero((status == 1) & (year >= first_year) & (year <= last_year))
            sub = sp.triu(A[keep][:, keep], k=1).tocoo()   # each friendship once, no self-loops
            sub.eliminate_zeros()
            order = np.lexsort((sub.col, sub.row))
            edges = np.column_stack([sub.row[order] + 1, sub.col[order] + 1])
            years = year[keep].astype(np.int64)

            with open(tmp_dir / f"{stem}_students.csv", "w", newline="", encoding="utf-8") as f:
                w = csv.writer(f)
                w.writerow(["student", "class_year"])
                w.writerows(zip(range(1, len(keep) + 1), years.tolist()))
            with open(tmp_dir / f"{stem}_edges.csv", "w", newline="", encoding="utf-8") as f:
                w = csv.writer(f)
                w.writerow(["i", "j"])
                w.writerows(edges.tolist())
            counts = [int((years == y).sum()) for y in range(first_year, last_year + 1)]
            rows.append([school, stem, A.shape[0], len(keep), len(edges)] + counts)

    if len({r[1] for r in rows}) != len(rows):
        raise SystemExit("two schools map to the same file name")
    with open(tmp_dir / "schools.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["school", "file_stem", "users_in_raw_data", "students_kept", "friendships_kept"]
                   + [f"students_class_of_{y}" for y in range(first_year, last_year + 1)])
        w.writerows(rows)
    with open(tmp_dir / "extraction_info.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["first_year", "last_year", "zip_md5", "schools"])
        w.writerow([first_year, last_year, found["md5"], len(rows)])
    shutil.rmtree(out_dir, ignore_errors=True)
    tmp_dir.rename(out_dir)
    print(f"Wrote {len(rows)} schools (students of class years {first_year}-{last_year}) to {out_dir}")


if __name__ == "__main__":
    main()
