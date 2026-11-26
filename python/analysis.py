"""
analysis.py  -  Student Performance Analysis (End-to-End)
=========================================================
Pipeline:
  1. Load raw data              5. Statistical + correlation analysis
  2. Inspect data quality       6. Outlier detection
  3. Clean data                 7. Visualisation (charts -> reports/charts)
  4. Exploratory Data Analysis  8. Export cleaned data (CSV, Excel, SQL/Power BI tables)

Run from the project root:   python python/analysis.py
"""
import json
import warnings
from pathlib import Path

import matplotlib
matplotlib.use("Agg")                      # headless backend: saves charts without opening windows
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
from scipy import stats

warnings.filterwarnings("ignore")
sns.set_theme(style="whitegrid", palette="viridis")

# ----------------------------------------------------------------------------
# 0. CONFIGURATION
# ----------------------------------------------------------------------------
ROOT = Path(__file__).resolve().parents[1]
RAW_PATH = ROOT / "data" / "raw" / "student_performance_raw.csv"
PROCESSED_DIR = ROOT / "data" / "processed"
CHART_DIR = ROOT / "reports" / "charts"
REPORT_DIR = ROOT / "reports"

PASS_MARK = 40            # final marks >= 40 -> Pass
MAX_STUDY_HOURS = 20      # domain rule: > 20 hrs/week for ONE subject is treated as a data-entry error
NUM_COLS = ["Attendance", "Study_Hours", "Assignment_Marks", "Exam_Marks", "Final_Marks"]
GRADE_ORDER = ["A", "B", "C", "D", "E", "F"]


def section(title: str) -> None:
    print("\n" + "=" * 78 + f"\n{title}\n" + "=" * 78)


# ----------------------------------------------------------------------------
# 1. DATA LOADING
# ----------------------------------------------------------------------------
def load_data(path: Path = RAW_PATH) -> pd.DataFrame:
    df = pd.read_csv(path)
    print(f"Loaded {path.name}: {df.shape[0]} rows x {df.shape[1]} columns")
    return df


# ----------------------------------------------------------------------------
# 2. DATA QUALITY INSPECTION
# ----------------------------------------------------------------------------
def inspect_data(df: pd.DataFrame) -> dict:
    section("2. DATA QUALITY INSPECTION")
    print(df.head(), "\n")
    df.info()
    missing = df.isna().sum()
    print("\nMissing values per column:\n", missing[missing > 0])
    n_dup = int(df.duplicated().sum())
    print(f"\nExact duplicate rows: {n_dup}")
    return {"raw_rows": int(len(df)), "raw_missing_total": int(missing.sum()),
            "raw_duplicates": n_dup, "raw_missing_by_col": missing[missing > 0].to_dict()}


# ----------------------------------------------------------------------------
# 6. OUTLIER DETECTION (IQR method)  -  defined early because cleaning uses it
# ----------------------------------------------------------------------------
def detect_outliers_iqr(df: pd.DataFrame, cols=NUM_COLS) -> pd.DataFrame:
    """Return count of outliers per column using the 1.5 * IQR rule."""
    result = []
    for c in cols:
        s = df[c].dropna()
        q1, q3 = s.quantile(0.25), s.quantile(0.75)
        iqr = q3 - q1
        low, high = q1 - 1.5 * iqr, q3 + 1.5 * iqr
        n_out = int(((s < low) | (s > high)).sum())
        result.append({"Column": c, "Q1": q1, "Q3": q3, "IQR": iqr,
                       "Lower_Fence": low, "Upper_Fence": high,
                       "Outliers": n_out, "Outlier_%": round(100 * n_out / len(s), 2)})
    return pd.DataFrame(result).round(2)


