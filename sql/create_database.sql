-- ============================================================================
-- create_database.sql
-- Creates the MySQL database used by the Student Performance Analysis project.
-- Run order: 1) create_database.sql  2) create_tables.sql  3) insert_data.sql  4) analysis_queries.sql
-- ============================================================================
DROP DATABASE IF EXISTS student_performance_db;
CREATE DATABASE student_performance_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE student_performance_db;
