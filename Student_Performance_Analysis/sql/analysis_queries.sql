-- ============================================================================
-- analysis_queries.sql  -  30 analytical queries (basic -> interview level)
-- Requires MySQL 8.0+ (CTEs and window functions).
-- Tables: students(student_id, gender, age, class_name)
--         subjects(subject_id, subject_name)
--         performance(performance_id, student_id, subject_id, attendance, study_hours,
--                     assignment_marks, exam_marks, final_marks, grade, pass_status)
-- Expected outputs for every query are listed in sql/expected_outputs.md
-- ============================================================================
USE student_performance_db;

-- ############################ SECTION A: BASICS ############################

-- Q01 | Dataset overview: how many students, subjects and performance records exist?
SELECT (SELECT COUNT(*) FROM students)    AS total_students,
       (SELECT COUNT(*) FROM subjects)    AS total_subjects,
       (SELECT COUNT(*) FROM performance) AS total_records;

-- Q02 | Number of students per class and gender split (GROUP BY on two columns)
SELECT class_name, gender, COUNT(*) AS students
FROM students
GROUP BY class_name, gender
ORDER BY class_name, gender;

-- Q03 | Which subject has the highest average final marks? (JOIN + GROUP BY + ORDER BY)
SELECT s.subject_name,
       ROUND(AVG(p.final_marks), 2) AS avg_final_marks
FROM performance p
JOIN subjects s ON s.subject_id = p.subject_id
GROUP BY s.subject_name
ORDER BY avg_final_marks DESC;

-- Q04 | Class-wise average final marks and pass percentage
SELECT st.class_name,
       COUNT(DISTINCT st.student_id) AS students,
       ROUND(AVG(p.final_marks), 2)  AS avg_final_marks,
       ROUND(100.0 * SUM(CASE WHEN p.pass_status = 'Pass' THEN 1 ELSE 0 END) / COUNT(*), 2) AS pass_pct
FROM performance p
JOIN students st ON st.student_id = p.student_id
GROUP BY st.class_name
ORDER BY avg_final_marks DESC;

-- Q05 | Overall pass percentage across all records
SELECT COUNT(*) AS total_records,
       SUM(CASE WHEN pass_status = 'Pass' THEN 1 ELSE 0 END) AS passed,
       ROUND(100.0 * SUM(CASE WHEN pass_status = 'Pass' THEN 1 ELSE 0 END) / COUNT(*), 2) AS pass_pct
FROM performance;

-- Q06 | Gender-wise performance comparison
SELECT st.gender,
       COUNT(*)                      AS records,
       ROUND(AVG(p.final_marks), 2)  AS avg_final_marks,
       ROUND(AVG(p.attendance), 2)   AS avg_attendance,
       ROUND(AVG(p.study_hours), 2)  AS avg_study_hours
FROM performance p
JOIN students st ON st.student_id = p.student_id
GROUP BY st.gender
ORDER BY st.gender;

-- Q07 | Grade distribution with percentage share (window function over the aggregate)
SELECT grade,
       COUNT(*) AS records,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM performance
GROUP BY grade
ORDER BY grade;

-- Q08 | Subject-wise pass rate; show only subjects whose pass rate is below 92% (HAVING)
SELECT s.subject_name,
       SUM(CASE WHEN p.pass_status = 'Fail' THEN 1 ELSE 0 END) AS failures,
       ROUND(100.0 * SUM(CASE WHEN p.pass_status = 'Pass' THEN 1 ELSE 0 END) / COUNT(*), 2) AS pass_pct
FROM performance p
JOIN subjects s ON s.subject_id = p.subject_id
GROUP BY s.subject_name
HAVING pass_pct < 92
ORDER BY pass_pct;

-- ################### SECTION B: STUDENT-LEVEL ANALYSIS ####################

-- Q09 | Top 10 students by average final marks (across all five subjects)
SELECT st.student_id, st.class_name,
       ROUND(AVG(p.final_marks), 2) AS avg_final_marks
FROM performance p
JOIN students st ON st.student_id = p.student_id
GROUP BY st.student_id, st.class_name
ORDER BY avg_final_marks DESC, st.student_id
LIMIT 10;