# ----------------------------------------------------------------------------
# 3. DATA CLEANING
# ----------------------------------------------------------------------------
def clean_data(df: pd.DataFrame, quality: dict) -> pd.DataFrame:
    section("3. DATA CLEANING")
    df = df.copy()

    # 3.1 Standardise text columns (remove stray spaces, consistent casing)
    for c in ["Student_ID", "Gender", "Class", "Subject"]:
        df[c] = df[c].astype("string").str.strip()
    df["Gender"] = df["Gender"].str.title()

    # 3.2 Remove exact duplicate records
    before = len(df)
    df = df.drop_duplicates().reset_index(drop=True)
    print(f"Duplicates removed: {before - len(df)}  (rows now: {len(df)})")

    # 3.3 Outlier detection BEFORE treatment (documented for the report)
    out_before = detect_outliers_iqr(df)
    print("\nOutliers (IQR rule) BEFORE treatment:\n", out_before.to_string(index=False))
    quality["outliers_before"] = out_before.set_index("Column")["Outliers"].to_dict()

    # 3.4 Treat impossible values:
    #     Study_Hours above MAX_STUDY_HOURS is a data-entry error -> set to NaN, then impute.
    bad_hours = df["Study_Hours"] > MAX_STUDY_HOURS
    quality["invalid_study_hours"] = int(bad_hours.sum())
    print(f"\nInvalid Study_Hours (> {MAX_STUDY_HOURS}) set to NaN: {int(bad_hours.sum())}")
    df.loc[bad_hours, "Study_Hours"] = np.nan
    #     Marks and attendance must lie within 0-100.
    for c in ["Attendance", "Assignment_Marks", "Exam_Marks", "Final_Marks"]:
        df[c] = df[c].where(df[c].between(0, 100))

    # 3.5 Missing value treatment
    #   a) Gender is a student-level attribute -> copy it from the student's other records
    df["Gender"] = df.groupby("Student_ID")["Gender"].transform(lambda s: s.fillna(s.dropna().iloc[0])
                                                                  if s.notna().any() else s)
    df["Gender"] = df["Gender"].fillna("Unknown")
    #   b) Attendance is mostly a student-level habit -> student mean, else overall median
    df["Attendance"] = df["Attendance"].fillna(df.groupby("Student_ID")["Attendance"].transform("mean"))
    df["Attendance"] = df["Attendance"].fillna(df["Attendance"].median())
    #   c) Study hours / assignment / exam -> median of the same Subject (robust to skew)
    for c in ["Study_Hours", "Assignment_Marks", "Exam_Marks"]:
        df[c] = df[c].fillna(df.groupby("Subject")[c].transform("median"))
    #   d) Final marks are derived: 30% assignment + 70% exam (recomputed for every row)
    df["Final_Marks"] = (0.30 * df["Assignment_Marks"] + 0.70 * df["Exam_Marks"]).round(2)

    df[["Attendance", "Study_Hours", "Assignment_Marks", "Exam_Marks"]] = \
        df[["Attendance", "Study_Hours", "Assignment_Marks", "Exam_Marks"]].round(1)
    df["Age"] = df["Age"].astype(int)
    print("Missing values after cleaning:", int(df.isna().sum().sum()))

    # 3.6 Feature engineering (used by SQL, Power BI and insights)
    df["Pass_Fail"] = np.where(df["Final_Marks"] >= PASS_MARK, "Pass", "Fail")
    df["Grade"] = pd.cut(df["Final_Marks"], bins=[-0.01, 39.99, 49.99, 59.99, 69.99, 79.99, 100],
                         labels=["F", "E", "D", "C", "B", "A"]).astype(str)
    df["Performance_Category"] = pd.cut(df["Final_Marks"], bins=[-0.01, 49.99, 64.99, 79.99, 100],
                                        labels=["At Risk", "Average", "Good", "Excellent"]).astype(str)
    # left-closed bins: <60, 60-<75, 75-<90, 90+  (identical to the CASE logic in the SQL queries)
    df["Attendance_Band"] = pd.cut(df["Attendance"], bins=[0, 60, 75, 90, 100.01], right=False,
                                   labels=["<60%", "60-75%", "75-90%", "90-100%"]).astype(str)
    df["Study_Band"] = pd.cut(df["Study_Hours"], bins=[0, 4, 8, 12, 100],
                              labels=["0-4 hrs", "4-8 hrs", "8-12 hrs", "12+ hrs"]).astype(str)

    quality["clean_rows"] = int(len(df))
    return df


