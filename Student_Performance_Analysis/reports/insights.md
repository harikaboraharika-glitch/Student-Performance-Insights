# Business Insights Report - Student Performance Analysis

> All figures come from the cleaned dataset (1,100 records, 220 students, 5 subjects) and are reproduced
> by both `python/analysis.py` and `sql/analysis_queries.sql`. The dataset is **synthetic**, so treat the
> findings as a demonstration of method, not as claims about real schools.

## Headline numbers

| KPI | Value |
|---|---|
| Students analysed | 220 |
| Performance records | 1,100 (220 students x 5 subjects) |
| Average final marks | 58.55 / 100 (median 58.50) |
| Overall pass percentage (final >= 40) | **92.64%** (1,019 passed, 81 failed) |
| Average attendance | 82.02% |
| Average weekly study hours per subject | 6.09 |
| Students needing academic support | **70 (31.82%)** |

---

## 10+ Business Questions Answered

### 1. Which subject has the highest average marks?
**English (61.42)**, followed by Computer Science (60.19), History (59.73), Science (57.20) and
**Mathematics (54.22, the lowest)**. A one-way ANOVA (F = 12.22, p < 0.001) confirms that the differences
between subjects are statistically significant. *(SQL Q03, Python chart 02)*

### 2. Which subject is the weakest, and is it weak everywhere?
Mathematics has the lowest average and the lowest pass rate (89.09%, 24 failures). It is the **weakest subject in
every class** (Grade 9: 54.86, Grade 10: 55.86, Grade 11: 53.54, Grade 12: 52.08). *(SQL Q08, Q28)*

### 3. Which students have low performance?
45 students average below 50 marks. The five lowest are S1092 (30.09), S1192 (31.96), S1132 (36.34),
S1156 (37.31) and S1096 (37.91). S1092 failed all 5 subjects. *(SQL Q10, Q11)*

### 4. Does attendance affect student performance?
**Yes - moderately.** Correlation between attendance and final marks is r = 0.311 (p < 0.001).

| Attendance band | Avg final marks | Records |
|---|---|---|
| < 60% | 48.90 | 7 |
| 60-75% | 52.94 | 223 |
| 75-90% | 58.84 | 668 |
| 90-100% | 64.12 | 202 |

Each extra attendance percentage point is associated with ~0.45 more final marks. Students with above-average
attendance pass 95.96% of the time vs 89.39% for below-average attendance. Attendance alone explains ~10%
of the variation in marks (R² = 0.097), so it matters but is not the whole story. *(SQL Q16, Q18, Q19)*

### 5. Does study time influence exam results?
**Yes - this is the strongest driver measured.** Correlation between weekly study hours and exam marks is
r = 0.423 (p < 0.001). Each extra weekly study hour is associated with ~2.13 more exam marks.

| Weekly study hours | Avg exam marks | Records |
|---|---|---|
| 0-4 | 50.07 | 268 |
| 4-8 | 56.48 | 565 |
| 8-12 | 62.72 | 242 |
| 12+ | 77.12 | 25 |

*Caution: the 12+ hour group is small (25 records). Correlation does not prove causation - students who
study more also tend to attend more (r = 0.48 between the two).* *(SQL Q17)*

### 6. Which class performs best?
**Grade 10** - average 60.63 and a 96.21% pass rate. **Grade 12** is lowest (56.28 average, 90.23% pass).
Grade 11 (58.91) and Grade 9 (57.77) sit in between. *(SQL Q04)*

### 7. What percentage of students passed?
**92.64%** of subject records are passes (1,019 of 1,100). Grade distribution: A 46, B 137, C 322, D 325, E 189,
F 81 (the F grade = fail). *(SQL Q05, Q07)*

### 8. Which students need academic support?
A student is flagged if their average is < 50, **or** they failed 2+ subjects, **or** average attendance < 75%.
**70 students (31.82%)** meet at least one rule: 45 by low average, 20 by multiple failures, 37 by low attendance
(rules overlap). The flagged group averages 49.69 vs 62.68 for the 150 "On Track" students.
The full list is in `data/processed/student_summary.csv` (filter `Needs_Support = True`) and the Excel sheet
`Needs_Support`. *(SQL Q12, Q29, Q30)*

### 9. Is there a gender gap?
No meaningful gap. Female students average 58.92 and male students 58.22. A Welch t-test gives p = 0.352,
so the difference is not statistically significant. *(SQL Q06, Python section 5)*

### 10. Who are the top performers and how do they differ?
Top five by average: S1211 (88.11), S1138 (84.50), S1044 (83.76), S1019 (83.08), S1205 (82.32).
Splitting students into quartiles shows the top quartile averages 71.09 marks with 85.4% attendance and 7.4 study
hours/week, while the bottom quartile averages 45.65 marks with 78.4% attendance and 5.2 study hours/week.
*(SQL Q09, Q13, Q23)*

### 11. Are there students with unusually uneven performance?
Yes. SQL Q15 lists students with the widest gap between their best and worst subject; these students may have a
subject-specific problem rather than a general one, so they need targeted (not blanket) support.

### 12. Do students do better in exams than in assignments?
On average, assignment marks are higher than exam marks in every subject (e.g. English 65.86 vs 59.51), meaning
exams are the harder component; 38 records show exam marks exceeding assignment marks by more than 15 points.
*(SQL Q20, Python section 4)*

---

## Data-quality summary (cleaning log)

| Issue | Raw data | Treatment |
|---|---|---|
| Rows | 1,140 | -> 1,100 after cleaning |
| Exact duplicate rows | 40 | Removed |
| Missing values | 169 cells (Gender 11, Attendance 35, Study_Hours 34, Assignment 33, Exam 33, Final 23) | Gender: copied from student's other records; Attendance: student mean; study/assignment/exam: subject median; Final: recomputed (30% assignment + 70% exam) |
| Invalid Study_Hours (> 20 hrs/week for one subject) | 6 | Set to missing, then imputed with subject median |
| IQR outliers after cleaning | Attendance 2, Study 4, Assignment 6, Exam 9, Final 7 | Retained: plausible values (e.g. very low marks) |

---

## Business recommendations

1. **Prioritise Mathematics.** It is the weakest subject in all four classes. Add remedial sessions, peer tutoring, or
   practice worksheets, starting with Grade 12 (52.08 average).
2. **Run an early-warning system.** Use the support flag (70 students) to trigger counselling and parent contact.
   Students with attendance below 75% *and* under 4 study hours a week (SQL Q29) should be contacted first.
3. **Monitor attendance weekly.** Moving a student from the 60-75% band to 75-90% is associated with roughly 6 extra
   marks on average.
4. **Teach study skills.** Offer structured study plans/homework clubs aiming for 8+ hours per subject per week.
5. **Review exam difficulty and preparation.** Exam marks run ~5-6 points below assignment marks; provide exam-practice
   sessions and mock tests.
6. **Support Grade 12 transition.** The senior class has the lowest average and pass rate; check workload and
   board-exam readiness.
7. **Use targeted, not blanket, interventions** for students with uneven subject profiles (SQL Q15).

## Limitations

* Data is synthetic and shows relationships built into the simulation; real data would be noisier.
* Correlations do not prove causation, and no time dimension exists, so improvement trends cannot be assessed.
* The 12+ study-hour and <60% attendance groups are small.
