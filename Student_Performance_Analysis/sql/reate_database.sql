USE student_performance_db;

SELECT * FROM students LIMIT 10;
SELECT
    class_name,
    COUNT(student_id) AS total_students
FROM students
GROUP BY class_name;

SELECT
    s.subject_name,
    ROUND(AVG(p.final_marks), 2) AS average_marks
FROM performance p
JOIN subjects s
    ON p.subject_id = s.subject_id
GROUP BY s.subject_name
ORDER BY average_marks DESC;

SELECT *
FROM performance
WHERE final_marks > (
    SELECT AVG(final_marks)
    FROM performance
);
SELECT ROUND(AVG(final_marks), 2) AS overall_average
FROM performance;

SELECT
    pass_status,
    COUNT(*) AS total_records
FROM performance
GROUP BY pass_status;

SELECT
    pass_status,
    COUNT(*) AS total_records,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM performance), 2) AS percentage
FROM performance
GROUP BY pass_status;

SELECT
    s.class_name,
    ROUND(AVG(p.final_marks), 2) AS average_marks
FROM students s
JOIN performance p
    ON s.student_id = p.student_id
GROUP BY s.class_name
ORDER BY average_marks DESC;

SELECT
    s.class_name,
    MAX(p.final_marks) AS highest_marks
FROM students s
JOIN performance p
    ON s.student_id = p.student_id
GROUP BY s.class_name
ORDER BY highest_marks DESC;

SELECT
    s.class_name,
    MIN(p.final_marks) AS lowest_marks
FROM students s
JOIN performance p
    ON s.student_id = p.student_id
GROUP BY s.class_name
ORDER BY lowest_marks ASC;

SELECT
    student_id,
    subject_id,
    final_marks,
    grade
FROM performance
WHERE final_marks > 80
ORDER BY final_marks DESC;

SELECT
    subject_id,
    COUNT(*) AS high_score_count
FROM performance
WHERE final_marks > 80
GROUP BY subject_id
ORDER BY high_score_count DESC;

SELECT
    s.subject_name,
    COUNT(*) AS high_score_count
FROM performance p
JOIN subjects s
    ON p.subject_id = s.subject_id
WHERE p.final_marks > 80
GROUP BY s.subject_name
ORDER BY high_score_count DESC;

SELECT
    s.class_name,
    ROUND(AVG(p.attendance), 2) AS average_attendance
FROM students s
JOIN performance p
    ON s.student_id = p.student_id
GROUP BY s.class_name
ORDER BY average_attendance DESC;

SELECT
    study_hours,
    ROUND(AVG(final_marks), 2) AS average_marks,
    COUNT(*) AS total_records
FROM performance
GROUP BY study_hours
ORDER BY study_hours;

SELECT
    CASE
        WHEN study_hours < 4 THEN 'Low'
        WHEN study_hours <= 8 THEN 'Medium'
        ELSE 'High'
    END AS study_category,
    COUNT(*) AS total_records,
    ROUND(AVG(final_marks), 2) AS average_marks
FROM performance
GROUP BY study_category
ORDER BY average_marks DESC;
SELECT
    s.class_name,
    ROUND(AVG(p.final_marks), 2) AS average_marks
FROM students s
JOIN performance p
    ON s.student_id = p.student_id
GROUP BY s.class_name
HAVING AVG(p.final_marks) > 58;

SELECT
    s.subject_name,
    ROUND(AVG(p.final_marks), 2) AS average_marks
FROM performance p
JOIN subjects s
    ON p.subject_id = s.subject_id
GROUP BY s.subject_name
HAVING AVG(p.final_marks) > 58
ORDER BY average_marks DESC;

SELECT
    student_id,
    final_marks,
    CASE
        WHEN final_marks >= 80 THEN 'Excellent'
        WHEN final_marks >= 60 THEN 'Good'
        WHEN final_marks >= 40 THEN 'Average'
        ELSE 'Needs Improvement'
    END AS performance_level
FROM performance
LIMIT 15;

SELECT
    CASE
        WHEN final_marks >= 80 THEN 'Excellent'
        WHEN final_marks >= 60 THEN 'Good'
        WHEN final_marks >= 40 THEN 'Average'
        ELSE 'Needs Improvement'
    END AS performance_level,
    COUNT(*) AS total_records
FROM performance
GROUP BY performance_level
ORDER BY total_records DESC;

SELECT
    performance_level,
    total_records,
    ROUND(total_records * 100.0 / SUM(total_records) OVER (), 2) AS percentage