# ----------------------------------------------------------------------------
# 4. EXPLORATORY DATA ANALYSIS
# ----------------------------------------------------------------------------
def run_eda(df: pd.DataFrame) -> dict:
    section("4. EXPLORATORY DATA ANALYSIS")
    m = {}
    print("Shape:", df.shape)
    print("\nDescriptive statistics:\n", df[NUM_COLS].describe().round(2))

    m["total_records"] = int(len(df))
    m["total_students"] = int(df["Student_ID"].nunique())
    m["avg_final"] = round(df["Final_Marks"].mean(), 2)
    m["median_final"] = round(df["Final_Marks"].median(), 2)
    m["avg_attendance"] = round(df["Attendance"].mean(), 2)
    m["avg_study_hours"] = round(df["Study_Hours"].mean(), 2)
    m["pass_pct"] = round((df["Pass_Fail"] == "Pass").mean() * 100, 2)

    by_subject = df.groupby("Subject").agg(Avg_Final=("Final_Marks", "mean"),
                                           Avg_Exam=("Exam_Marks", "mean"),
                                           Avg_Assignment=("Assignment_Marks", "mean"),
                                           Pass_Rate=("Pass_Fail", lambda s: (s == "Pass").mean() * 100)
                                           ).round(2).sort_values("Avg_Final", ascending=False)
    print("\nPerformance by subject:\n", by_subject)
    m["by_subject"] = by_subject.to_dict("index")

    by_class = df.groupby("Class").agg(Avg_Final=("Final_Marks", "mean"),
                                       Pass_Rate=("Pass_Fail", lambda s: (s == "Pass").mean() * 100),
                                       Students=("Student_ID", "nunique")).round(2).sort_values("Avg_Final", ascending=False)
    print("\nPerformance by class:\n", by_class)
    m["by_class"] = by_class.to_dict("index")

    by_gender = df[df["Gender"] != "Unknown"].groupby("Gender").agg(
        Avg_Final=("Final_Marks", "mean"),
        Pass_Rate=("Pass_Fail", lambda s: (s == "Pass").mean() * 100)).round(2)
    print("\nPerformance by gender:\n", by_gender)
    m["by_gender"] = by_gender.to_dict("index")

    by_att = df.groupby("Attendance_Band").agg(Avg_Final=("Final_Marks", "mean"),
                                               Records=("Final_Marks", "size")).round(2)
    by_att = by_att.reindex([b for b in ["<60%", "60-75%", "75-90%", "90-100%"] if b in by_att.index])
    print("\nPerformance by attendance band:\n", by_att)
    m["by_attendance_band"] = by_att.to_dict("index")

    by_study = df.groupby("Study_Band").agg(Avg_Exam=("Exam_Marks", "mean"),
                                            Records=("Exam_Marks", "size")).round(2)
    by_study = by_study.reindex([b for b in ["0-4 hrs", "4-8 hrs", "8-12 hrs", "12+ hrs"] if b in by_study.index])
    print("\nExam marks by weekly study-hour band:\n", by_study)
    m["by_study_band"] = by_study.to_dict("index")

    grade_dist = df["Grade"].value_counts().reindex(GRADE_ORDER).fillna(0).astype(int)
    print("\nGrade distribution:\n", grade_dist)
    m["grade_dist"] = grade_dist.to_dict()

    # Student-level view: who needs academic support?
    student = df.groupby("Student_ID").agg(
        Class=("Class", "first"), Gender=("Gender", "first"),
        Avg_Final=("Final_Marks", "mean"), Avg_Attendance=("Attendance", "mean"),
        Avg_Study_Hours=("Study_Hours", "mean"),
        Subjects_Failed=("Pass_Fail", lambda s: int((s == "Fail").sum())))
    # Support rule: overall average below 50 OR failing 2+ subjects OR average attendance below 75%
    # (evaluated on UNROUNDED averages so Python and SQL give identical counts)
    student["Needs_Support"] = ((student["Avg_Final"] < 50) | (student["Subjects_Failed"] >= 2) |
                                (student["Avg_Attendance"] < 75))
    student[["Avg_Final", "Avg_Attendance", "Avg_Study_Hours"]] = \
        student[["Avg_Final", "Avg_Attendance", "Avg_Study_Hours"]].round(2)
    m["students_need_support"] = int(student["Needs_Support"].sum())
    m["students_need_support_pct"] = round(student["Needs_Support"].mean() * 100, 2)
    m["top_students"] = student.sort_values("Avg_Final", ascending=False).head(5)["Avg_Final"].to_dict()
    print(f"\nStudents needing academic support: {m['students_need_support']} "
          f"({m['students_need_support_pct']}%)")
    print(student.sort_values("Avg_Final").head(10))
    m["_student"] = student        # kept in-memory for charts/exports (removed before JSON dump)
    return m


