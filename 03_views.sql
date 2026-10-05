-- =====================================================================
-- 03_views.sql
-- Analysis views for statistical analysis and Power BI.
-- Dialect: SQLite 3.31 or newer. Run after 01_schema.sql and 02_data.sql.
--
-- KPI DEFINITIONS
--   Total_Revenue_EUR  = SUM(Revenue.Amount_EUR). Money received by the club.
--   Total_Expenses_EUR = SUM(Expenses.Total_Cost_EUR). Money paid by the club.
--   Net_Result_EUR     = Total_Revenue_EUR - Total_Expenses_EUR.
--   In-kind and community support has no monetary value and is excluded from all money KPIs.
--
-- DESIGN RULES
--   * Every view lists its columns explicitly (no SELECT *).
--   * Each detail table is aggregated separately, so there is no join fan-out.
--   * Dimension-to-fact joins use LEFT JOIN with no filter on the fact table in WHERE.
--   * SUM is wrapped in COALESCE(..., 0) so an empty table gives 0 instead of NULL.
--   * Share percentages divide with NULLIF, so a zero total gives NULL instead of an error.
--   * Views contain no ORDER BY. Add ORDER BY in the query that reads the view.
--   * Staff, Players, Travel, Equipment, Match_Costs and Stadium have no Season column.
--     The database holds one season (checked by CHK036), so their totals are season totals.
-- =====================================================================

PRAGMA foreign_keys = ON;

-- Grain: one row for the whole dataset (one season).
CREATE VIEW vw_kpi_summary AS
SELECT
    (SELECT COALESCE(SUM(Amount_EUR), 0)           FROM Revenue)     AS Total_Revenue_EUR,
    (SELECT COALESCE(SUM(Total_Cost_EUR), 0)       FROM Expenses)    AS Total_Expenses_EUR,
    (SELECT COALESCE(SUM(Amount_EUR), 0)           FROM Revenue)
      - (SELECT COALESCE(SUM(Total_Cost_EUR), 0)   FROM Expenses)    AS Net_Result_EUR,
    (SELECT COALESCE(SUM(Total_Season_Cost_EUR), 0) FROM Staff)      AS Total_Coach_Cost_EUR,
    (SELECT COALESCE(SUM(Total_Season_Cost_EUR), 0) FROM Players)    AS Total_Player_Cost_EUR,
    (SELECT COALESCE(SUM(Fuel_Cost_EUR), 0)        FROM Travel)      AS Total_Travel_Cost_EUR,
    (SELECT COALESCE(SUM(Total_Cost_EUR), 0)       FROM Equipment)   AS Total_Equipment_Cost_EUR,
    (SELECT COALESCE(SUM(Total_Match_Cost_EUR), 0) FROM Match_Costs) AS Total_Match_Cost_EUR,
    (SELECT COALESCE(SUM(Total_Cost_EUR), 0)       FROM Stadium)     AS Total_Stadium_Cost_EUR;

-- Grain: one row per revenue source (all sources, including sources with 0 revenue).
CREATE VIEW vw_revenue_by_source AS
SELECT
    s.Revenue_Source                                             AS Revenue_Source,
    COUNT(r.Revenue_ID)                                          AS Line_Count,
    COALESCE(SUM(r.Amount_EUR), 0)                               AS Total_Amount_EUR,
    ROUND(100.0 * COALESCE(SUM(r.Amount_EUR), 0)
          / NULLIF((SELECT SUM(Amount_EUR) FROM Revenue), 0), 2) AS Share_Pct
FROM Dim_Revenue_Source AS s
LEFT JOIN Revenue AS r
       ON r.Revenue_Source = s.Revenue_Source
GROUP BY s.Revenue_Source;

-- Grain: one row per expense category (all categories, including categories with 0 cost).
CREATE VIEW vw_expenses_by_category AS
SELECT
    c.Expense_Category                                              AS Expense_Category,
    COUNT(e.Expense_ID)                                             AS Line_Count,
    COALESCE(SUM(e.Total_Cost_EUR), 0)                              AS Total_Cost_EUR,
    ROUND(100.0 * COALESCE(SUM(e.Total_Cost_EUR), 0)
          / NULLIF((SELECT SUM(Total_Cost_EUR) FROM Expenses), 0), 2) AS Share_Pct
FROM Dim_Expense_Category AS c
LEFT JOIN Expenses AS e
       ON e.Expense_Category = c.Expense_Category
GROUP BY c.Expense_Category;

-- Grain: one row per (Expense_Category, Expense_Type).
CREATE VIEW vw_expenses_by_type AS
SELECT
    Expense_Category,
    Expense_Type,
    COUNT(*)                          AS Line_Count,
    COALESCE(SUM(Total_Cost_EUR), 0)  AS Total_Cost_EUR
