# Expected Outputs for `analysis_queries.sql`

Outputs below were produced by running every query against the project's cleaned dataset (`sql/insert_data.sql`). Your MySQL results should match; decimals may display with trailing zeros (e.g. `61.4` vs `61.40`) and rows with tied values may appear in a different order only where noted.

## Q01 - Dataset overview: how many students, subjects and performance records exist?

| total_students | total_subjects | total_records |
|---|---|---|
| 220 | 5 | 1100 |

## Q02 - Number of students per class and gender split (GROUP BY on two columns)

| class_name | gender | students |
|---|---|---|
| Grade 10 | Female | 27 |
| Grade 10 | Male | 31 |
| Grade 11 | Female | 31 |
| Grade 11 | Male | 30 |
| Grade 12 | Female | 19 |
| Grade 12 | Male | 24 |
| Grade 9 | Female | 26 |
| Grade 9 | Male | 32 |

## Q03 - Which subject has the highest average final marks? (JOIN + GROUP BY + ORDER BY)

| subject_name | avg_final_marks |
|---|---|
| English | 61.42 |
| Computer Science | 60.19 |
| History | 59.73 |
| Science | 57.2 |
| Mathematics | 54.22 |

## Q04 - Class-wise average final marks and pass percentage

| class_name | students | avg_final_marks | pass_pct |
|---|---|---|---|
| Grade 10 | 58 | 60.63 | 96.21 |
| Grade 11 | 61 | 58.91 | 92.13 |
| Grade 9 | 58 | 57.77 | 91.38 |
| Grade 12 | 43 | 56.28 | 90.23 |

## Q05 - Overall pass percentage across all records

| total_records | passed | pass_pct |
|---|---|---|
| 1100 | 1019 | 92.64 |

## Q06 - Gender-wise performance comparison

| gender | records | avg_final_marks | avg_attendance | avg_study_hours |
|---|---|---|---|---|
| Female | 515 | 58.92 | 81.67 | 6.16 |
| Male | 585 | 58.22 | 82.34 | 6.02 |

## Q07 - Grade distribution with percentage share (window function over the aggregate)

| grade | records | pct_of_total |
|---|---|---|
| A | 46 | 4.18 |
| B | 137 | 12.45 |
| C | 322 | 29.27 |
| D | 325 | 29.55 |
| E | 189 | 17.18 |
| F | 81 | 7.36 |

## Q08 - Subject-wise pass rate; show only subjects whose pass rate is below 92% (HAVING)

| subject_name | failures | pass_pct |
|---|---|---|
| Mathematics | 24 | 89.09 |
| Science | 19 | 91.36 |

## Q09 - Top 10 students by average final marks (across all five subjects)

| student_id | class_name | avg_final_marks |
|---|---|---|
| S1211 | Grade 9 | 88.11 |
| S1138 | Grade 11 | 84.5 |
| S1044 | Grade 9 | 83.76 |
| S1019 | Grade 10 | 83.08 |
| S1205 | Grade 10 | 82.32 |
| S1098 | Grade 9 | 81.28 |
| S1086 | Grade 10 | 77.94 |
| S1176 | Grade 10 | 75.97 |
| S1123 | Grade 10 | 74.79 |
| S1013 | Grade 10 | 73.71 |

## Q10 - Low performers: students whose overall average is below 50

| student_id | class_name | avg_final_marks |
|---|---|---|
| S1092 | Grade 9 | 30.09 |
| S1192 | Grade 10 | 31.96 |
| S1132 | Grade 9 | 36.34 |
| S1156 | Grade 9 | 37.31 |
| S1096 | Grade 12 | 37.91 |
| S1042 | Grade 12 | 39.35 |
| S1078 | Grade 10 | 39.42 |
| S1066 | Grade 12 | 39.7 |
| S1162 | Grade 11 | 40.62 |
| S1107 | Grade 12 | 40.87 |

## Q11 - Students who failed in 2 or more subjects (HAVING on a conditional count)

| student_id | subjects_failed |
|---|---|
| S1092 | 5 |
| S1078 | 4 |
| S1096 | 4 |
| S1132 | 4 |
| S1156 | 4 |
| S1003 | 3 |
| S1007 | 3 |
| S1042 | 3 |
| S1066 | 3 |
| S1107 | 3 |