# ----------------------------------------------------------------------------
# 5. STATISTICAL & CORRELATION ANALYSIS
# ----------------------------------------------------------------------------
def run_statistics(df: pd.DataFrame, m: dict) -> pd.DataFrame:
    section("5. STATISTICAL & CORRELATION ANALYSIS")
    corr = df[NUM_COLS + ["Age"]].corr(method="pearson").round(3)
    print("Pearson correlation matrix:\n", corr)

    # Pearson & Spearman between key drivers and outcome
    for x, y in [("Attendance", "Final_Marks"), ("Study_Hours", "Exam_Marks"), ("Study_Hours", "Final_Marks")]:
        r, p = stats.pearsonr(df[x], df[y])
        rho, p_s = stats.spearmanr(df[x], df[y])
        print(f"{x} vs {y}: Pearson r={r:.3f} (p={p:.2e}) | Spearman rho={rho:.3f} (p={p_s:.2e})")
        m[f"corr_{x}_{y}"] = round(float(r), 3)
        m[f"p_{x}_{y}"] = float(p)

    # Simple linear regression: marks gained per extra study hour / attendance point
    sl = stats.linregress(df["Study_Hours"], df["Exam_Marks"])
    m["exam_per_study_hour"] = round(float(sl.slope), 2)
    sl2 = stats.linregress(df["Attendance"], df["Final_Marks"])
    m["final_per_attendance_pt"] = round(float(sl2.slope), 3)
    m["r2_attendance_final"] = round(float(sl2.rvalue ** 2), 3)
    print(f"Each extra weekly study hour -> {sl.slope:.2f} more exam marks (R2={sl.rvalue**2:.3f})")
    print(f"Each +1% attendance -> {sl2.slope:.3f} more final marks (R2={sl2.rvalue**2:.3f})")

    # One-way ANOVA: do subject means differ?
    groups = [g["Final_Marks"].values for _, g in df.groupby("Subject")]
    f_stat, p_anova = stats.f_oneway(*groups)
    m["anova_subject_F"], m["anova_subject_p"] = round(float(f_stat), 2), float(p_anova)
    print(f"ANOVA (Final_Marks across subjects): F={f_stat:.2f}, p={p_anova:.2e}")

    # Welch t-test: gender difference in final marks
    g = df[df["Gender"].isin(["Male", "Female"])]
    t_stat, p_t = stats.ttest_ind(g.loc[g.Gender == "Male", "Final_Marks"],
                                  g.loc[g.Gender == "Female", "Final_Marks"], equal_var=False)
    m["ttest_gender_t"], m["ttest_gender_p"] = round(float(t_stat), 3), float(p_t)
    print(f"Welch t-test (Male vs Female final marks): t={t_stat:.2f}, p={p_t:.3f}")

    skew = df[NUM_COLS].skew().round(3)
    print("\nSkewness:\n", skew)
    return corr


# ----------------------------------------------------------------------------
# 7. VISUALISATION
# ----------------------------------------------------------------------------
def _save(fig, name):
    CHART_DIR.mkdir(parents=True, exist_ok=True)
    fig.tight_layout()
    fig.savefig(CHART_DIR / name, dpi=130)
    plt.close(fig)