FROM Expenses
GROUP BY Expense_Category, Expense_Type;

-- Grain: one row per paid person (coaching staff positions and players).
-- UNION ALL is used on purpose: the two sources never overlap and no row may be removed.
CREATE VIEW vw_payroll AS
SELECT 'Coaching Staff' AS Payroll_Group, Staff_ID AS Person_ID, Role AS Person_Label,
       Monthly_Salary_EUR, Months, Total_Season_Cost_EUR
FROM Staff
UNION ALL
SELECT 'Players' AS Payroll_Group, Player_ID AS Person_ID, Player AS Person_Label,
       Monthly_Salary_EUR, Months, Total_Season_Cost_EUR
FROM Players;

-- Grain: one row per league match (14 rows). Travel is one-to-one with away matches,
-- so the LEFT JOIN cannot multiply rows. Home matches have no travel row:
-- distances, vehicle-km and fuel cost are 0 there and Destination_ID is 'No travel'.
CREATE VIEW vw_match_day_costs AS
SELECT
    m.Match_ID                                   AS Match_ID,
    m.Home_Away                                  AS Home_Away,
    m.Referees_Count                             AS Referees_Count,
    m.Referee_Cost_EUR                           AS Referee_Cost_EUR,
    m.Doctor_Cost_EUR                            AS Doctor_Cost_EUR,
    m.Other_Match_Cost_EUR                       AS Other_Match_Cost_EUR,
    m.Total_Match_Cost_EUR                       AS Total_Match_Cost_EUR,
    COALESCE(t.Destination_ID, 'No travel')      AS Destination_ID,
    COALESCE(t.One_Way_Distance_KM, 0)           AS One_Way_Distance_KM,
    COALESCE(t.Round_Trip_Distance_KM, 0)        AS Round_Trip_Distance_KM,
    COALESCE(t.Vehicle_KM, 0)                    AS Vehicle_KM,
    COALESCE(t.Fuel_Cost_EUR, 0)                 AS Travel_Fuel_Cost_EUR,
    m.Total_Match_Cost_EUR + COALESCE(t.Fuel_Cost_EUR, 0) AS Total_Match_Day_Cost_EUR
FROM Match_Costs AS m
LEFT JOIN Travel AS t
       ON t.Match_ID = m.Match_ID;

-- =====================================================================
-- Control checks. Control_Value is the total or count provided by the club,
-- or the expected structural value (row counts, zero problem rows).
-- Status is OK only when Calculated_Value - Control_Value rounds to 0.
-- A NULL Calculated_Value gives a NULL difference and therefore Status = CHECK.
-- Grain: one row per check.
-- =====================================================================
CREATE VIEW vw_control_checks AS
SELECT
    Check_ID,
    Check_Description,
    Calculated_Value,
    Control_Value,
    Calculated_Value - Control_Value AS Difference,
    CASE WHEN ROUND(Calculated_Value - Control_Value, 2) = 0 THEN 'OK' ELSE 'CHECK' END AS Status
