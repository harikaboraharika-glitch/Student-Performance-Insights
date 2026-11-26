# Business Questions

Each question is answered with SQL (queries in `sql/analysis_queries.sql`) and Python (`python/analysis.py`).
Full answers with numbers are in `reports/insights.md`.

| # | Business question | SQL query | Python / chart |
|---|---|---|---|
| 1 | Which subject has the highest average marks? | Q03 | EDA section 4, chart 02 |
| 2 | Which subject is weakest, and in which classes? | Q08, Q28 | chart 03, 12 |
| 3 | Which students have low performance? | Q10, Q11 | `student_summary.csv` |
| 4 | Does attendance affect student performance? | Q16, Q18, Q19 | chart 05, 10 |
| 5 | Does study time influence exam results? | Q17 | chart 06 |
| 6 | Which class performs best? | Q04, Q21, Q27 | chart 04 |
| 7 | What percentage of students passed? | Q05, Q07 | chart 01, 08 |
| 8 | Which students need academic support? | Q12, Q29, Q30 | `Needs_Support` sheet in Excel |
| 9 | Is there a performance gap between genders? | Q06 | chart 09, t-test |
| 10 | Who are the top performers and how do they differ from the rest? | Q09, Q13, Q23 | EDA section 4 |
| 11 | Which students perform unevenly across subjects? | Q15, Q25 | - |
| 12 | Are exams harder than assignments? | Q20 | EDA section 4 |
| 13 | How is performance distributed across grades? | Q07, Q26 | chart 08 |
| 14 | Which subject topper / top 3 per class? | Q21, Q22 | - |

## Metric definitions
* **Final marks** = 30% assignment + 70% exam.
* **Pass** = final marks >= 40.
* **Needs support** = average final < 50 OR failed 2+ subjects OR average attendance < 75%.