def make_charts(df: pd.DataFrame, corr: pd.DataFrame, m: dict) -> None:
    section("7. DATA VISUALISATION")
    # 01 Distribution of final marks
    fig, ax = plt.subplots(figsize=(8, 5))
    sns.histplot(df["Final_Marks"], bins=25, kde=True, color="#2a788e", ax=ax)
    ax.axvline(PASS_MARK, color="red", ls="--", label=f"Pass mark ({PASS_MARK})")
    ax.axvline(df["Final_Marks"].mean(), color="black", ls=":", label="Mean")
    ax.set(title="Distribution of Final Marks", xlabel="Final Marks"); ax.legend()
    _save(fig, "01_final_marks_distribution.png")

    # 02 Average final marks by subject
    order = df.groupby("Subject")["Final_Marks"].mean().sort_values(ascending=False)
    fig, ax = plt.subplots(figsize=(8, 5))
    sns.barplot(x=order.index, y=order.values, palette="viridis", ax=ax)
    for i, v in enumerate(order.values):
        ax.text(i, v + 0.5, f"{v:.1f}", ha="center")
    ax.set(title="Average Final Marks by Subject", xlabel="", ylabel="Average Final Marks")
    plt.setp(ax.get_xticklabels(), rotation=15)
    _save(fig, "02_avg_marks_by_subject.png")

    # 03 Boxplot by subject
    fig, ax = plt.subplots(figsize=(9, 5))
    sns.boxplot(data=df, x="Subject", y="Final_Marks", order=order.index, palette="viridis", ax=ax)
    ax.set(title="Final Marks Spread by Subject")
    plt.setp(ax.get_xticklabels(), rotation=15)
    _save(fig, "03_boxplot_marks_by_subject.png")

    # 04 Class performance
    cls = df.groupby("Class")["Final_Marks"].mean().sort_index()
    fig, ax = plt.subplots(figsize=(7, 5))
    sns.barplot(x=cls.index, y=cls.values, palette="mako", ax=ax)
    for i, v in enumerate(cls.values):
        ax.text(i, v + 0.5, f"{v:.1f}", ha="center")
    ax.set(title="Average Final Marks by Class", xlabel="", ylabel="Average Final Marks")
    _save(fig, "04_avg_marks_by_class.png")

    # 05 Attendance vs final marks
    fig, ax = plt.subplots(figsize=(8, 5))
    sns.regplot(data=df, x="Attendance", y="Final_Marks", scatter_kws={"alpha": .35, "s": 18},
                line_kws={"color": "red"}, ax=ax)
    ax.set(title=f"Attendance vs Final Marks (r = {m['corr_Attendance_Final_Marks']})")
    _save(fig, "05_attendance_vs_final.png")

    # 06 Study hours vs exam marks
    fig, ax = plt.subplots(figsize=(8, 5))
    sns.regplot(data=df, x="Study_Hours", y="Exam_Marks", scatter_kws={"alpha": .35, "s": 18},
                line_kws={"color": "red"}, ax=ax)
    ax.set(title=f"Weekly Study Hours vs Exam Marks (r = {m['corr_Study_Hours_Exam_Marks']})")
    _save(fig, "06_study_hours_vs_exam.png")

    # 07 Correlation heatmap
    fig, ax = plt.subplots(figsize=(8, 6))
    sns.heatmap(corr, annot=True, fmt=".2f", cmap="coolwarm", center=0, ax=ax)
    ax.set_title("Correlation Heatmap")
    _save(fig, "07_correlation_heatmap.png")

    # 08 Grade distribution
    gd = df["Grade"].value_counts().reindex(GRADE_ORDER).fillna(0)
    fig, ax = plt.subplots(figsize=(7, 5))
    sns.barplot(x=gd.index, y=gd.values, palette="viridis", ax=ax)
    ax.set(title="Grade Distribution", xlabel="Grade", ylabel="Number of Records")
    _save(fig, "08_grade_distribution.png")

    # 09 Gender comparison
    fig, ax = plt.subplots(figsize=(7, 5))
    sns.boxplot(data=df[df.Gender != "Unknown"], x="Gender", y="Final_Marks", palette="Set2", ax=ax)
    ax.set(title="Final Marks by Gender")
    _save(fig, "09_gender_comparison.png")

    # 10 Attendance band impact
    band = df.groupby("Attendance_Band")["Final_Marks"].mean()
    band = band.reindex([b for b in ["<60%", "60-75%", "75-90%", "90-100%"] if b in band.index])
    fig, ax = plt.subplots(figsize=(7, 5))
    sns.barplot(x=band.index, y=band.values, palette="rocket", ax=ax)
    for i, v in enumerate(band.values):
        ax.text(i, v + 0.5, f"{v:.1f}", ha="center")
    ax.set(title="Average Final Marks by Attendance Band", xlabel="Attendance", ylabel="Average Final Marks")
    _save(fig, "10_attendance_band_impact.png")

    # 11 Outlier boxplots (cleaned data)
    fig, axes = plt.subplots(1, 5, figsize=(16, 4))
    for ax, c in zip(axes, NUM_COLS):
        sns.boxplot(y=df[c], ax=ax, color="#5ec962"); ax.set_title(c)
    fig.suptitle("Outlier Check After Cleaning")
    _save(fig, "11_outlier_boxplots.png")

    # 12 Pass rate by subject
    pr = df.groupby("Subject")["Pass_Fail"].apply(lambda s: (s == "Pass").mean() * 100).sort_values()
    fig, ax = plt.subplots(figsize=(8, 5))
    sns.barplot(x=pr.values, y=pr.index, palette="crest", ax=ax)
    ax.set(title="Pass Percentage by Subject", xlabel="Pass %", ylabel="")
    _save(fig, "12_pass_rate_by_subject.png")
    print(f"12 charts saved to {CHART_DIR}")