FROM (
    SELECT
        CASE
            WHEN final_marks >= 80 THEN 'Excellent'
            WHEN final_marks >= 60 THEN 'Good'
            WHEN final_marks >= 40 THEN 'Average'
            ELSE 'Needs Improvement'
        END AS performance_level,
        COUNT(*) AS total_records
    FROM performance
    GROUP BY performance_level
) AS result
ORDER BY percentage DESC;

SELECT
    student_id,
    subject_id,
    final_marks,
    ROW_NUMBER() OVER (
        ORDER BY final_marks DESC
    ) AS rank_number
FROM performance
LIMIT 15;

SELECT
    student_id,
    subject_id,
    final_marks,
    RANK() OVER (
        ORDER BY final_marks DESC
    ) AS rank_number
FROM performance
LIMIT 15;

SELECT
    student_id,
    subject_id,
    final_marks,
    RANK() OVER (
        ORDER BY final_marks DESC
    ) AS rank_number
FROM performance
WHERE final_marks BETWEEN 60 AND 61
ORDER BY final_marks DESC;
SELECT
    student_id,
    subject_id,
    final_marks,
    DENSE_RANK() OVER (
        ORDER BY final_marks DESC
    ) AS dense_rank_number
FROM performance
WHERE final_marks BETWEEN 60 AND 61
ORDER BY final_marks DESC;
SELECT
    student_id,
    subject_id,
    final_marks,
    RANK() OVER (
        PARTITION BY subject_id
        ORDER BY final_marks DESC
    ) AS subject_rank
FROM performance
ORDER BY subject_id, subject_rank
LIMIT 20;

SELECT *
FROM (
    SELECT
        student_id,
        subject_id,
        final_marks,
        RANK() OVER (
            PARTITION BY subject_id
            ORDER BY final_marks DESC
        ) AS subject_rank
    FROM performance
) AS ranked_students
WHERE subject_rank <= 3
ORDER BY subject_id, subject_rank;

SELECT
    student_id,
    subject_id,
    final_marks,
    LAG(final_marks) OVER (
        PARTITION BY student_id
        ORDER BY subject_id
    ) AS previous_marks
FROM performance
ORDER BY student_id, subject_id
LIMIT 20;

SELECT
    student_id,
    subject_id,
    final_marks,
    LEAD(final_marks) OVER (
        PARTITION BY student_id
        ORDER BY subject_id
    ) AS next_marks
FROM performance
ORDER BY student_id, subject_id
LIMIT 20;

SELECT
    student_id,
    subject_id,
    final_marks,
    LAG(final_marks) OVER (
        PARTITION BY student_id
        ORDER BY subject_id
    ) AS previous_marks,
    final_marks - LAG(final_marks) OVER (
        PARTITION BY student_id
        ORDER BY subject_id
    ) AS marks_difference
FROM performance
ORDER BY student_id, subject_id
LIMIT 20;

SELECT
    student_id,
    subject_id,
    final_marks,
    LAG(final_marks) OVER (
        PARTITION BY student_id
        ORDER BY subject_id
    ) AS previous_marks,
    CASE
        WHEN final_marks > LAG(final_marks) OVER (
            PARTITION BY student_id
            ORDER BY subject_id
        ) THEN 'Improved'
        WHEN final_marks < LAG(final_marks) OVER (
            PARTITION BY student_id
            ORDER BY subject_id
        ) THEN 'Declined'
        ELSE 'No Previous Record'
    END AS performance_change
FROM performance
ORDER BY student_id, subject_id
LIMIT 20;

SELECT
    student_id,
    subject_id,
    final_marks,
    FIRST_VALUE(final_marks) OVER (
        PARTITION BY student_id
        ORDER BY subject_id
    ) AS first_subject_marks
FROM performance
ORDER BY student_id, subject_id
LIMIT 20;

SELECT
    student_id,
    subject_id,
    final_marks,
    LAST_VALUE(final_marks) OVER (
        PARTITION BY student_id
        ORDER BY subject_id
        ROWS BETWEEN UNBOUNDED PRECEDING
        AND UNBOUNDED FOLLOWING
    ) AS last_subject_marks
FROM performance
ORDER BY student_id, subject_id
LIMIT 20;

SELECT
    student_id,
    subject_id,
    final_marks,
    NTILE(4) OVER (
        ORDER BY final_marks DESC
    ) AS performance_group
