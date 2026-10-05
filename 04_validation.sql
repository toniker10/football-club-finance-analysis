-- =====================================================================
-- 04_validation.sql
-- Read-only validation queries. Run after 01, 02 and 03.
-- Nothing here changes data. Expected result of every section is stated above the query.
-- =====================================================================

PRAGMA foreign_keys = ON;

-- 1. All control checks. Expected: Status = OK on every row.
SELECT Check_ID, Check_Description, Calculated_Value, Control_Value, Difference, Status
FROM vw_control_checks
ORDER BY Check_ID;

-- 2. Summary of the control checks. Expected: only the row 'OK'.
SELECT Status, COUNT(*) AS Check_Count
FROM vw_control_checks
GROUP BY Status
ORDER BY Status;

-- 3. Row counts of every table (grain check).
SELECT 'Team_Info' AS Table_Name, COUNT(*) AS Row_Count FROM Team_Info
UNION ALL SELECT 'Parameters', COUNT(*) FROM Parameters
UNION ALL SELECT 'Dim_Revenue_Source', COUNT(*) FROM Dim_Revenue_Source
UNION ALL SELECT 'Dim_Expense_Category', COUNT(*) FROM Dim_Expense_Category
UNION ALL SELECT 'Revenue', COUNT(*) FROM Revenue
UNION ALL SELECT 'Expenses', COUNT(*) FROM Expenses
UNION ALL SELECT 'Staff', COUNT(*) FROM Staff
UNION ALL SELECT 'Players', COUNT(*) FROM Players
UNION ALL SELECT 'Equipment', COUNT(*) FROM Equipment
UNION ALL SELECT 'Match_Costs', COUNT(*) FROM Match_Costs
UNION ALL SELECT 'Travel', COUNT(*) FROM Travel
UNION ALL SELECT 'Stadium', COUNT(*) FROM Stadium
UNION ALL SELECT 'In_Kind_Community', COUNT(*) FROM In_Kind_Community
UNION ALL SELECT 'Data_Dictionary', COUNT(*) FROM Data_Dictionary;

-- 4. Row counts before and after the join in vw_match_day_costs (fan-out test).
--    Expected: both rows show 14 and the same 980 match cost.
SELECT 'Match_Costs (before join)' AS Source_Name,
       COUNT(*) AS Row_Count,
       SUM(Total_Match_Cost_EUR) AS Match_Cost_EUR
FROM Match_Costs
UNION ALL
SELECT 'vw_match_day_costs (after join)',
       COUNT(*),
       SUM(Total_Match_Cost_EUR)
FROM vw_match_day_costs;

-- 5. Expense categories and their totals, to spot unexpected category values.
--    Expected: 17 categories, total 35833.
SELECT Expense_Category, COUNT(*) AS Line_Count, SUM(Total_Cost_EUR) AS Total_Cost_EUR
FROM Expenses
GROUP BY Expense_Category
ORDER BY Expense_Category;

-- 6. Type check: numeric columns must hold numbers, never text.
--    Expected: Text_Value_Count = 0 on every row.
SELECT 'Revenue.Amount_EUR' AS Column_Name,
       COUNT(*) AS Text_Value_Count
FROM Revenue WHERE typeof(Amount_EUR) NOT IN ('integer', 'real')
UNION ALL
SELECT 'Expenses.Quantity', COUNT(*)
FROM Expenses WHERE typeof(Quantity) NOT IN ('integer', 'real')
UNION ALL
SELECT 'Expenses.Unit_Cost_EUR', COUNT(*)
FROM Expenses WHERE typeof(Unit_Cost_EUR) NOT IN ('integer', 'real')
UNION ALL
SELECT 'Expenses.Total_Cost_EUR', COUNT(*)
FROM Expenses WHERE typeof(Total_Cost_EUR) NOT IN ('integer', 'real')
UNION ALL
SELECT 'Travel.Fuel_Cost_EUR', COUNT(*)
FROM Travel WHERE typeof(Fuel_Cost_EUR) NOT IN ('integer', 'real');

-- 7. SQLite built-in checks. Expected: the first returns no rows, the second returns 'ok'.
PRAGMA foreign_key_check;
PRAGMA integrity_check;