# ----------------------------------------------------------------------------
# 8. EXPORT
# ----------------------------------------------------------------------------
def export_data(df: pd.DataFrame, m: dict, outliers_after: pd.DataFrame) -> None:
    section("8. EXPORTING CLEANED DATA")
    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)
    cols = ["Student_ID", "Gender", "Age", "Class", "Subject", "Attendance", "Study_Hours",
            "Assignment_Marks", "Exam_Marks", "Final_Marks", "Grade", "Pass_Fail",
            "Performance_Category", "Attendance_Band", "Study_Band"]
    df[cols].to_csv(PROCESSED_DIR / "student_performance_cleaned.csv", index=False)

    # Star-schema tables (used for MySQL inserts and the Power BI data model)
    dim_students = df.groupby("Student_ID", as_index=False).agg(
        Gender=("Gender", "first"), Age=("Age", "first"), Class=("Class", "first"))
    subjects = sorted(df["Subject"].unique())
    dim_subjects = pd.DataFrame({"Subject_ID": range(1, len(subjects) + 1), "Subject_Name": subjects})
    fact = df.merge(dim_subjects, left_on="Subject", right_on="Subject_Name")
    fact = fact[["Student_ID", "Subject_ID", "Attendance", "Study_Hours", "Assignment_Marks",
                 "Exam_Marks", "Final_Marks", "Grade", "Pass_Fail"]].sort_values(
        ["Student_ID", "Subject_ID"]).reset_index(drop=True)
    fact.insert(0, "Performance_ID", range(1, len(fact) + 1))
    dim_students.to_csv(PROCESSED_DIR / "dim_students.csv", index=False)
    dim_subjects.to_csv(PROCESSED_DIR / "dim_subjects.csv", index=False)
    fact.to_csv(PROCESSED_DIR / "fact_performance.csv", index=False)

    student = m["_student"].reset_index()
    student.to_csv(PROCESSED_DIR / "student_summary.csv", index=False)

    # Excel workbook with summary sheets (Excel part of the tech stack)
    with pd.ExcelWriter(PROCESSED_DIR / "student_performance_summary.xlsx", engine="openpyxl") as xw:
        df[cols].to_excel(xw, sheet_name="Cleaned_Data", index=False)
        df.groupby("Subject")[["Attendance", "Study_Hours", "Assignment_Marks", "Exam_Marks", "Final_Marks"]] \
            .mean().round(2).reset_index().to_excel(xw, sheet_name="Subject_Summary", index=False)
        df.groupby("Class")[["Attendance", "Study_Hours", "Assignment_Marks", "Exam_Marks", "Final_Marks"]] \
            .mean().round(2).reset_index().to_excel(xw, sheet_name="Class_Summary", index=False)
        student.to_excel(xw, sheet_name="Student_Summary", index=False)
        student[student["Needs_Support"]].sort_values("Avg_Final").to_excel(xw, sheet_name="Needs_Support", index=False)
        outliers_after.to_excel(xw, sheet_name="Outlier_Report", index=False)
        for ws in xw.book.worksheets:                     # tidy column widths
            for col in ws.columns:
                ws.column_dimensions[col[0].column_letter].width = max(12, len(str(col[0].value)) + 4)
            ws.freeze_panes = "A2"
    print("Saved to data/processed/: student_performance_cleaned.csv, dim_students.csv, dim_subjects.csv,\n"
          "  fact_performance.csv, student_summary.csv, student_performance_summary.xlsx")


# ----------------------------------------------------------------------------
# MAIN
# ----------------------------------------------------------------------------
def main() -> dict:
    raw = load_data()
    quality = inspect_data(raw)
    df = clean_data(raw, quality)
    m = run_eda(df)
    corr = run_statistics(df, m)
    section("6. OUTLIER DETECTION AFTER CLEANING")
    outliers_after = detect_outliers_iqr(df)
    print(outliers_after.to_string(index=False))
    m["outliers_after"] = outliers_after.set_index("Column")["Outliers"].to_dict()
    make_charts(df, corr, m)
    export_data(df, m, outliers_after)

    m.update(quality)
    student = m.pop("_student")
    m["low_performers_examples"] = student.sort_values("Avg_Final").head(5)["Avg_Final"].to_dict()
    with open(REPORT_DIR / "summary_metrics.json", "w") as f:
        json.dump(m, f, indent=2, default=float)
    section("PIPELINE COMPLETE")
    return m


if __name__ == "__main__":
    main()