## Q12 - How many students need academic support?

| students_needing_support | pct_of_students |
|---|---|
| 70 | 31.82 |

## Q13 - Consistent high achievers: students scoring 60+ in EVERY subject

| student_id | avg_final_marks | lowest_subject_mark |
|---|---|---|
| S1211 | 88.11 | 63.86 |
| S1138 | 84.5 | 76.33 |
| S1044 | 83.76 | 73.03 |
| S1019 | 83.08 | 68.75 |
| S1205 | 82.32 | 79.15 |
| S1098 | 81.28 | 69.67 |
| S1086 | 77.94 | 66.46 |
| S1176 | 75.97 | 60.46 |
| S1123 | 74.79 | 61.28 |
| S1013 | 73.71 | 63.87 |

## Q14 - Students scoring above their own class average (correlated subquery inside a CTE)

| class_name | students_above_class_avg |
|---|---|
| Grade 10 | 28 |
| Grade 11 | 31 |
| Grade 12 | 23 |
| Grade 9 | 29 |

## Q15 - Students with the largest gap between best and worst subject (inconsistent performers)

| student_id | best_mark | worst_mark | spread |
|---|---|---|---|
| S1103 | 64.39 | 23.74 | 40.65 |
| S1211 | 99.13 | 63.86 | 35.27 |
| S1064 | 76.2 | 41.54 | 34.66 |
| S1119 | 75.76 | 42.62 | 33.14 |
| S1166 | 87.3 | 54.61 | 32.69 |

## Q16 - Does attendance affect performance? Average marks by attendance band (CASE)

| attendance_band | records | avg_final_marks | pass_pct |
|---|---|---|---|
| 1. <60% | 7 | 48.9 | 100.0 |
| 2. 60-75% | 223 | 52.94 | 86.1 |
| 3. 75-90% | 668 | 58.84 | 93.56 |
| 4. 90-100% | 202 | 64.12 | 96.53 |

## Q17 - Does study time influence exam results? Average exam marks by weekly study-hour band

| study_band | records | avg_exam_marks |
|---|---|---|
| 1. 0-4 hrs | 268 | 50.07 |
| 2. 4-8 hrs | 565 | 56.48 |
| 3. 8-12 hrs | 242 | 62.72 |
| 4. 12+ hrs | 25 | 77.12 |

## Q18 - Pearson correlation between attendance and final marks computed in pure SQL

| corr_attendance_final |
|---|
| 0.311 |

## Q19 - Pass rate of students with attendance ABOVE vs BELOW the overall average (scalar subquery)

| attendance_group | records | avg_final_marks | pass_pct |
|---|---|---|---|
| Above average attendance | 544 | 61.71 | 95.96 |
| Below average attendance | 556 | 55.46 | 89.39 |

## Q20 - Records where exam marks beat assignment marks by more than 15 points (WHERE filter)

| exam_much_higher_than_assignment |
|---|
| 38 |

## Q21 - Rank students inside each class by average final marks (RANK, top 3 per class)

| class_name | student_id | avg_final_marks | class_rank |
|---|---|---|---|
| Grade 10 | S1019 | 83.08 | 1 |
| Grade 10 | S1205 | 82.32 | 2 |
| Grade 10 | S1086 | 77.94 | 3 |
| Grade 11 | S1138 | 84.5 | 1 |
| Grade 11 | S1046 | 73.21 | 2 |
| Grade 11 | S1173 | 72.64 | 3 |
| Grade 12 | S1185 | 73.31 | 1 |
| Grade 12 | S1067 | 68.11 | 2 |
| Grade 12 | S1153 | 67.01 | 3 |
| Grade 9 | S1211 | 88.11 | 1 |
| Grade 9 | S1044 | 83.76 | 2 |
| Grade 9 | S1098 | 81.28 | 3 |

## Q22 - Subject topper for every subject (ROW_NUMBER with a tie-breaker)

| subject_name | student_id | topper_marks |
|---|---|---|
| Computer Science | S1044 | 97.57 |
| English | S1211 | 91.52 |
| History | S1138 | 95.63 |
| Mathematics | S1211 | 99.13 |
| Science | S1211 | 95.62 |

