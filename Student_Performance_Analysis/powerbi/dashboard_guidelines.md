# Power BI Dashboard Guidelines

A `.pbix` file cannot be generated outside Power BI Desktop, so this guide gives everything needed to build the
dashboard manually in about 45-60 minutes: data model, DAX, layout, slicers and click-by-click steps.

**Requirements:** Power BI Desktop (free, Windows). Files used: `data/processed/` -> `fact_performance.csv`,
`dim_students.csv`, `dim_subjects.csv` (and optionally `student_summary.csv`).

---

## 1. Data model (star schema)

```
        Dim_Students (1) ───────< Fact_Performance >─────── (1) Dim_Subjects
        Student_ID (PK)            Student_ID (FK)             Subject_ID (PK)
        Gender                     Subject_ID (FK)             Subject_Name
        Age                        Attendance
        Class                      Study_Hours
                                   Assignment_Marks
                                   Exam_Marks
                                   Final_Marks
                                   Grade, Pass_Fail
```

| Table | Source file | Rows | Role |
|---|---|---|---|
| Fact_Performance | fact_performance.csv | 1,100 | Fact (measures) |
| Dim_Students | dim_students.csv | 220 | Dimension |
| Dim_Subjects | dim_subjects.csv | 5 | Dimension |

**Relationships** (Model view -> Manage relationships):

| From (many) | To (one) | Cardinality | Cross-filter direction |
|---|---|---|---|
| Fact_Performance[Student_ID] | Dim_Students[Student_ID] | Many-to-one | Single |
| Fact_Performance[Subject_ID] | Dim_Subjects[Subject_ID] | Many-to-one | Single |

Optional: import `student_summary.csv` as **Student_Summary** and relate `Student_Summary[Student_ID]` ->
`Dim_Students[Student_ID]` (one-to-one) to list flagged students in a table.

---

## 2. Step-by-step build instructions

### Step 1 - Load the data
1. Open Power BI Desktop -> **Home -> Get data -> Text/CSV**.
2. Select `fact_performance.csv` -> **Transform Data** (not Load).
3. In Power Query confirm data types: `Attendance`, `Study_Hours`, `Assignment_Marks`, `Exam_Marks`, `Final_Marks`
   = Decimal Number; `Performance_ID`, `Subject_ID` = Whole Number; the rest = Text. Click **Close & Apply**.
4. Repeat Get data for `dim_students.csv` (Age = Whole Number) and `dim_subjects.csv`.
5. Rename the queries to **Fact_Performance**, **Dim_Students**, **Dim_Subjects**.

### Step 2 - Build the model
1. Go to **Model view**. Power BI usually auto-detects both relationships; if not, drag
   `Fact_Performance[Student_ID]` onto `Dim_Students[Student_ID]` and `Fact_Performance[Subject_ID]` onto
   `Dim_Subjects[Subject_ID]`.
2. Check each is **Many to one (*:1)** with **Single** cross-filter direction.
3. Hide the foreign keys (`Student_ID`, `Subject_ID`, `Performance_ID` in the fact table) from Report view.

### Step 3 - Create calculated columns (Fact_Performance)
Table tools -> **New column**. Paste each formula separately (see section 3).

### Step 4 - Create measures
Create a table to hold measures: **Home -> Enter data -> name it `_Measures`** (leave blank, load), then
**New measure** for each measure in section 3 and choose `_Measures` as the home table.

### Step 5 - Build the pages
Follow the layouts in section 4. Set the canvas to 16:9 (View -> Page view -> Fit to page), and pick a theme
(View -> Themes) - the colour palette used here is deep blue `#1F4E79`, teal `#2A9D8F`, amber `#F4A261`, red `#E63946`.

### Step 6 - Add slicers and interactions
Insert slicers (section 5), then use **Format -> Edit interactions** so slicers filter every visual on the page.
Sync slicers across pages: View -> **Sync slicers**.

### Step 7 - Polish and publish
Add titles, number formats (1 decimal), tooltips, and a title banner. Save as `powerbi/Student_Performance_Dashboard.pbix`.
Optional: **Publish** to Power BI Service and pin to a dashboard.

---

## 3. DAX

### 3.1 Calculated columns (Fact_Performance)