-- Q10 | Low performers: students whose overall average is below 50
SELECT st.student_id, st.class_name,
       ROUND(AVG(p.final_marks), 2) AS avg_final_marks
FROM performance p
JOIN students st ON st.student_id = p.student_id
GROUP BY st.student_id, st.class_name
HAVING AVG(p.final_marks) < 50
ORDER BY avg_final_marks, st.student_id
LIMIT 10;

-- Q11 | Students who failed in 2 or more subjects (HAVING on a conditional count)
SELECT student_id, COUNT(*) AS subjects_failed
FROM performance
WHERE pass_status = 'Fail'
GROUP BY student_id
HAVING COUNT(*) >= 2
ORDER BY subjects_failed DESC, student_id
LIMIT 10;

-- Q12 | How many students need academic support?
--      Rule: average < 50  OR  failed 2+ subjects  OR  average attendance < 75%  (CTE)
WITH student_summary AS (
    SELECT student_id,
           AVG(final_marks) AS avg_final,
           AVG(attendance)  AS avg_att,
           SUM(CASE WHEN pass_status = 'Fail' THEN 1 ELSE 0 END) AS failed_subjects
    FROM performance
    GROUP BY student_id
)
SELECT COUNT(*) AS students_needing_support,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM students), 2) AS pct_of_students
FROM student_summary
WHERE avg_final < 50 OR failed_subjects >= 2 OR avg_att < 75;

-- Q13 | Consistent high achievers: students scoring 60+ in EVERY subject
SELECT student_id,
       ROUND(AVG(final_marks), 2) AS avg_final_marks,
       MIN(final_marks)           AS lowest_subject_mark
FROM performance
GROUP BY student_id
HAVING MIN(final_marks) >= 60
ORDER BY avg_final_marks DESC, student_id
LIMIT 10;

-- Q14 | Students scoring above their own class average (correlated subquery inside a CTE)
WITH student_avg AS (
    SELECT st.student_id, st.class_name, AVG(p.final_marks) AS avg_final
    FROM performance p
    JOIN students st ON st.student_id = p.student_id
    GROUP BY st.student_id, st.class_name
)
SELECT class_name,
       COUNT(*) AS students_above_class_avg
FROM student_avg sa
WHERE avg_final > (SELECT AVG(avg_final) FROM student_avg x WHERE x.class_name = sa.class_name)
GROUP BY class_name
ORDER BY class_name;

-- Q15 | Students with the largest gap between best and worst subject (inconsistent performers)
SELECT student_id,
       MAX(final_marks) AS best_mark,
       MIN(final_marks) AS worst_mark,
       ROUND(MAX(final_marks) - MIN(final_marks), 2) AS spread
FROM performance
GROUP BY student_id
ORDER BY spread DESC, student_id
LIMIT 5;

-- ########### SECTION C: ATTENDANCE & STUDY-TIME RELATIONSHIPS ##############

-- Q16 | Does attendance affect performance? Average marks by attendance band (CASE)
SELECT CASE WHEN attendance < 60 THEN '1. <60%'
            WHEN attendance < 75 THEN '2. 60-75%'
            WHEN attendance < 90 THEN '3. 75-90%'
            ELSE '4. 90-100%' END AS attendance_band,
       COUNT(*)                     AS records,
       ROUND(AVG(final_marks), 2)   AS avg_final_marks,
       ROUND(100.0 * SUM(CASE WHEN pass_status = 'Pass' THEN 1 ELSE 0 END) / COUNT(*), 2) AS pass_pct
FROM performance
GROUP BY attendance_band
ORDER BY attendance_band;

-- Q17 | Does study time influence exam results? Average exam marks by weekly study-hour band
SELECT CASE WHEN study_hours <= 4  THEN '1. 0-4 hrs'
            WHEN study_hours <= 8  THEN '2. 4-8 hrs'
            WHEN study_hours <= 12 THEN '3. 8-12 hrs'
            ELSE '4. 12+ hrs' END AS study_band,
       COUNT(*)                   AS records,
       ROUND(AVG(exam_marks), 2)  AS avg_exam_marks
FROM performance
GROUP BY study_band
ORDER BY study_band;