## Q23 - Split students into performance quartiles with NTILE(4) and summarise each quartile

| quartile | students | avg_final_marks | avg_attendance | avg_study_hours |
|---|---|---|---|---|
| 1 | 55 | 71.09 | 85.42 | 7.37 |
| 2 | 55 | 61.88 | 82.42 | 6.14 |
| 3 | 55 | 55.59 | 81.84 | 5.68 |
| 4 | 55 | 45.65 | 78.42 | 5.16 |

## Q24 - Compare subject averages with the previous (higher-ranked) subject using LAG

| subject_name | avg_final_marks | diff_vs_previous |
|---|---|---|
| English | 61.42 |  |
| Computer Science | 60.19 | -1.23 |
| History | 59.73 | -0.46 |
| Science | 57.2 | -2.53 |
| Mathematics | 54.22 | -2.99 |

## Q25 - Each student's mark in a subject vs their own average (window AVG per student) - first 8 rows

| student_id | subject_id | final_marks | student_avg | diff_from_own_avg |
|---|---|---|---|---|
| S1001 | 1 | 70.45 | 69.54 | 0.91 |
| S1001 | 2 | 74.6 | 69.54 | 5.06 |
| S1001 | 3 | 69.61 | 69.54 | 0.07 |
| S1001 | 4 | 61.98 | 69.54 | -7.56 |
| S1001 | 5 | 71.06 | 69.54 | 1.52 |
| S1002 | 1 | 69.62 | 64.85 | 4.77 |
| S1002 | 2 | 73.09 | 64.85 | 8.24 |
| S1002 | 3 | 66.42 | 64.85 | 1.57 |

## Q26 - Cumulative grade distribution (running total of records from grade A downwards)

| grade | records | cumulative_records | cumulative_pct |
|---|---|---|---|
| A | 46 | 46 | 4.18 |
| B | 137 | 183 | 16.64 |
| C | 322 | 505 | 45.91 |
| D | 325 | 830 | 75.45 |
| E | 189 | 1019 | 92.64 |
| F | 81 | 1100 | 100.0 |

## Q27 - Class x Subject performance matrix (conditional aggregation / pivot)

| class_name | mathematics | science | english | history | computer_science |
|---|---|---|---|---|---|
| Grade 10 | 55.86 | 60.52 | 63.31 | 62.38 | 61.09 |
| Grade 11 | 53.54 | 57.37 | 63.16 | 59.27 | 61.19 |
| Grade 12 | 52.08 | 54.09 | 60.71 | 58.14 | 56.36 |
| Grade 9 | 54.86 | 56.01 | 58.2 | 58.73 | 61.07 |

## Q28 - Weakest subject for each class (CTE + RANK) - where should extra teaching hours go?

| class_name | weakest_subject | avg_final_marks |
|---|---|---|
| Grade 10 | Mathematics | 55.86 |
| Grade 11 | Mathematics | 53.54 |
| Grade 12 | Mathematics | 52.08 |
| Grade 9 | Mathematics | 54.86 |

## Q29 - At-risk students with LOW attendance AND LOW study time (multi-condition subquery)

| student_id | class_name | avg_attendance | avg_study_hours | avg_final_marks |
|---|---|---|---|---|
| S1156 | Grade 9 | 68.6 | 3.4 | 37.31 |
| S1162 | Grade 11 | 69.6 | 3.6 | 40.62 |
| S1107 | Grade 12 | 69.6 | 2.1 | 40.87 |
| S1149 | Grade 10 | 72.4 | 3.2 | 43.72 |
| S1100 | Grade 12 | 71.4 | 2.9 | 47.6 |
| S1177 | Grade 10 | 71.6 | 3.7 | 48.06 |
| S1116 | Grade 9 | 62.0 | 1.5 | 48.44 |
| S1209 | Grade 9 | 69.6 | 2.4 | 48.8 |
| S1079 | Grade 11 | 67.3 | 1.5 | 51.02 |
| S1128 | Grade 12 | 67.0 | 2.7 | 52.03 |

## Q30 - Reusable view for Power BI / reporting: one row per student with support flag

| support_status | students | avg_final_marks |
|---|---|---|
| Needs Support | 70 | 49.69 |
| On Track | 150 | 62.68 |