FROM (
    SELECT 'CHK001' AS Check_ID, 'Total revenue' AS Check_Description, (SELECT COALESCE(SUM(Amount_EUR), 0) FROM Revenue) AS Calculated_Value, 42000 AS Control_Value
    UNION ALL
    SELECT 'CHK002' AS Check_ID, 'Total expenses' AS Check_Description, (SELECT COALESCE(SUM(Total_Cost_EUR), 0) FROM Expenses) AS Calculated_Value, 35833 AS Control_Value
    UNION ALL
    SELECT 'CHK003' AS Check_ID, 'Net result = revenue - expenses' AS Check_Description, (SELECT COALESCE(SUM(Amount_EUR), 0) FROM Revenue) - (SELECT COALESCE(SUM(Total_Cost_EUR), 0) FROM Expenses) AS Calculated_Value, 6167 AS Control_Value
    UNION ALL
    SELECT 'CHK004' AS Check_ID, 'Net result from vw_kpi_summary' AS Check_Description, (SELECT Net_Result_EUR FROM vw_kpi_summary) AS Calculated_Value, 6167 AS Control_Value
    UNION ALL
    SELECT 'CHK005' AS Check_ID, 'Coach cost (Staff table)' AS Check_Description, (SELECT COALESCE(SUM(Total_Season_Cost_EUR), 0) FROM Staff) AS Calculated_Value, 13000 AS Control_Value
    UNION ALL
    SELECT 'CHK006' AS Check_ID, 'Coaching Staff category (Expenses table)' AS Check_Description, (SELECT COALESCE(SUM(Total_Cost_EUR), 0) FROM Expenses WHERE Expense_Category = 'Coaching Staff') AS Calculated_Value, 13000 AS Control_Value
    UNION ALL
    SELECT 'CHK007' AS Check_ID, 'Player cost (Players table)' AS Check_Description, (SELECT COALESCE(SUM(Total_Season_Cost_EUR), 0) FROM Players) AS Calculated_Value, 12000 AS Control_Value
    UNION ALL
    SELECT 'CHK008' AS Check_ID, 'Player Salaries category (Expenses table)' AS Check_Description, (SELECT COALESCE(SUM(Total_Cost_EUR), 0) FROM Expenses WHERE Expense_Category = 'Player Salaries') AS Calculated_Value, 12000 AS Control_Value
    UNION ALL
    SELECT 'CHK009' AS Check_ID, 'Electricity (Expenses table)' AS Check_Description, (SELECT COALESCE(SUM(Total_Cost_EUR), 0) FROM Expenses WHERE Expense_Category = 'Electricity') AS Calculated_Value, 2500 AS Control_Value
    UNION ALL
    SELECT 'CHK010' AS Check_ID, 'Water (Expenses table)' AS Check_Description, (SELECT COALESCE(SUM(Total_Cost_EUR), 0) FROM Expenses WHERE Expense_Category = 'Water') AS Calculated_Value, 1000 AS Control_Value
    UNION ALL
    SELECT 'CHK011' AS Check_ID, 'Stadium cost (Stadium table)' AS Check_Description, (SELECT COALESCE(SUM(Total_Cost_EUR), 0) FROM Stadium) AS Calculated_Value, 3500 AS Control_Value
    UNION ALL
    SELECT 'CHK012' AS Check_ID, 'Referee cost (Match_Costs table)' AS Check_Description, (SELECT COALESCE(SUM(Referee_Cost_EUR), 0) FROM Match_Costs) AS Calculated_Value, 840 AS Control_Value
    UNION ALL
    SELECT 'CHK013' AS Check_ID, 'Referees category (Expenses table)' AS Check_Description, (SELECT COALESCE(SUM(Total_Cost_EUR), 0) FROM Expenses WHERE Expense_Category = 'Referees') AS Calculated_Value, 840 AS Control_Value
    UNION ALL
    SELECT 'CHK014' AS Check_ID, 'Doctor cost (Match_Costs table)' AS Check_Description, (SELECT COALESCE(SUM(Doctor_Cost_EUR), 0) FROM Match_Costs) AS Calculated_Value, 140 AS Control_Value
    UNION ALL
    SELECT 'CHK015' AS Check_ID, 'Match Doctor category (Expenses table)' AS Check_Description, (SELECT COALESCE(SUM(Total_Cost_EUR), 0) FROM Expenses WHERE Expense_Category = 'Match Doctor') AS Calculated_Value, 140 AS Control_Value
    UNION ALL
    SELECT 'CHK016' AS Check_ID, 'Total match cost (Match_Costs table)' AS Check_Description, (SELECT COALESCE(SUM(Total_Match_Cost_EUR), 0) FROM Match_Costs) AS Calculated_Value, 980 AS Control_Value
    UNION ALL
    SELECT 'CHK017' AS Check_ID, 'Equipment and medical supplies (Equipment table)' AS Check_Description, (SELECT COALESCE(SUM(Total_Cost_EUR), 0) FROM Equipment) AS Calculated_Value, 4175 AS Control_Value
    UNION ALL
    SELECT 'CHK018' AS Check_ID, 'Equipment & Medical Supplies category (Expenses table)' AS Check_Description, (SELECT COALESCE(SUM(Total_Cost_EUR), 0) FROM Expenses WHERE Expense_Category = 'Equipment & Medical Supplies') AS Calculated_Value, 4175 AS Control_Value
    UNION ALL
    SELECT 'CHK019' AS Check_ID, 'Travel fuel cost (Travel table)' AS Check_Description, (SELECT COALESCE(SUM(Fuel_Cost_EUR), 0) FROM Travel) AS Calculated_Value, 678 AS Control_Value
    UNION ALL
    SELECT 'CHK020' AS Check_ID, 'Travel category (Expenses table)' AS Check_Description, (SELECT COALESCE(SUM(Total_Cost_EUR), 0) FROM Expenses WHERE Expense_Category = 'Travel') AS Calculated_Value, 678 AS Control_Value
    UNION ALL
    SELECT 'CHK021' AS Check_ID, 'Accountant (Expenses table)' AS Check_Description, (SELECT COALESCE(SUM(Total_Cost_EUR), 0) FROM Expenses WHERE Expense_Category = 'Accountant') AS Calculated_Value, 1000 AS Control_Value
    UNION ALL
    SELECT 'CHK022' AS Check_ID, 'Lawyer (Expenses table)' AS Check_Description, (SELECT COALESCE(SUM(Total_Cost_EUR), 0) FROM Expenses WHERE Expense_Category = 'Lawyer') AS Calculated_Value, 500 AS Control_Value
    UNION ALL
    SELECT 'CHK023' AS Check_ID, 'Sum of round-trip km for one car cycle' AS Check_Description, (SELECT COALESCE(SUM(Round_Trip_Distance_KM), 0) FROM Travel) AS Calculated_Value, 1130 AS Control_Value
    UNION ALL
    SELECT 'CHK024' AS Check_ID, 'Total vehicle-km' AS Check_Description, (SELECT COALESCE(SUM(Vehicle_KM), 0) FROM Travel) AS Calculated_Value, 4520 AS Control_Value
    UNION ALL
    SELECT 'CHK025' AS Check_ID, 'Cars needed = travellers / persons per car, rounded up' AS Check_Description, ((SELECT Value FROM Parameters WHERE Parameter = 'Travellers_per_Away_Match') + (SELECT Value FROM Parameters WHERE Parameter = 'Persons_per_Car') - 1) / (SELECT Value FROM Parameters WHERE Parameter = 'Persons_per_Car') AS Calculated_Value, 4 AS Control_Value
    UNION ALL
    SELECT 'CHK026' AS Check_ID, 'Travel rows where Number_of_Cars differs from 4' AS Check_Description, (SELECT COUNT(*) FROM Travel WHERE Number_of_Cars <> 4) AS Calculated_Value, 0 AS Control_Value
    UNION ALL
    SELECT 'CHK027' AS Check_ID, 'Monetary cost of in-kind support' AS Check_Description, (SELECT COALESCE(SUM(Monetary_Cost_to_Club_EUR), 0) FROM In_Kind_Community) AS Calculated_Value, 0 AS Control_Value
    UNION ALL
    SELECT 'CHK028' AS Check_ID, 'Revenue total from vw_revenue_by_source' AS Check_Description, (SELECT COALESCE(SUM(Total_Amount_EUR), 0) FROM vw_revenue_by_source) AS Calculated_Value, 42000 AS Control_Value
    UNION ALL
    SELECT 'CHK029' AS Check_ID, 'Expenses total from vw_expenses_by_category' AS Check_Description, (SELECT COALESCE(SUM(Total_Cost_EUR), 0) FROM vw_expenses_by_category) AS Calculated_Value, 35833 AS Control_Value
    UNION ALL
    SELECT 'CHK030' AS Check_ID, 'Expenses total from vw_expenses_by_type' AS Check_Description, (SELECT COALESCE(SUM(Total_Cost_EUR), 0) FROM vw_expenses_by_type) AS Calculated_Value, 35833 AS Control_Value
    UNION ALL
    SELECT 'CHK031' AS Check_ID, 'Payroll total from vw_payroll' AS Check_Description, (SELECT COALESCE(SUM(Total_Season_Cost_EUR), 0) FROM vw_payroll) AS Calculated_Value, 25000 AS Control_Value
    UNION ALL
    SELECT 'CHK032' AS Check_ID, 'Rows in vw_match_day_costs (no join fan-out)' AS Check_Description, (SELECT COUNT(*) FROM vw_match_day_costs) AS Calculated_Value, 14 AS Control_Value
    UNION ALL
    SELECT 'CHK033' AS Check_ID, 'Total match-day cost after join (match + fuel)' AS Check_Description, (SELECT COALESCE(SUM(Total_Match_Day_Cost_EUR), 0) FROM vw_match_day_costs) AS Calculated_Value, 1658 AS Control_Value
    UNION ALL
    SELECT 'CHK034' AS Check_ID, 'Revenue share percentages sum to 100' AS Check_Description, (SELECT ROUND(SUM(Share_Pct), 0) FROM vw_revenue_by_source) AS Calculated_Value, 100 AS Control_Value
    UNION ALL
    SELECT 'CHK035' AS Check_ID, 'Expense share percentages sum to 100' AS Check_Description, (SELECT ROUND(SUM(Share_Pct), 0) FROM vw_expenses_by_category) AS Calculated_Value, 100 AS Control_Value
    UNION ALL
    SELECT 'CHK036' AS Check_ID, 'Rows in Team_Info (one season)' AS Check_Description, (SELECT COUNT(*) FROM Team_Info) AS Calculated_Value, 1 AS Control_Value
    UNION ALL
    SELECT 'CHK037' AS Check_ID, 'Rows in Revenue' AS Check_Description, (SELECT COUNT(*) FROM Revenue) AS Calculated_Value, 6 AS Control_Value
    UNION ALL
    SELECT 'CHK038' AS Check_ID, 'Rows in Expenses' AS Check_Description, (SELECT COUNT(*) FROM Expenses) AS Calculated_Value, 34 AS Control_Value
    UNION ALL
    SELECT 'CHK039' AS Check_ID, 'Rows in Staff' AS Check_Description, (SELECT COUNT(*) FROM Staff) AS Calculated_Value, 3 AS Control_Value
    UNION ALL
    SELECT 'CHK040' AS Check_ID, 'Paid players (rows in Players)' AS Check_Description, (SELECT COUNT(*) FROM Players) AS Calculated_Value, 3 AS Control_Value
    UNION ALL
    SELECT 'CHK041' AS Check_ID, 'Rows in Equipment' AS Check_Description, (SELECT COUNT(*) FROM Equipment) AS Calculated_Value, 9 AS Control_Value
    UNION ALL
    SELECT 'CHK042' AS Check_ID, 'League matches (rows in Match_Costs)' AS Check_Description, (SELECT COUNT(*) FROM Match_Costs) AS Calculated_Value, 14 AS Control_Value
    UNION ALL
    SELECT 'CHK043' AS Check_ID, 'Home matches' AS Check_Description, (SELECT COUNT(*) FROM Match_Costs WHERE Home_Away = 'Home') AS Calculated_Value, 7 AS Control_Value
    UNION ALL
    SELECT 'CHK044' AS Check_ID, 'Away matches' AS Check_Description, (SELECT COUNT(*) FROM Match_Costs WHERE Home_Away = 'Away') AS Calculated_Value, 7 AS Control_Value
    UNION ALL
    SELECT 'CHK045' AS Check_ID, 'Away destinations (rows in Travel)' AS Check_Description, (SELECT COUNT(*) FROM Travel) AS Calculated_Value, 7 AS Control_Value
    UNION ALL
    SELECT 'CHK046' AS Check_ID, 'Rows in Stadium' AS Check_Description, (SELECT COUNT(*) FROM Stadium) AS Calculated_Value, 6 AS Control_Value
    UNION ALL
    SELECT 'CHK047' AS Check_ID, 'Rows in In_Kind_Community' AS Check_Description, (SELECT COUNT(*) FROM In_Kind_Community) AS Calculated_Value, 4 AS Control_Value
    UNION ALL
    SELECT 'CHK048' AS Check_ID, 'Rows in Dim_Revenue_Source' AS Check_Description, (SELECT COUNT(*) FROM Dim_Revenue_Source) AS Calculated_Value, 5 AS Control_Value
    UNION ALL
    SELECT 'CHK049' AS Check_ID, 'Rows in Dim_Expense_Category' AS Check_Description, (SELECT COUNT(*) FROM Dim_Expense_Category) AS Calculated_Value, 17 AS Control_Value
    UNION ALL
    SELECT 'CHK050' AS Check_ID, 'League matches in Team_Info equals rows in Match_Costs' AS Check_Description, (SELECT League_Matches FROM Team_Info) - (SELECT COUNT(*) FROM Match_Costs) AS Calculated_Value, 0 AS Control_Value
    UNION ALL
    SELECT 'CHK051' AS Check_ID, 'Travel rows without a matching Match_Costs row' AS Check_Description, (SELECT COUNT(*) FROM Travel AS t WHERE NOT EXISTS (SELECT 1 FROM Match_Costs AS m WHERE m.Match_ID = t.Match_ID)) AS Calculated_Value, 0 AS Control_Value
    UNION ALL
    SELECT 'CHK052' AS Check_ID, 'Travel rows that point to a home match' AS Check_Description, (SELECT COUNT(*) FROM Travel AS t WHERE NOT EXISTS (SELECT 1 FROM Match_Costs AS m WHERE m.Match_ID = t.Match_ID AND m.Home_Away = 'Away')) AS Calculated_Value, 0 AS Control_Value
    UNION ALL
    SELECT 'CHK053' AS Check_ID, 'Away matches without a Travel row' AS Check_Description, (SELECT COUNT(*) FROM Match_Costs AS m WHERE m.Home_Away = 'Away' AND NOT EXISTS (SELECT 1 FROM Travel AS t WHERE t.Match_ID = m.Match_ID)) AS Calculated_Value, 0 AS Control_Value
    UNION ALL
    SELECT 'CHK054' AS Check_ID, 'Expenses rows without a valid category' AS Check_Description, (SELECT COUNT(*) FROM Expenses AS e WHERE NOT EXISTS (SELECT 1 FROM Dim_Expense_Category AS c WHERE c.Expense_Category = e.Expense_Category)) AS Calculated_Value, 0 AS Control_Value
    UNION ALL
    SELECT 'CHK055' AS Check_ID, 'Revenue rows without a valid source' AS Check_Description, (SELECT COUNT(*) FROM Revenue AS r WHERE NOT EXISTS (SELECT 1 FROM Dim_Revenue_Source AS s WHERE s.Revenue_Source = r.Revenue_Source)) AS Calculated_Value, 0 AS Control_Value
    UNION ALL
    SELECT 'CHK056' AS Check_ID, 'Revenue and Expenses rows without a valid season' AS Check_Description, (SELECT COUNT(*) FROM Revenue AS r WHERE NOT EXISTS (SELECT 1 FROM Team_Info AS t WHERE t.Season = r.Season)) + (SELECT COUNT(*) FROM Expenses AS e WHERE NOT EXISTS (SELECT 1 FROM Team_Info AS t WHERE t.Season = e.Season)) AS Calculated_Value, 0 AS Control_Value
    UNION ALL
    SELECT 'CHK057' AS Check_ID, 'Match_Costs rows where referee cost differs from Referees_Count * fee' AS Check_Description, (SELECT COUNT(*) FROM Match_Costs WHERE Referee_Cost_EUR <> Referees_Count * (SELECT Value FROM Parameters WHERE Parameter = 'Referee_Fee_per_Referee')) AS Calculated_Value, 0 AS Control_Value
    UNION ALL
    SELECT 'CHK058' AS Check_ID, 'Home matches where referee count differs from the parameter' AS Check_Description, (SELECT COUNT(*) FROM Match_Costs WHERE Home_Away = 'Home' AND Referees_Count <> (SELECT Value FROM Parameters WHERE Parameter = 'Referees_per_Home_Match')) AS Calculated_Value, 0 AS Control_Value
    UNION ALL
    SELECT 'CHK059' AS Check_ID, 'Home matches where doctor cost differs from the parameter' AS Check_Description, (SELECT COUNT(*) FROM Match_Costs WHERE Home_Away = 'Home' AND Doctor_Cost_EUR <> (SELECT Value FROM Parameters WHERE Parameter = 'Doctor_Fee_per_Home_Match')) AS Calculated_Value, 0 AS Control_Value
    UNION ALL
    SELECT 'CHK060' AS Check_ID, 'Away matches with a doctor cost paid by the club' AS Check_Description, (SELECT COUNT(*) FROM Match_Costs WHERE Home_Away = 'Away' AND Doctor_Cost_EUR <> 0) AS Calculated_Value, 0 AS Control_Value
    UNION ALL
    SELECT 'CHK061' AS Check_ID, 'Travel rows where cars, consumption or price differ from Parameters' AS Check_Description, (SELECT COUNT(*) FROM Travel WHERE Number_of_Cars <> (SELECT Value FROM Parameters WHERE Parameter = 'Number_of_Cars_per_Away_Match') OR Fuel_Consumption_L_per_100KM <> (SELECT Value FROM Parameters WHERE Parameter = 'Fuel_Consumption_L_per_100KM') OR Fuel_Price_EUR_per_L <> (SELECT Value FROM Parameters WHERE Parameter = 'Fuel_Price_EUR_per_L')) AS Calculated_Value, 0 AS Control_Value
    UNION ALL
    SELECT 'CHK062' AS Check_ID, 'Money values with more than 2 decimals' AS Check_Description, (SELECT COUNT(*) FROM Revenue WHERE ROUND(Amount_EUR, 2) <> Amount_EUR) + (SELECT COUNT(*) FROM Expenses WHERE ROUND(Unit_Cost_EUR, 2) <> Unit_Cost_EUR OR ROUND(Total_Cost_EUR, 2) <> Total_Cost_EUR) + (SELECT COUNT(*) FROM Staff WHERE ROUND(Monthly_Salary_EUR, 2) <> Monthly_Salary_EUR) + (SELECT COUNT(*) FROM Players WHERE ROUND(Monthly_Salary_EUR, 2) <> Monthly_Salary_EUR) + (SELECT COUNT(*) FROM Equipment WHERE ROUND(Unit_Cost_EUR, 2) <> Unit_Cost_EUR) + (SELECT COUNT(*) FROM Stadium WHERE ROUND(Monthly_Cost_EUR, 2) <> Monthly_Cost_EUR) + (SELECT COUNT(*) FROM Match_Costs WHERE ROUND(Referee_Cost_EUR, 2) <> Referee_Cost_EUR OR ROUND(Doctor_Cost_EUR, 2) <> Doctor_Cost_EUR OR ROUND(Other_Match_Cost_EUR, 2) <> Other_Match_Cost_EUR) + (SELECT COUNT(*) FROM Travel WHERE ROUND(Fuel_Cost_EUR, 2) <> Fuel_Cost_EUR) AS Calculated_Value, 0 AS Control_Value
    UNION ALL
    SELECT 'CHK063' AS Check_ID, 'Undocumented columns (columns missing from Data_Dictionary)' AS Check_Description, (SELECT COUNT(*) FROM sqlite_master AS m JOIN pragma_table_xinfo(m.name) AS c WHERE m.type = 'table' AND m.name NOT LIKE 'sqlite_%' AND NOT EXISTS (SELECT 1 FROM Data_Dictionary AS d WHERE d.Table_Name = m.name AND d.Column_Name = c.name)) AS Calculated_Value, 0 AS Control_Value
    UNION ALL
    SELECT 'CHK064' AS Check_ID, 'Staff table total minus Coaching Staff category in Expenses' AS Check_Description, (SELECT COALESCE(SUM(Total_Season_Cost_EUR),0) FROM Staff) - (SELECT COALESCE(SUM(Total_Cost_EUR), 0) FROM Expenses WHERE Expense_Category = 'Coaching Staff') AS Calculated_Value, 0 AS Control_Value
    UNION ALL
    SELECT 'CHK065' AS Check_ID, 'Players table total minus Player Salaries category in Expenses' AS Check_Description, (SELECT COALESCE(SUM(Total_Season_Cost_EUR),0) FROM Players) - (SELECT COALESCE(SUM(Total_Cost_EUR), 0) FROM Expenses WHERE Expense_Category = 'Player Salaries') AS Calculated_Value, 0 AS Control_Value
    UNION ALL
    SELECT 'CHK066' AS Check_ID, 'Stadium electricity row minus Electricity category in Expenses' AS Check_Description, (SELECT COALESCE(SUM(Total_Cost_EUR),0) FROM Stadium WHERE Category = 'Electricity') - (SELECT COALESCE(SUM(Total_Cost_EUR), 0) FROM Expenses WHERE Expense_Category = 'Electricity') AS Calculated_Value, 0 AS Control_Value
    UNION ALL
    SELECT 'CHK067' AS Check_ID, 'Stadium water row minus Water category in Expenses' AS Check_Description, (SELECT COALESCE(SUM(Total_Cost_EUR),0) FROM Stadium WHERE Category = 'Water') - (SELECT COALESCE(SUM(Total_Cost_EUR), 0) FROM Expenses WHERE Expense_Category = 'Water') AS Calculated_Value, 0 AS Control_Value
    UNION ALL
    SELECT 'CHK068' AS Check_ID, 'Stadium table total minus the three stadium categories in Expenses' AS Check_Description, (SELECT COALESCE(SUM(Total_Cost_EUR),0) FROM Stadium) - (SELECT COALESCE(SUM(Total_Cost_EUR), 0) FROM Expenses WHERE Expense_Category = 'Electricity') - (SELECT COALESCE(SUM(Total_Cost_EUR), 0) FROM Expenses WHERE Expense_Category = 'Water') - (SELECT COALESCE(SUM(Total_Cost_EUR), 0) FROM Expenses WHERE Expense_Category = 'Other Stadium Costs') AS Calculated_Value, 0 AS Control_Value
    UNION ALL
    SELECT 'CHK069' AS Check_ID, 'Match_Costs referee total minus Referees category in Expenses' AS Check_Description, (SELECT COALESCE(SUM(Referee_Cost_EUR),0) FROM Match_Costs) - (SELECT COALESCE(SUM(Total_Cost_EUR), 0) FROM Expenses WHERE Expense_Category = 'Referees') AS Calculated_Value, 0 AS Control_Value
    UNION ALL
    SELECT 'CHK070' AS Check_ID, 'Match_Costs doctor total minus Match Doctor category in Expenses' AS Check_Description, (SELECT COALESCE(SUM(Doctor_Cost_EUR),0) FROM Match_Costs) - (SELECT COALESCE(SUM(Total_Cost_EUR), 0) FROM Expenses WHERE Expense_Category = 'Match Doctor') AS Calculated_Value, 0 AS Control_Value
    UNION ALL
    SELECT 'CHK071' AS Check_ID, 'Equipment table total minus Equipment & Medical Supplies category in Expenses' AS Check_Description, (SELECT COALESCE(SUM(Total_Cost_EUR),0) FROM Equipment) - (SELECT COALESCE(SUM(Total_Cost_EUR), 0) FROM Expenses WHERE Expense_Category = 'Equipment & Medical Supplies') AS Calculated_Value, 0 AS Control_Value
    UNION ALL
    SELECT 'CHK072' AS Check_ID, 'Travel fuel total minus the Fuel expense line' AS Check_Description, (SELECT COALESCE(SUM(Fuel_Cost_EUR),0) FROM Travel) - (SELECT COALESCE(SUM(Total_Cost_EUR),0) FROM Expenses WHERE Expense_Type = 'Fuel') AS Calculated_Value, 0 AS Control_Value
    UNION ALL
    SELECT 'CHK073' AS Check_ID, 'Referee appearances in Expenses minus sum of Referees_Count' AS Check_Description, (SELECT COALESCE(SUM(Quantity),0) FROM Expenses WHERE Expense_Category = 'Referees') - (SELECT COALESCE(SUM(Referees_Count),0) FROM Match_Costs) AS Calculated_Value, 0 AS Control_Value
    UNION ALL
    SELECT 'CHK074' AS Check_ID, 'Doctor appearances in Expenses minus number of home matches' AS Check_Description, (SELECT COALESCE(SUM(Quantity),0) FROM Expenses WHERE Expense_Category = 'Match Doctor') - (SELECT COUNT(*) FROM Match_Costs WHERE Home_Away = 'Home') AS Calculated_Value, 0 AS Control_Value
    UNION ALL
    SELECT 'CHK075' AS Check_ID, 'Expense lines in Equipment category minus rows in Equipment' AS Check_Description, (SELECT COUNT(*) FROM Expenses WHERE Expense_Category = 'Equipment & Medical Supplies') - (SELECT COUNT(*) FROM Equipment) AS Calculated_Value, 0 AS Control_Value
    UNION ALL
    SELECT 'CHK076' AS Check_ID, 'Home_Matches in Team_Info minus Home rows in Match_Costs' AS Check_Description, (SELECT SUM(Home_Matches) FROM Team_Info) - (SELECT COUNT(*) FROM Match_Costs WHERE Home_Away = 'Home') AS Calculated_Value, 0 AS Control_Value
    UNION ALL
    SELECT 'CHK077' AS Check_ID, 'Away_Matches in Team_Info minus Away rows in Match_Costs' AS Check_Description, (SELECT SUM(Away_Matches) FROM Team_Info) - (SELECT COUNT(*) FROM Match_Costs WHERE Home_Away = 'Away') AS Calculated_Value, 0 AS Control_Value
    UNION ALL
    SELECT 'CHK078' AS Check_ID, 'Staff, Players or Stadium rows with more months than the season' AS Check_Description, (SELECT COUNT(*) FROM Staff WHERE Months > (SELECT MAX(Season_Months) FROM Team_Info)) + (SELECT COUNT(*) FROM Players WHERE Months > (SELECT MAX(Season_Months) FROM Team_Info)) + (SELECT COUNT(*) FROM Stadium WHERE Months > (SELECT MAX(Season_Months) FROM Team_Info)) AS Calculated_Value, 0 AS Control_Value
    UNION ALL
    SELECT 'CHK079' AS Check_ID, 'Number_of_Cars parameter minus cars needed (travellers / persons per car, rounded up)' AS Check_Description, (SELECT Value FROM Parameters WHERE Parameter = 'Number_of_Cars_per_Away_Match') - ((SELECT Value FROM Parameters WHERE Parameter = 'Travellers_per_Away_Match') + (SELECT Value FROM Parameters WHERE Parameter = 'Persons_per_Car') - 1) / (SELECT Value FROM Parameters WHERE Parameter = 'Persons_per_Car') AS Calculated_Value, 0 AS Control_Value
    UNION ALL
    SELECT 'CHK080' AS Check_ID, 'Total expenses minus (all source tables + lines without a source table)' AS Check_Description, (SELECT COALESCE(SUM(Total_Cost_EUR),0) FROM Expenses) - ((SELECT COALESCE(SUM(Total_Season_Cost_EUR),0) FROM Staff) + (SELECT COALESCE(SUM(Total_Season_Cost_EUR),0) FROM Players) + (SELECT COALESCE(SUM(Total_Cost_EUR),0) FROM Stadium) + (SELECT COALESCE(SUM(Total_Match_Cost_EUR),0) FROM Match_Costs) + (SELECT COALESCE(SUM(Total_Cost_EUR),0) FROM Equipment) + (SELECT COALESCE(SUM(Total_Cost_EUR),0) FROM Expenses WHERE Expense_Type IN ('Fuel','Tolls','Other Vehicle Costs')) + (SELECT COALESCE(SUM(Total_Cost_EUR),0) FROM Expenses WHERE Expense_Category IN ('Accountant','Lawyer','Phone & Internet','Website, Social Media, Advertising & Printing','Insurance','Registrations & Player Cards','Transfers','Other Operating Expenses'))) AS Calculated_Value, 0 AS Control_Value
);
