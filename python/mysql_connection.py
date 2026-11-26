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

# Fetch tables from MySQL
students_df = pd.read_sql("SELECT * FROM students", engine)
subjects_df = pd.read_sql("SELECT * FROM subjects", engine)
performance_df = pd.read_sql("SELECT * FROM performance", engine)

# Display records
print("\nSTUDENTS TABLE")
print(students_df.head())

print("\nSUBJECTS TABLE")
print(subjects_df)

print("\nPERFORMANCE TABLE")
print(performance_df.head())

# Display total records
print("\nTOTAL RECORDS")
print("Students:", len(students_df))
print("Subjects:", len(subjects_df))
print("Performance:", len(performance_df))

engine.dispose()