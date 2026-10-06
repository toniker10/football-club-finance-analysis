# Football Club Season Finance: Excel → SQL → Statistics → Power BI

A small amateur football club tracked its whole season in one Excel workbook. This project checks that workbook, loads it into a SQL database with quality controls, analyses it with descriptive statistics, and presents the result in a four-page Power BI report.

**Main finding:** the club ends the season with a surplus of **6,167 EUR (14.7% of revenue)**, but **two sources provide 95.2% of its revenue**. Losing the largest one would turn the surplus into a loss of **13,833 EUR**.

---

## The problem

The club's finances lived in a spreadsheet full of formulas. Nobody could answer four basic questions with confidence:

1. Is the club financially safe this season?
2. Where does the money come from, and how dependent is the club on one source?
3. Where does the money go?
4. What does one match cost, at home and away?

There was also no proof that the spreadsheet itself was correct, and no visual summary a club board or a sponsor could read in a minute.

## What the data says

| Question | Answer |
|---|---|
| Is the club safe? | Revenue 42,000 EUR, expenses 35,833 EUR, **surplus 6,167 EUR** (margin 14.7%). The surplus covers about **1.7 months** of expenses. |
| How dependent is it on one source? | Fundraising Dinners (20,000) and Village Funding (20,000) are **95.2%** of revenue. Sponsorships add 2,000. Ticket sales and other revenue are 0. **Without the largest source the club ends 13,833 EUR in the red.** |
| Where does the money go? | Salaries (coaches 13,000 + players 12,000) are **69.8%** of expenses. The 3 largest categories (coaching staff, player salaries, equipment) are **81.4%**. 7 of the 17 expense categories cost nothing. |
| What does a match cost? | A **home match costs a flat 140 EUR** (referees and match doctor). An away match costs only the **fuel for the trip: 12 to 156 EUR, 96.9 EUR on average**. Total match-day cost for 14 matches is 1,658 EUR, of which travel is 678 EUR for 4,520 vehicle km. |

**What this suggests (from the data only):**
- The club's biggest risk is revenue concentration, not spending. The two large sources are one-season amounts, so their renewal decides the next season.
- The cushion is thin. In the what-if sheet, revenue **−10%** and expenses **+10%** at the same time give a **loss of about 1,616 EUR**. Either change alone still leaves a surplus (1,967 EUR and 2,584 EUR).
- Match costs are small and predictable. Cost control should focus on payroll and equipment, not on match days.

## Pipeline

| Step | Folder | What it does | Why |
|---|---|---|---|
| 1. Excel | `01_excel/` | The club's own workbook: 14 tables (revenue, expenses, staff, players, travel, equipment, matches, stadium...) with formulas and a built-in `Checks` sheet (65 checks). | Source of truth. |
| 2. SQL | `02_sql/` | The same data in a SQLite database with constraints, 3 triggers, 7 views and **80 control checks**. `build_and_test.py` rebuilds the database and tests it. | Proves the numbers are consistent and protects them from bad edits. |
| 3. Statistics | `03_statistics/` | A five-sheet workbook: Summary, Revenue, Expenses, Matches, What_If. Descriptive statistics only. | Turns tables into answers: shares, concentration, averages, scenarios. |
| 4. Power BI | `04_powerbi/` | A four-page report built straight on the Excel tables, with 21 DAX measures. | Lets a non-technical reader see the findings. |

### Why only descriptive statistics
The data covers one season and the whole club, not a sample. Means, shares, minimum/maximum and scenarios are meaningful. Hypothesis tests and confidence intervals would be misleading, so they are not used.

## Data validation

- **Excel ↔ SQL:** all 11 data tables were compared cell by cell. 0 differences, including the calculated columns.
- **Excel formulas:** recalculated independently. 0 errors, 0 differences from the stored values, all 65 workbook checks OK.
- **SQL control checks:** 80 of 80 OK. They include reconciliations that need no typed-in totals, for example "sum of the Staff table = Coaching Staff category in Expenses".
- **Constraint tests:** 12 of 12 invalid inserts or updates are rejected (unknown source, negative amount, travel on a home match, and others).
- **Mutation tests:** 6 of 6 changes made in a single source table (a salary, a stadium cost, a distance, and so on) are caught by the control checks. This shows the checks really work.
- **Power BI:** every number in the report was compared with the Excel source.

## Power BI report

**Model:** 7 tables loaded from the Excel file (`tbl_Revenue`, `tbl_Expenses`, `tbl_Staff`, `tbl_Players`, `tbl_Travel`, `tbl_Match_Costs`, `tbl_Team_Info`) and **one relationship**: `tbl_Travel[Match_ID]` → `tbl_Match_Costs[Match_ID]` (many to one, single direction). It lets the fuel cost of each trip reach the right match. All 21 measures are in `DAX_Measures.txt`.

### 1. Overview: is the club safe?
Six cards (revenue, expenses, net result, net margin, net result if the largest source is lost, reserve in months) and a column chart of revenue against expenses.

![Overview](04_powerbi/screenshots/01_overview.png)

### 2. Revenue: where does the money come from?
Bar chart and table by source with share of total. Cards: top 2 sources share (95.2%) and active sources (3).

![Revenue](04_powerbi/screenshots/02_revenue.png)

### 3. Expenses: where does the money go?
Bar chart and table by category, filtered to categories with a cost above zero (10 of 17). Cards: top 3 categories share (81.4%), payroll cost (25,000), payroll share (69.8%).

![Expenses](04_powerbi/screenshots/03_expenses.png)

### 4. Matches: what does a match cost?
Cost per match (away matches A01–A07, then home matches H01–H07), average cost home vs away, and cards for league matches (14), match-day cost (1,658), travel cost (678) and vehicle km (4,520).

![Matches](04_powerbi/screenshots/04_matches.png)

> The report was built in a Greek-language Power BI. A card showing "42,000 χιλ." means 42,000 (χιλ. = thousand). Decimal commas follow the Greek locale.

## Repository structure

```
football-club-finance/
├── README.md
├── 01_excel/
│   └── Football_Club_Finance_Dataset.xlsx
├── 02_sql/
│   ├── 01_schema.sql
│   ├── 02_data.sql
│   ├── 03_views.sql
│   ├── 04_validation.sql
│   └── build_and_test.py
├── 03_statistics/
│   └── Football_Club_Statistics.xlsx
└── 04_powerbi/
    ├── Football_Club_Finance.pbix
    ├── DAX_Measures.txt
    └── screenshots/

## How to run it

**SQL (Python 3, standard library only):**
```
cd 02_sql
python build_and_test.py
```
It builds `football_club_finance.db` from the three SQL files and runs all tests. The expected last line is `RESULT: ALL PASSED`. `04_validation.sql` contains read-only queries you can run in any SQLite client.

**Power BI:** open `Football_Club_Finance.pbix`. If Power BI cannot find the data, go to *Home → Transform data → Data source settings → Change source* and point it to `01_excel/Football_Club_Finance_Dataset.xlsx`.

## Limitations

- One season only, and no dates (the periods are season labels), so there is no time trend.
- The numbers come from the club's workbook. This project checks that they are consistent, but it does not check them against bank statements or receipts.
- The statistics workbook holds values copied from the SQL views. If the data changes, it must be refreshed by hand.
- The 21 measures were checked by comparing the report with the source numbers, not with automated tests inside Power BI.

## Tools

Excel, SQLite (SQL, views, triggers), Python (standard library), Power BI (DAX).