FROM performance
ORDER BY final_marks DESC
LIMIT 20;
SELECT
    performance_group,
    COUNT(*) AS total_records,
    ROUND(AVG(final_marks), 2) AS average_marks,
    MIN(final_marks) AS minimum_marks,
    MAX(final_marks) AS maximum_marks
FROM (
    SELECT
        final_marks,
        NTILE(4) OVER (
            ORDER BY final_marks DESC
        ) AS performance_group
    FROM performance
) AS grouped_data
GROUP BY performance_group
ORDER BY performance_group;

SELECT
    student_id,
    subject_id,
    final_marks,
    SUM(final_marks) OVER (
        PARTITION BY student_id
        ORDER BY subject_id
    ) AS running_total
FROM performance
ORDER BY student_id, subject_id
LIMIT 20;

SELECT
    student_id,
    subject_id,
    final_marks,
    ROUND(
        AVG(final_marks) OVER (
            PARTITION BY student_id
            ORDER BY subject_id
        ), 2
    ) AS running_average
FROM performance
ORDER BY student_id, subject_id
LIMIT 20;


USE student_performance_db;

-- 1. COUNT() OVER()
SELECT
    student_id,
    subject_id,
    final_marks,
    COUNT(*) OVER (
        PARTITION BY student_id
    ) AS total_subjects
FROM performance
ORDER BY student_id, subject_id
LIMIT 20;


-- 2. MAX() OVER()
SELECT
    student_id,
    subject_id,
    final_marks,
    MAX(final_marks) OVER (
        PARTITION BY student_id
    ) AS highest_marks
FROM performance
ORDER BY student_id, subject_id
LIMIT 20;


-- 3. MIN() OVER()
SELECT
    student_id,
    subject_id,
    final_marks,
    MIN(final_marks) OVER (
        PARTITION BY student_id
    ) AS lowest_marks
FROM performance
ORDER BY student_id, subject_id
LIMIT 20;


-- 4. SUM() OVER() - Total marks per student
SELECT
    student_id,
    subject_id,
    final_marks,
    SUM(final_marks) OVER (
        PARTITION BY student_id
    ) AS total_marks
FROM performance
ORDER BY student_id, subject_id
LIMIT 20;


-- 5. AVG() OVER() - Overall student average
SELECT
    student_id,
    subject_id,
    final_marks,
    ROUND(
        AVG(final_marks) OVER (
            PARTITION BY student_id
        ), 2
    ) AS student_average
FROM performance
ORDER BY student_id, subject_id
LIMIT 20;


-- 6. NTILE(5) - Divide into five groups
SELECT
    student_id,
    final_marks,
    NTILE(5) OVER (
        ORDER BY final_marks DESC
    ) AS performance_group
FROM performance
ORDER BY final_marks DESC
LIMIT 20;


-- 7. LAG() with offset 2
SELECT
    student_id,
    subject_id,
    final_marks,
    LAG(final_marks, 2) OVER (
        PARTITION BY student_id
        ORDER BY subject_id
    ) AS two_subjects_before
FROM performance
ORDER BY student_id, subject_id
LIMIT 20;


-- 8. LEAD() with offset 2
SELECT
    student_id,
    subject_id,
    final_marks,
    LEAD(final_marks, 2) OVER (
        PARTITION BY student_id
        ORDER BY subject_id
    ) AS two_subjects_after
FROM performance
ORDER BY student_id, subject_id
LIMIT 20;


-- 9. Percentage contribution of each subject
SELECT
    student_id,
    subject_id,
    final_marks,
    ROUND(
        final_marks * 100.0 /
        SUM(final_marks) OVER (
            PARTITION BY student_id
        ), 2
    ) AS marks_percentage
FROM performance
ORDER BY student_id, subject_id
LIMIT 20;


-- 10. Difference from student's average
SELECT
    student_id,
    subject_id,
    final_marks,
    ROUND(
        final_marks - AVG(final_marks) OVER (
            PARTITION BY student_id
        ), 2
    ) AS difference_from_average
FROM performance
ORDER BY student_id, subject_id
LIMIT 20;


-- 11. Ranking students by total marks
SELECT
    student_id,
    total_marks,
    RANK() OVER (
        ORDER BY total_marks DESC
    ) AS student_rank
FROM (
    SELECT
        student_id,
        SUM(final_marks) AS total_marks
    FROM performance
    GROUP BY student_id
) AS student_totals
ORDER BY student_rank
LIMIT 20;


