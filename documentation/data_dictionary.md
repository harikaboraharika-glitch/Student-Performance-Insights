# Data Dictionary

## 1. Raw file - `data/raw/student_performance_raw.csv` (1,140 rows)

| Column | Type | Description | Valid values / notes |
|---|---|---|---|
| Student_ID | Text | Unique student identifier | `S1001` - `S1220` (one student appears once per subject) |
| Gender | Text | Student gender | Male / Female (11 missing) |
| Age | Integer | Age in years | 14 - 18 |
| Class | Text | Class / grade of the student | Grade 9, Grade 10, Grade 11, Grade 12 |
| Subject | Text | Subject studied | Mathematics, Science, English, History, Computer Science |
| Attendance | Decimal | % of classes attended in that subject | 0 - 100 (35 missing) |
| Study_Hours | Decimal | Weekly study hours for that subject | 0.5 - 18 realistic; 6 injected errors above 20 (34 missing) |
| Assignment_Marks | Decimal | Assignment score | 0 - 100 (33 missing) |
| Exam_Marks | Decimal | Exam score | 0 - 100 (33 missing) |
| Final_Marks | Decimal | Final score = 0.30 x Assignment + 0.70 x Exam | 0 - 100 (23 missing) |

Intentional data-quality issues: **40 duplicate rows**, **169 missing cells**, **6 impossible study-hour values**.

## 2. Cleaned file - `data/processed/student_performance_cleaned.csv` (1,100 rows)

All raw columns (no missing values, no duplicates) plus derived columns:

| Column | Description | Logic |
|---|---|---|
| Grade | Letter grade | A >= 80, B 70-79.99, C 60-69.99, D 50-59.99, E 40-49.99, F < 40 |
| Pass_Fail | Result | Pass if Final_Marks >= 40 |
| Performance_Category | Performance tier | At Risk < 50, Average 50-64.99, Good 65-79.99, Excellent >= 80 |
| Attendance_Band | Attendance bucket | <60%, 60-75%, 75-90%, 90-100% (lower bound inclusive) |
| Study_Band | Weekly study bucket | 0-4, 4-8, 8-12, 12+ hrs (upper bound inclusive) |

## 3. Star-schema tables (for MySQL and Power BI)

**`dim_students.csv` / MySQL `students`** (220 rows)

| Column | Description |
|---|---|
| Student_ID / student_id | Primary key |
| Gender / gender | Male / Female |
| Age / age | Age in years |
| Class / class_name | Grade 9-12 (`class_name` in MySQL because CLASS is reserved) |

**`dim_subjects.csv` / MySQL `subjects`** (5 rows)

| Column | Description |
|---|---|
| Subject_ID / subject_id | Primary key (1 Computer Science, 2 English, 3 History, 4 Mathematics, 5 Science) |
| Subject_Name / subject_name | Subject name |

**`fact_performance.csv` / MySQL `performance`** (1,100 rows)

| Column | Description |
|---|---|
| Performance_ID | Primary key |
| Student_ID | Foreign key -> students |
| Subject_ID | Foreign key -> subjects |
| Attendance, Study_Hours, Assignment_Marks, Exam_Marks, Final_Marks | Measures (see above) |
| Grade | A-F |
| Pass_Fail (CSV) / pass_status (MySQL) | Pass / Fail |

**`student_summary.csv`** (220 rows, one per student): Student_ID, Class, Gender, Avg_Final, Avg_Attendance,
Avg_Study_Hours, Subjects_Failed, Needs_Support (True if Avg_Final < 50 OR Subjects_Failed >= 2 OR Avg_Attendance < 75).

## 4. Other outputs

| File | Purpose |
|---|---|
| `data/processed/student_performance_summary.xlsx` | Excel workbook: Cleaned_Data, Subject_Summary, Class_Summary, Student_Summary, Needs_Support, Outlier_Report |
| `reports/summary_metrics.json` | Key metrics produced by `analysis.py` |
| `reports/charts/*.png` | 12 charts |