```DAX
Attendance Band =
SWITCH(
    TRUE(),
    Fact_Performance[Attendance] < 60, "<60%",
    Fact_Performance[Attendance] < 75, "60-75%",
    Fact_Performance[Attendance] < 90, "75-90%",
    "90-100%"
)

Attendance Band Sort =
SWITCH(
    TRUE(),
    Fact_Performance[Attendance] < 60, 1,
    Fact_Performance[Attendance] < 75, 2,
    Fact_Performance[Attendance] < 90, 3,
    4
)

Study Band =
SWITCH(
    TRUE(),
    Fact_Performance[Study_Hours] <= 4, "0-4 hrs",
    Fact_Performance[Study_Hours] <= 8, "4-8 hrs",
    Fact_Performance[Study_Hours] <= 12, "8-12 hrs",
    "12+ hrs"
)

Study Band Sort =
SWITCH(
    TRUE(),
    Fact_Performance[Study_Hours] <= 4, 1,
    Fact_Performance[Study_Hours] <= 8, 2,
    Fact_Performance[Study_Hours] <= 12, 3,
    4
)

Performance Category =
SWITCH(
    TRUE(),
    Fact_Performance[Final_Marks] < 50, "At Risk",
    Fact_Performance[Final_Marks] < 65, "Average",
    Fact_Performance[Final_Marks] < 80, "Good",
    "Excellent"
)
```
Then select `Attendance Band` -> **Column tools -> Sort by column -> Attendance Band Sort**, and do the same for
`Study Band` -> `Study Band Sort`, so bands appear in the correct order.

### 3.2 Measures

```DAX
Total Students = DISTINCTCOUNT(Fact_Performance[Student_ID])

Total Records = COUNTROWS(Fact_Performance)

Avg Final Marks = AVERAGE(Fact_Performance[Final_Marks])

Avg Exam Marks = AVERAGE(Fact_Performance[Exam_Marks])

Avg Assignment Marks = AVERAGE(Fact_Performance[Assignment_Marks])

Avg Attendance = AVERAGE(Fact_Performance[Attendance])

Avg Study Hours = AVERAGE(Fact_Performance[Study_Hours])

Pass Count =
CALCULATE(COUNTROWS(Fact_Performance), Fact_Performance[Pass_Fail] = "Pass")

Fail Count =
CALCULATE(COUNTROWS(Fact_Performance), Fact_Performance[Pass_Fail] = "Fail")

Pass % = DIVIDE([Pass Count], [Total Records])

Fail % = DIVIDE([Fail Count], [Total Records])

-- Students flagged for academic support:
-- average < 50  OR  failed 2+ subjects  OR  average attendance < 75
Students Needing Support =
VAR StudentTable =
    ADDCOLUMNS(
        VALUES(Dim_Students[Student_ID]),
        "@AvgFinal", CALCULATE(AVERAGE(Fact_Performance[Final_Marks])),
        "@AvgAtt",   CALCULATE(AVERAGE(Fact_Performance[Attendance])),
        "@Fails",    COALESCE(CALCULATE(COUNTROWS(Fact_Performance),
                                        Fact_Performance[Pass_Fail] = "Fail"), 0)
    )
RETURN
    COUNTROWS(
        FILTER(StudentTable, [@AvgFinal] < 50 || [@Fails] >= 2 || [@AvgAtt] < 75)
    )

% Students Needing Support = DIVIDE([Students Needing Support], [Total Students])

-- Best / worst subject (text KPI cards)
Top Subject =
VAR T = ADDCOLUMNS(VALUES(Dim_Subjects[Subject_Name]), "@Avg", CALCULATE([Avg Final Marks]))
RETURN MAXX(TOPN(1, T, [@Avg], DESC), Dim_Subjects[Subject_Name])

Weakest Subject =
VAR T = ADDCOLUMNS(VALUES(Dim_Subjects[Subject_Name]), "@Avg", CALCULATE([Avg Final Marks]))
RETURN MAXX(TOPN(1, T, [@Avg], ASC), Dim_Subjects[Subject_Name])

-- Benchmark for conditional formatting / reference lines
Overall Avg Final Marks = CALCULATE([Avg Final Marks], ALL(Fact_Performance), ALL(Dim_Students), ALL(Dim_Subjects))

Variance vs Overall = [Avg Final Marks] - [Overall Avg Final Marks]

-- Correlation between attendance and final marks (card or tooltip)
Attendance-Marks Correlation =
VAR Pairs = SUMMARIZE(Fact_Performance, Fact_Performance[Performance_ID],
                      Fact_Performance[Attendance], Fact_Performance[Final_Marks])
VAR MeanX = AVERAGEX(Pairs, Fact_Performance[Attendance])
VAR MeanY = AVERAGEX(Pairs, Fact_Performance[Final_Marks])
VAR Cov   = SUMX(Pairs, (Fact_Performance[Attendance] - MeanX) * (Fact_Performance[Final_Marks] - MeanY))
VAR VarX  = SUMX(Pairs, (Fact_Performance[Attendance] - MeanX) ^ 2)
VAR VarY  = SUMX(Pairs, (Fact_Performance[Final_Marks] - MeanY) ^ 2)
RETURN DIVIDE(Cov, SQRT(VarX * VarY))
```

**Values to sanity-check against (no slicers applied):** Total Students 220 | Total Records 1,100 |
Avg Final Marks 58.55 | Pass % 92.64% | Avg Attendance 82.02 | Avg Study Hours 6.09 |
Students Needing Support 70 | Top Subject English | Weakest Subject Mathematics | Correlation 0.311.

---

## 4. Dashboard design and layout (3 pages)

