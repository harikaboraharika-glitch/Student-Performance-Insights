-- ============================================================================
-- create_tables.sql
-- Star-schema style design:  students (dimension) + subjects (dimension) + performance (fact)
-- NOTE: the column is called class_name because CLASS is a reserved word in MySQL.
-- ============================================================================
USE student_performance_db;

DROP TABLE IF EXISTS performance;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS subjects;

CREATE TABLE students (
    student_id   VARCHAR(10)  NOT NULL,
    gender       VARCHAR(10)  NOT NULL,
    age          TINYINT      NOT NULL,
    class_name   VARCHAR(10)  NOT NULL,
    PRIMARY KEY (student_id)
);

CREATE TABLE subjects (
    subject_id    INT          NOT NULL,
    subject_name  VARCHAR(50)  NOT NULL,
    PRIMARY KEY (subject_id),
    UNIQUE KEY uq_subject_name (subject_name)
);

CREATE TABLE performance (
    performance_id    INT           NOT NULL,
    student_id        VARCHAR(10)   NOT NULL,
    subject_id        INT           NOT NULL,
    attendance        DECIMAL(5,1)  NOT NULL,   -- % of classes attended
    study_hours       DECIMAL(4,1)  NOT NULL,   -- weekly hours studied for the subject
    assignment_marks  DECIMAL(5,1)  NOT NULL,   -- out of 100
    exam_marks        DECIMAL(5,1)  NOT NULL,   -- out of 100
    final_marks       DECIMAL(5,2)  NOT NULL,   -- 30% assignment + 70% exam
    grade             CHAR(1)       NOT NULL,   -- A-F
    pass_status       VARCHAR(4)    NOT NULL,   -- Pass / Fail (pass mark = 40)
    PRIMARY KEY (performance_id),
    UNIQUE KEY uq_student_subject (student_id, subject_id),
    CONSTRAINT fk_perf_student FOREIGN KEY (student_id) REFERENCES students (student_id),
    CONSTRAINT fk_perf_subject FOREIGN KEY (subject_id) REFERENCES subjects (subject_id),
    CONSTRAINT chk_marks CHECK (final_marks BETWEEN 0 AND 100)
);

CREATE INDEX idx_perf_subject ON performance (subject_id);
CREATE INDEX idx_students_class ON students (class_name);
SHOW TABLES;