-- 12. Ranking students by average marks
SELECT
    student_id,
    average_marks,
    DENSE_RANK() OVER (
        ORDER BY average_marks DESC
    ) AS student_rank
FROM (
    SELECT
        student_id,
        ROUND(AVG(final_marks), 2) AS average_marks
    FROM performance
    GROUP BY student_id
) AS student_averages
ORDER BY student_rank
LIMIT 20;


USE student_performance_db;

-- 1. Top 10 students by average marks
SELECT
    s.student_id,
    s.gender,
    s.class_name,
    ROUND(AVG(p.final_marks), 2) AS average_marks
FROM students s
JOIN performance p
    ON s.student_id = p.student_id
GROUP BY s.student_id, s.gender, s.class_name
ORDER BY average_marks DESC
LIMIT 10;


-- 2. Bottom 10 students by average marks
SELECT
    s.student_id,
    s.gender,
    s.class_name,
    ROUND(AVG(p.final_marks), 2) AS average_marks
FROM students s
JOIN performance p
    ON s.student_id = p.student_id
GROUP BY s.student_id, s.gender, s.class_name
ORDER BY average_marks ASC
LIMIT 10;


-- 3. Average marks by gender
SELECT
    s.gender,
    ROUND(AVG(p.final_marks), 2) AS average_marks,
    COUNT(DISTINCT s.student_id) AS total_students
FROM students s
JOIN performance p
    ON s.student_id = p.student_id
GROUP BY s.gender;


-- 4. Pass percentage by subject
SELECT
    sub.subject_name,
    COUNT(*) AS total_records,
    SUM(CASE WHEN p.pass_status = 'Pass' THEN 1 ELSE 0 END) AS passed,
    ROUND(
        SUM(CASE WHEN p.pass_status = 'Pass' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2
    ) AS pass_percentage
FROM performance p
JOIN subjects sub
    ON p.subject_id = sub.subject_id
GROUP BY sub.subject_name
ORDER BY pass_percentage DESC;


-- 5. Fail count by subject
SELECT
    sub.subject_name,
    COUNT(*) AS failed_records
FROM performance p
JOIN subjects sub
    ON p.subject_id = sub.subject_id
WHERE p.pass_status = 'Fail'
GROUP BY sub.subject_name
ORDER BY failed_records DESC;


-- 6. Average marks by attendance category
SELECT
    CASE
        WHEN attendance < 60 THEN 'Low Attendance'
        WHEN attendance < 80 THEN 'Medium Attendance'
        ELSE 'High Attendance'
    END AS attendance_category,
    COUNT(*) AS total_records,
    ROUND(AVG(final_marks), 2) AS average_marks
FROM performance
GROUP BY attendance_category
ORDER BY average_marks DESC;


-- 7. Students needing academic support
SELECT
    s.student_id,
    s.class_name,
    ROUND(AVG(p.final_marks), 2) AS average_marks
FROM students s
JOIN performance p
    ON s.student_id = p.student_id
GROUP BY s.student_id, s.class_name
HAVING AVG(p.final_marks) < 40
ORDER BY average_marks ASC;


-- 8. Study hours and pass percentage
SELECT
    CASE
        WHEN study_hours < 4 THEN 'Low Study Hours'
        WHEN study_hours <= 8 THEN 'Medium Study Hours'
        ELSE 'High Study Hours'
    END AS study_category,
    COUNT(*) AS total_records,
    ROUND(
        SUM(CASE WHEN pass_status = 'Pass' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2
    ) AS pass_percentage
FROM performance
GROUP BY study_category
ORDER BY pass_percentage DESC;


-- 9. Subject-wise highest and lowest marks
SELECT
    sub.subject_name,
    MAX(p.final_marks) AS highest_marks,
    MIN(p.final_marks) AS lowest_marks,
    ROUND(AVG(p.final_marks), 2) AS average_marks
FROM performance p
JOIN subjects sub
    ON p.subject_id = sub.subject_id
GROUP BY sub.subject_name
ORDER BY average_marks DESC;


-- 10. Class-wise pass percentage
SELECT
    s.class_name,
    COUNT(*) AS total_records,
    SUM(CASE WHEN p.pass_status = 'Pass' THEN 1 ELSE 0 END) AS passed,
    ROUND(
        SUM(CASE WHEN p.pass_status = 'Pass' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2
    ) AS pass_percentage
FROM students s
JOIN performance p
    ON s.student_id = p.student_id
GROUP BY s.class_name
ORDER BY pass_percentage DESC;