-- Q18 | Pearson correlation between attendance and final marks computed in pure SQL
SELECT ROUND(
         (AVG(attendance * final_marks) - AVG(attendance) * AVG(final_marks)) /
         (SQRT(AVG(attendance * attendance) - AVG(attendance) * AVG(attendance)) *
          SQRT(AVG(final_marks * final_marks) - AVG(final_marks) * AVG(final_marks))), 3) AS corr_attendance_final
FROM performance;

-- Q19 | Pass rate of students with attendance ABOVE vs BELOW the overall average (scalar subquery)
SELECT CASE WHEN attendance >= (SELECT AVG(attendance) FROM performance)
            THEN 'Above average attendance' ELSE 'Below average attendance' END AS attendance_group,
       COUNT(*)                   AS records,
       ROUND(AVG(final_marks), 2) AS avg_final_marks,
       ROUND(100.0 * SUM(CASE WHEN pass_status = 'Pass' THEN 1 ELSE 0 END) / COUNT(*), 2) AS pass_pct
FROM performance
GROUP BY attendance_group
ORDER BY attendance_group;

-- Q20 | Records where exam marks beat assignment marks by more than 15 points (WHERE filter)
SELECT COUNT(*) AS exam_much_higher_than_assignment
FROM performance
WHERE exam_marks - assignment_marks > 15;

-- ################ SECTION D: WINDOW FUNCTIONS & CTEs #####################

-- Q21 | Rank students inside each class by average final marks (RANK, top 3 per class)
WITH student_avg AS (
    SELECT st.student_id, st.class_name, AVG(p.final_marks) AS avg_final
    FROM performance p
    JOIN students st ON st.student_id = p.student_id
    GROUP BY st.student_id, st.class_name
),
ranked AS (
    SELECT class_name, student_id, ROUND(avg_final, 2) AS avg_final_marks,
           RANK() OVER (PARTITION BY class_name ORDER BY avg_final DESC) AS class_rank
    FROM student_avg
)
SELECT * FROM ranked
WHERE class_rank <= 3
ORDER BY class_name, class_rank, student_id;

-- Q22 | Subject topper for every subject (ROW_NUMBER with a tie-breaker)
WITH ranked AS (
    SELECT s.subject_name, p.student_id, p.final_marks,
           ROW_NUMBER() OVER (PARTITION BY s.subject_name
                              ORDER BY p.final_marks DESC, p.student_id) AS rn
    FROM performance p
    JOIN subjects s ON s.subject_id = p.subject_id
)
SELECT subject_name, student_id, final_marks AS topper_marks
FROM ranked
WHERE rn = 1
ORDER BY subject_name;

-- Q23 | Split students into performance quartiles with NTILE(4) and summarise each quartile
WITH student_avg AS (
    SELECT student_id, AVG(final_marks) AS avg_final, AVG(attendance) AS avg_att,
           AVG(study_hours) AS avg_study
    FROM performance
    GROUP BY student_id
),
quartiles AS (
    SELECT *, NTILE(4) OVER (ORDER BY avg_final DESC) AS quartile
    FROM student_avg
)
SELECT quartile,
       COUNT(*)                    AS students,
       ROUND(AVG(avg_final), 2)    AS avg_final_marks,
       ROUND(AVG(avg_att), 2)      AS avg_attendance,
       ROUND(AVG(avg_study), 2)    AS avg_study_hours
FROM quartiles
GROUP BY quartile
ORDER BY quartile;

-- Q24 | Compare subject averages with the previous (higher-ranked) subject using LAG
WITH subject_avg AS (
    SELECT s.subject_name, AVG(p.final_marks) AS avg_final
    FROM performance p
    JOIN subjects s ON s.subject_id = p.subject_id
    GROUP BY s.subject_name
)
SELECT subject_name,
       ROUND(avg_final, 2) AS avg_final_marks,
       ROUND(avg_final - LAG(avg_final) OVER (ORDER BY avg_final DESC), 2) AS diff_vs_previous
FROM subject_avg
ORDER BY avg_final DESC;

-- Q25 | Each student's mark in a subject vs their own average (window AVG per student) - first 8 rows
SELECT student_id, subject_id, final_marks,
       ROUND(AVG(final_marks) OVER (PARTITION BY student_id), 2) AS student_avg,
       ROUND(final_marks - AVG(final_marks) OVER (PARTITION BY student_id), 2) AS diff_from_own_avg
