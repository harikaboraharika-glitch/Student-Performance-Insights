import pandas as pd
from sqlalchemy import create_engine

# MySQL connection
username = "root"
password = "Lakshmi123"
host = "localhost"
database = "student_performance_db"

engine = create_engine(
    f"mysql+pymysql://{username}:{password}@{host}/{database}"
)

# Fetch tables
students_df = pd.read_sql("SELECT * FROM students", engine)
subjects_df = pd.read_sql("SELECT * FROM subjects", engine)
performance_df = pd.read_sql("SELECT * FROM performance", engine)

# Merge performance with students
merged_df = pd.merge(
    performance_df,
    students_df,
    on="student_id",
    how="inner"
)

# Merge with subjects
merged_df = pd.merge(
    merged_df,
    subjects_df,
    on="subject_id",
    how="inner"
)

# Display combined data
print("\nCOMBINED DATA")
print(merged_df.head(10))

print("\nTotal Records:", len(merged_df))
print("\nColumns:")
print(merged_df.columns.tolist())

engine.dispose()
# Save combined data
merged_df.to_csv(
    "data/processed/student_performance_merged.csv",
    index=False
)

print("\nCombined dataset saved successfully!")