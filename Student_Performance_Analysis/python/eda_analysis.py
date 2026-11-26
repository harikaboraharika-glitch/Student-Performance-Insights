import pandas as pd

# Load dataset
df = pd.read_csv("data/processed/student_performance_merged.csv")

# Display first 5 records
print("\nFIRST 5 RECORDS")
print(df.head())

# Dataset information
print("\nDATASET INFORMATION")
print(df.info())

# Number of rows and columns
print("\nDATASET SHAPE")
print(df.shape)

# Column names
print("\nCOLUMN NAMES")
print(df.columns.tolist())

# Check missing values
print("\nMISSING VALUES")
print(df.isnull().sum())

# Check duplicate records
print("\nDUPLICATE RECORDS")
print(df.duplicated().sum())

# Descriptive Statistics
print("\nDESCRIPTIVE STATISTICS")
print(df.describe())

# Average marks
print("\nAVERAGE FINAL MARKS")
print(df["final_marks"].mean())

# Highest marks
print("\nHIGHEST FINAL MARKS")
print(df["final_marks"].max())

# Lowest marks
print("\nLOWEST FINAL MARKS")
print(df["final_marks"].min())

# Average attendance
print("\nAVERAGE ATTENDANCE")
print(df["attendance"].mean())

# Average study hours
print("\nAVERAGE STUDY HOURS")
print(df["study_hours"].mean())



subject_analysis = df.groupby("subject_name")["final_marks"].mean()

print("\nAVERAGE MARKS BY SUBJECT")
print(subject_analysis.sort_values(ascending=False))

# Average marks by class
class_analysis = df.groupby("class_name")["final_marks"].mean()

print("\nAVERAGE MARKS BY CLASS")
print(class_analysis.sort_values(ascending=False))

# Pass and fail analysis
pass_count = df["pass_status"].value_counts()

print("\nPASS AND FAIL COUNT")
print(pass_count)

print("\nPASS AND FAIL PERCENTAGE")
print(df["pass_status"].value_counts(normalize=True) * 100)

# Study hours vs final marks

study_analysis = df.groupby(
    pd.cut(
        df["study_hours"],
        bins=[0, 4, 8, float("inf")],
        labels=["Low", "Medium", "High"]
    )
)["final_marks"].agg(["count", "mean"])

print("\nSTUDY HOURS VS PERFORMANCE")
print(study_analysis)

# Study hours vs final marks

study_analysis = df.groupby(
    pd.cut(
        df["study_hours"],
        bins=[0, 4, 8, float("inf")],
        labels=["Low", "Medium", "High"]
    )
)["final_marks"].agg(["count", "mean"])

print("\nSTUDY HOURS VS PERFORMANCE")
print(study_analysis)

# Attendance vs performance

df["attendance_category"] = pd.cut(
    df["attendance"],
    bins=[0, 70, 85, 100],
    labels=["Low", "Medium", "High"],
    include_lowest=True
)

attendance_analysis = df.groupby(
    "attendance_category",
    observed=False
)["final_marks"].agg(["count", "mean"])

print("\nATTENDANCE VS PERFORMANCE")
print(attendance_analysis)
# Correlation with final marks

correlation = df[
    ["attendance", "study_hours", "assignment_marks",
     "exam_marks", "final_marks"]
].corr()

print("\nCORRELATION WITH FINAL MARKS")
print(correlation["final_marks"].sort_values(ascending=False))

# Student-level performance analysis

student_summary = df.groupby("student_id").agg(
    average_marks=("final_marks", "mean"),
    average_attendance=("attendance", "mean"),
    average_study_hours=("study_hours", "mean"),
    total_pass=("pass_status", lambda x: (x == "Pass").sum()),
    total_fail=("pass_status", lambda x: (x == "Fail").sum())
).reset_index()

print("\nSTUDENT PERFORMANCE SUMMARY")
print(student_summary.head(10))

print("\nTOP 10 STUDENTS")
print(student_summary.sort_values(
    by="average_marks", ascending=False
).head(10))

print("\nBOTTOM 10 STUDENTS")
print(student_summary.sort_values(
    by="average_marks", ascending=True
).head(10))

student_summary.to_csv(
    "data/processed/student_summary_analysis.csv",
    index=False
)

print("\nStudent summary CSV saved successfully!")

# Save subject-wise analysis

subject_summary = df.groupby("subject_name").agg(
    average_marks=("final_marks", "mean"),
    average_attendance=("attendance", "mean"),
    average_study_hours=("study_hours", "mean")
).reset_index()

subject_summary.to_csv(
    "data/processed/subject_summary.csv",
    index=False
)

print("\nSubject summary CSV saved successfully!")
print(subject_summary)

# Save class-wise analysis

class_summary = df.groupby("class_name").agg(
    average_marks=("final_marks", "mean"),
    average_attendance=("attendance", "mean"),
    average_study_hours=("study_hours", "mean")
).reset_index()

class_summary.to_csv(
    "data/processed/class_summary.csv",
    index=False
)

print("\nClass summary CSV saved successfully!")
print(class_summary)