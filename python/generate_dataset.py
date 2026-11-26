"""
generate_dataset.py
-------------------
Creates a realistic, synthetic student performance dataset (RAW, intentionally messy).

The raw file contains:
  * 1,100 unique student-subject records (220 students x 5 subjects)
  * 40 exact duplicate rows
  * ~2-3% missing values in numeric columns and ~1% in Gender
  * A few unrealistic Study_Hours values (data-entry errors) for outlier practice

Run:  python python/generate_dataset.py
"""
from pathlib import Path
import numpy as np
import pandas as pd

SEED = 42
rng = np.random.default_rng(SEED)           # fixed seed -> reproducible dataset

ROOT = Path(__file__).resolve().parents[1]
RAW_PATH = ROOT / "data" / "raw" / "student_performance_raw.csv"

N_STUDENTS = 220
SUBJECTS = ["Mathematics", "Science", "English", "History", "Computer Science"]
# Small subject-level difficulty effect (negative = harder subject)
SUBJECT_EFFECT = {"Mathematics": -4, "Science": -1, "English": 3, "History": 1, "Computer Science": 2}
CLASS_AGE = {"Grade 9": 14, "Grade 10": 15, "Grade 11": 16, "Grade 12": 17}

rows = []
for i in range(N_STUDENTS):
    sid = f"S{1001 + i}"
    gender = str(rng.choice(["Male", "Female"]))
    cls = str(rng.choice(list(CLASS_AGE), p=[0.28, 0.27, 0.25, 0.20]))
    age = CLASS_AGE[cls] + int(rng.choice([0, 0, 1]))        # some students are a year older
    ability = rng.normal(0, 8)                                 # latent student ability
    diligence = rng.normal(0, 1)                               # latent attitude -> attendance & study
    base_att = float(np.clip(82 + 7 * diligence + rng.normal(0, 3), 45, 100))

    for subj in SUBJECTS:
        attendance = float(np.clip(base_att + rng.normal(0, 5), 40, 100))
        study = float(np.clip(6 + 2.0 * diligence + rng.normal(0, 2.2), 0.5, 18))   # hours per week
        assignment = float(np.clip(
            62 + ability + SUBJECT_EFFECT[subj] + 0.15 * (attendance - 80) + 1.2 * (study - 6)
            + rng.normal(0, 7), 10, 100))
        exam = float(np.clip(
            56 + 1.1 * ability + SUBJECT_EFFECT[subj] + 0.30 * (attendance - 80) + 1.8 * (study - 6)
            + rng.normal(0, 9), 5, 100))
        final = 0.30 * assignment + 0.70 * exam               # weighting: 30% assignment, 70% exam
        rows.append([sid, gender, age, cls, subj, round(attendance, 1), round(study, 1),
                     round(assignment, 1), round(exam, 1), round(final, 2)])

cols = ["Student_ID", "Gender", "Age", "Class", "Subject", "Attendance", "Study_Hours",
        "Assignment_Marks", "Exam_Marks", "Final_Marks"]
df = pd.DataFrame(rows, columns=cols)

# ---- Inject data-quality problems for cleaning practice ----
n = len(df)
for col, frac in [("Attendance", 0.03), ("Study_Hours", 0.03), ("Assignment_Marks", 0.03),
                  ("Exam_Marks", 0.03), ("Final_Marks", 0.02), ("Gender", 0.01)]:
    idx = rng.choice(df.index, size=int(n * frac), replace=False)
    df.loc[idx, col] = np.nan

out_idx = rng.choice(df.index, size=6, replace=False)          # unrealistic study hours
df.loc[out_idx, "Study_Hours"] = [35.0, 42.0, 48.0, 60.0, 28.5, 31.0]

dups = df.sample(40, random_state=SEED)                        # exact duplicate rows
df = pd.concat([df, dups], ignore_index=True).sample(frac=1, random_state=SEED).reset_index(drop=True)

RAW_PATH.parent.mkdir(parents=True, exist_ok=True)
df.to_csv(RAW_PATH, index=False)
print(f"Raw dataset saved: {RAW_PATH}  shape={df.shape}")