Canvas 1280 x 720. Top banner (title + subtitle) 60 px; slicer strip beneath; KPI row; two rows of charts.

### Page 1 - Executive Overview

```
┌──────────────────────────────────────────────────────────────────────────┐
│  STUDENT PERFORMANCE DASHBOARD                                           │
├──────────────────────────────────────────────────────────────────────────┤
│ [Class ▼] [Gender ▼] [Subject ▼]                                          │
├─────────┬─────────┬─────────┬─────────┬─────────┬─────────────────────────┤
│ Total   │ Avg     │ Pass %  │ Avg     │ Students│ Top / Weakest           │
│ Students│ Final   │         │ Attend. │ Needing │ Subject cards           │
│  220    │ 58.55   │ 92.64%  │ 82.0%   │ Support │                         │
├─────────┴─────────┴─────────┴─────────┴─────────┴─────────────────────────┤
│ Avg Final Marks by Subject (bar)   │ Grade Distribution (column)          │
├────────────────────────────────────┼──────────────────────────────────────┤
│ Avg Final Marks & Pass % by Class  │ Pass vs Fail (donut)                 │
│ (clustered column + line)          │                                      │
└──────────────────────────────────────────────────────────────────────────┘
```

| Visual | Type | Fields |
|---|---|---|
| KPI cards (x6) | Card / Card (new) | Total Students, Avg Final Marks, Pass %, Avg Attendance, Students Needing Support, Top Subject / Weakest Subject |
| Avg marks by subject | Clustered bar | Axis: Dim_Subjects[Subject_Name]; Values: Avg Final Marks (sort descending; data labels on) |
| Grade distribution | Clustered column | Axis: Fact_Performance[Grade] (sorted A-F); Values: Total Records |
| Class performance | Line and clustered column | Shared axis: Dim_Students[Class]; Column: Avg Final Marks; Line: Pass % |
| Pass vs fail | Donut | Legend: Fact_Performance[Pass_Fail]; Values: Total Records |

### Page 2 - Drivers of Performance

| Visual | Type | Fields |
|---|---|---|
| Attendance impact | Column chart | Axis: Attendance Band (sorted by Attendance Band Sort); Values: Avg Final Marks |
| Study time impact | Column chart | Axis: Study Band; Values: Avg Exam Marks |
| Attendance vs marks | Scatter | X: Attendance; Y: Final_Marks (averaged); Details: Performance_ID; add trend line (Analytics pane) |
| Study hours vs exam | Scatter | X: Study_Hours; Y: Exam_Marks; add trend line |
| Subject x Class heatmap | Matrix | Rows: Class; Columns: Subject_Name; Values: Avg Final Marks; conditional formatting -> background colour scale (red low, green high) |
| Gender comparison | Clustered column | Axis: Gender; Values: Avg Final Marks, Pass % |
| Correlation card | Card | Attendance-Marks Correlation |

### Page 3 - Student Support (action page)

| Visual | Type | Fields |
|---|---|---|
| KPI cards | Card | Students Needing Support, % Students Needing Support, Fail Count |
| Support list | Table | Student_Summary: Student_ID, Class, Avg_Final, Avg_Attendance, Avg_Study_Hours, Subjects_Failed; filter visual: Needs_Support = True; sort Avg_Final ascending; data bars on Avg_Final |
| Performance category mix | 100% stacked bar | Axis: Class; Legend: Performance Category; Values: Total Records |
| Fails by subject | Bar | Axis: Subject_Name; Values: Fail Count |
| Top 10 students | Table | Student_ID, Avg_Final with Top N filter (Top 10 by Avg_Final) |

---

## 5. Slicers and filters

| Slicer | Field | Style | Notes |
|---|---|---|---|
| Class | Dim_Students[Class] | Tile / buttons | Multi-select |
| Gender | Dim_Students[Gender] | Dropdown | |
| Subject | Dim_Subjects[Subject_Name] | Dropdown | |
| Grade | Fact_Performance[Grade] | Tile | Pages 1-2 |
| Attendance Band | Fact_Performance[Attendance Band] | Tile | Page 2 |
| Final Marks range | Fact_Performance[Final_Marks] | Between (numeric range) | Page 2 |

Use **Sync slicers** for Class, Gender, Subject so selections persist across pages. Add a **Clear all slicers**
bookmark button. Page-level filters: none (show all data by default). Add **drill-through** from Page 1 class chart to Page 3.

---

## 6. Formatting checklist
- Consistent palette (max 4-5 colours), red only for risk/fail.
- Format all averages to 1-2 decimals and percentages to 1 decimal.
- Turn on data labels for bar/column charts, add axis titles, and give each visual a descriptive title.
- Add a text box on each page with the key takeaway (e.g. "Mathematics is the weakest subject in every class").
- Test every slicer combination; verify KPI values against section 3 reference numbers.
- Take a screenshot of each page and save in `powerbi/` for the README.
