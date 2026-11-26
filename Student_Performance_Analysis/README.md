<<<<<<< HEAD
# Student Performance Analysis

An end-to-end data analytics project that cleans messy student records, uncovers what drives academic performance,
and identifies students who need support - using **Python, SQL (MySQL), Power BI and Excel**.

![Python](https://img.shields.io/badge/Python-3.9%2B-blue) ![MySQL](https://img.shields.io/badge/MySQL-8.0-orange)
![Power BI](https://img.shields.io/badge/Power%20BI-Dashboard-yellow) ![Excel](https://img.shields.io/badge/Excel-Summary-green)

---

## 1. Project Overview
School leadership records marks, attendance and study hours for every student in every subject, but the data is
messy and unanalysed. This project builds a clean dataset, answers 12+ business questions with Python and SQL,
provides a Power BI dashboard design (with all DAX), and delivers recommendations.

> **Note:** the dataset is synthetic (generated with a fixed random seed) so the project can be shared publicly.
> It deliberately contains duplicates, missing values and impossible values for data-cleaning practice.

## 2. Business Problem
* Why do some students score much higher than others?
* Do attendance and study time really matter?
* Which subjects and classes need the most help?
* Which students should receive academic support *now*?

## 3. Project Objectives
1. Clean and validate the raw data (duplicates, missing values, outliers).
2. Measure performance: average marks, pass rate, grade distribution.
3. Quantify the effect of attendance, study hours, subject, class and gender (correlation, t-test, ANOVA).
4. Build an early-warning rule to flag students needing support.
5. Write 30 SQL analytical queries (basic to interview level).
6. Design a 3-page Power BI dashboard with DAX measures.
7. Summarise insights and recommendations for decision makers.

## 4. Tools and Technologies
| Area | Tools |
|---|---|
| Data cleaning & analysis | Python 3, Pandas, NumPy, SciPy |
| Visualisation | Matplotlib, Seaborn |
| Database | MySQL 8.0 (CTEs, window functions) |
| BI / dashboard | Power BI Desktop, DAX |
| Spreadsheet | Excel (auto-generated summary workbook) |
| Other | Jupyter Notebook, Git/GitHub |

## 5. Dataset Description
`data/raw/student_performance_raw.csv` - 1,140 rows (1,100 unique + 40 duplicates), 10 columns.
220 students x 5 subjects (Mathematics, Science, English, History, Computer Science), Grades 9-12.

| Column | Description |
|---|---|
| Student_ID | Unique student ID (S1001-S1220) |
| Gender | Male / Female |
| Age | 14-18 |
| Class | Grade 9 - Grade 12 |
| Subject | One of 5 subjects |
| Attendance | % of classes attended |
| Study_Hours | Weekly study hours for that subject |
| Assignment_Marks | Out of 100 |
| Exam_Marks | Out of 100 |
| Final_Marks | 30% assignment + 70% exam |

Data-quality issues injected: **40 duplicates, 169 missing cells, 6 impossible study-hour values.**
Full details: [`documentation/data_dictionary.md`](documentation/data_dictionary.md).

## 6. Folder Structure
```
Student_Performance_Analysis/
├── README.md
├── requirements.txt
├── .gitignore
├── data/
│   ├── raw/        student_performance_raw.csv
│   └── processed/  student_performance_cleaned.csv, dim_students.csv, dim_subjects.csv,
│                   fact_performance.csv, student_summary.csv, student_performance_summary.xlsx
├── notebooks/      Student_Performance_Analysis.ipynb      (executed, with outputs)
├── python/         analysis.py, generate_dataset.py, generate_sql_inserts.py
├── sql/            create_database.sql, create_tables.sql, insert_data.sql,
│                   analysis_queries.sql, expected_outputs.md
├── powerbi/        dashboard_guidelines.md                  (data model, DAX, layout, steps)
├── reports/        insights.md, summary_metrics.json, charts/ (12 PNG charts)
└── documentation/  project_overview.md, data_dictionary.md, business_questions.md
```

## 7. Installation
```bash
# 1. Clone the repository
git clone https://github.com/<your-username>/Student_Performance_Analysis.git
cd Student_Performance_Analysis

# 2. (Recommended) create a virtual environment
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate

# 3. Install dependencies
pip install -r requirements.txt
```
Tested with Python 3.12, pandas 3.0, NumPy 2.5, SciPy 1.18, Matplotlib 3.11, Seaborn 0.13.

## 8. How to Execute the Project
Run all commands from the project root.

```bash
python python/generate_dataset.py      # (optional) regenerate the raw dataset - already included
python python/analysis.py              # clean data, EDA, statistics, charts, exports
python python/generate_sql_inserts.py  # (optional) rebuild sql/insert_data.sql from the cleaned data
jupyter notebook notebooks/Student_Performance_Analysis.ipynb   # step-by-step notebook version
```
`analysis.py` prints every step and writes:
* `data/processed/*.csv` and `student_performance_summary.xlsx`
* `reports/charts/*.png` (12 charts) and `reports/summary_metrics.json`

## 9. SQL Execution Instructions (MySQL 8.0+)
Run the scripts in this order (MySQL Workbench: *File -> Open SQL Script -> Run*; or the command line):

```bash
mysql -u root -p < sql/create_database.sql
mysql -u root -p < sql/create_tables.sql
mysql -u root -p < sql/insert_data.sql        # contains every INSERT statement - no CSV import needed
mysql -u root -p < sql/analysis_queries.sql   # 30 analytical queries
```
* **CSV import alternative:** `sql/insert_data.sql` explains how to load `data/processed/*.csv` with
  `LOAD DATA LOCAL INFILE` (requires `SET GLOBAL local_infile = 1;`) or the Workbench *Table Data Import Wizard*.
* **Expected results** for all 30 queries are in [`sql/expected_outputs.md`](sql/expected_outputs.md).
* **Schema:** `students` (220) and `subjects` (5) dimensions + `performance` (1,100) fact table with primary and foreign keys.
* Queries cover SELECT, WHERE, GROUP BY, HAVING, joins, subqueries, CTEs, `RANK`, `ROW_NUMBER`, `NTILE`, `LAG`,
  running totals, pivot with `CASE`, and a reporting view.

## 10. Power BI Dashboard Instructions
A `.pbix` cannot be generated outside Power BI Desktop, so [`powerbi/dashboard_guidelines.md`](powerbi/dashboard_guidelines.md)
provides everything needed to build it in under an hour:
1. Load `fact_performance.csv`, `dim_students.csv`, `dim_subjects.csv` from `data/processed/`.
2. Create the two many-to-one relationships (star schema).
3. Add the calculated columns and 18 DAX measures + 5 calculated columns (Pass %, Students Needing Support, Top Subject, ...).
4. Build the 3 pages: **Executive Overview**, **Drivers of Performance**, **Student Support**.
5. Add slicers (Class, Gender, Subject, Grade, Attendance Band) and sync them across pages.
6. Validate KPI values against the reference numbers in the guide.

## 11. Key Findings
| Question | Finding |
|---|---|
| Average final marks | 58.55 / 100 |
| Pass percentage | **92.64%** (1,019 of 1,100 records) |
| Best / worst subject | **English** 61.42 / **Mathematics** 54.22 (weakest in every class) |
| Best / worst class | **Grade 10** 60.63 / **Grade 12** 56.28 |
| Attendance effect | r = 0.31; marks rise from 52.9 (60-75% attendance) to 64.1 (90-100%) |
| Study time effect | r = 0.42 with exam marks; about +2.1 exam marks per extra weekly study hour |
| Gender | No significant difference (58.92 vs 58.22, p = 0.35) |
| Students needing support | **70 of 220 (31.8%)** |

Charts: see `reports/charts/`. Full analysis: [`reports/insights.md`](reports/insights.md).

## 12. Business Recommendations
1. **Prioritise Mathematics** with remedial classes and peer tutoring, starting with Grade 12.
2. **Launch an early-warning system** using the support rule (average < 50, 2+ failed subjects, or attendance < 75%).
3. **Track attendance weekly** - lifting students from 60-75% to 75-90% attendance is associated with ~6 more marks.
4. **Promote structured study habits** (8+ hours per subject per week).
5. **Add exam-practice sessions** - exam marks are ~6 points lower than assignment marks.
6. **Review the Grade 12 workload and readiness** (lowest average and pass rate).

## 13. Future Improvements
* Predictive model (logistic regression / random forest) to forecast failure risk.
* Add a time dimension (terms/exams) to measure improvement and trends.
* Add teacher, school and socio-economic features for deeper root-cause analysis.
* Automate the pipeline (scheduled script) and refresh Power BI from MySQL directly.
* Deploy an interactive Streamlit dashboard.

## 14. Limitations
Synthetic data; correlations are not causation; small groups at the extremes (12+ study hours, <60% attendance).

## 15. Author
**Your Name** - Data Analyst (Fresher) | [LinkedIn](https://linkedin.com/in/your-profile) | [GitHub](https://github.com/your-username)

*Replace the placeholders above before publishing.*
=======
# Student-Performance-Insights
End-to-end Student Academic Performance Analysis using Python, SQL, Excel, and Power BI.
>>>>>>> 366e90e29e218a00bcfd3de756a2a3d41b292c63
