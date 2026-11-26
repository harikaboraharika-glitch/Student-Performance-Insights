# Project Overview

**Project:** Student Performance Analysis - an end-to-end data analytics project
**Role simulated:** Data Analyst at a school / education-analytics team
**Tools:** Python (Pandas, NumPy, Matplotlib, Seaborn, SciPy), MySQL, Power BI, Excel

## Business context
School leadership wants to understand *why* some students perform better than others, spot students who need help
early, and decide where to invest teaching resources. Marks, attendance and study hours are recorded per student per
subject, but the data is messy (duplicates, missing values, data-entry errors) and nobody has analysed it together.

## Goals
1. Build a clean, trustworthy dataset from messy raw records.
2. Measure overall performance (average marks, pass rate, grade mix).
3. Identify the drivers of performance (attendance, study time, subject, class, gender).
4. Flag students who need academic support.
5. Deliver the results as SQL queries, an interactive Power BI dashboard and a written insights report.

## Workflow

```
Raw CSV  ->  Python cleaning & EDA  ->  Cleaned CSV / star-schema CSVs  ->  MySQL (SQL analysis)
                    |                                  |
                    v                                  v
            Charts + Excel summary              Power BI dashboard
                    \_____________ Insights & recommendations _____________/
```

## Deliverables
| Area | Files |
|---|---|
| Data | `data/raw`, `data/processed` |
| Python | `python/analysis.py`, `notebooks/Student_Performance_Analysis.ipynb` |
| SQL | `sql/*.sql`, `sql/expected_outputs.md` |
| Power BI | `powerbi/dashboard_guidelines.md` |
| Reports | `reports/insights.md`, `reports/charts/` |
| Docs | `documentation/*.md`, `README.md` |

## Skills demonstrated
Data cleaning, imputation strategy, outlier handling, EDA, hypothesis testing (t-test, ANOVA), correlation and
regression, SQL (joins, subqueries, CTEs, window functions), star-schema modelling, DAX, dashboard design, and
business storytelling.