FROM performance
ORDER BY student_id, subject_id
LIMIT 8;

-- Q26 | Cumulative grade distribution (running total of records from grade A downwards)
WITH g AS (
    SELECT grade, COUNT(*) AS records FROM performance GROUP BY grade
)
SELECT grade, records,
       SUM(records) OVER (ORDER BY grade ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_records,
       ROUND(100.0 * SUM(records) OVER (ORDER BY grade ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
             / SUM(records) OVER (), 2) AS cumulative_pct
FROM g
ORDER BY grade;

-- ################# SECTION E: ADVANCED BUSINESS QUERIES ##################

-- Q27 | Class x Subject performance matrix (conditional aggregation / pivot)
SELECT st.class_name,
       ROUND(AVG(CASE WHEN s.subject_name = 'Mathematics'       THEN p.final_marks END), 2) AS mathematics,
       ROUND(AVG(CASE WHEN s.subject_name = 'Science'           THEN p.final_marks END), 2) AS science,
       ROUND(AVG(CASE WHEN s.subject_name = 'English'           THEN p.final_marks END), 2) AS english,
       ROUND(AVG(CASE WHEN s.subject_name = 'History'           THEN p.final_marks END), 2) AS history,
       ROUND(AVG(CASE WHEN s.subject_name = 'Computer Science'  THEN p.final_marks END), 2) AS computer_science
FROM performance p
JOIN students st ON st.student_id = p.student_id
JOIN subjects s  ON s.subject_id  = p.subject_id
GROUP BY st.class_name
ORDER BY st.class_name;

-- Q28 | Weakest subject for each class (CTE + RANK) - where should extra teaching hours go?
WITH class_subject AS (
    SELECT st.class_name, s.subject_name, AVG(p.final_marks) AS avg_final
    FROM performance p
    JOIN students st ON st.student_id = p.student_id
    JOIN subjects s  ON s.subject_id  = p.subject_id
    GROUP BY st.class_name, s.subject_name
),
ranked AS (
    SELECT *, RANK() OVER (PARTITION BY class_name ORDER BY avg_final ASC) AS weakest_rank
    FROM class_subject
)
SELECT class_name, subject_name AS weakest_subject, ROUND(avg_final, 2) AS avg_final_marks
FROM ranked
WHERE weakest_rank = 1
ORDER BY class_name;

-- Q29 | At-risk students with LOW attendance AND LOW study time (multi-condition subquery)
SELECT st.student_id, st.class_name,
       ROUND(a.avg_att, 1)   AS avg_attendance,
       ROUND(a.avg_study, 1) AS avg_study_hours,
       ROUND(a.avg_final, 2) AS avg_final_marks
FROM students st
JOIN (SELECT student_id, AVG(attendance) AS avg_att, AVG(study_hours) AS avg_study,
             AVG(final_marks) AS avg_final
      FROM performance GROUP BY student_id) a ON a.student_id = st.student_id
WHERE a.avg_att < 75 AND a.avg_study < 4
ORDER BY a.avg_final, st.student_id
LIMIT 10;

-- Q30 | Reusable view for Power BI / reporting: one row per student with support flag
CREATE OR REPLACE VIEW vw_student_summary AS
SELECT st.student_id, st.gender, st.age, st.class_name,
       ROUND(AVG(p.final_marks), 2) AS avg_final_marks,
       ROUND(AVG(p.attendance), 2)  AS avg_attendance,
       ROUND(AVG(p.study_hours), 2) AS avg_study_hours,
       SUM(CASE WHEN p.pass_status = 'Fail' THEN 1 ELSE 0 END) AS subjects_failed,
       CASE WHEN AVG(p.final_marks) < 50
              OR SUM(CASE WHEN p.pass_status = 'Fail' THEN 1 ELSE 0 END) >= 2
              OR AVG(p.attendance) < 75 THEN 'Needs Support' ELSE 'On Track' END AS support_status
FROM students st
JOIN performance p ON p.student_id = st.student_id
GROUP BY st.student_id, st.gender, st.age, st.class_name;

SELECT support_status, COUNT(*) AS students, ROUND(AVG(avg_final_marks), 2) AS avg_final_marks
FROM vw_student_summary
GROUP BY support_status
ORDER BY support_status;
