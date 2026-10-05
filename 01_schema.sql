-- =====================================================================
-- 01_schema.sql
-- Amateur Football Club - Season Finance Database
-- Dialect  : SQLite 3.31 or newer (generated columns are required)
-- Source   : Football_Club_Finance_Dataset.xlsx (data provided by the club)
--
-- IMPORTANT
--   * SQLite does NOT enforce foreign keys unless every connection runs:
--         PRAGMA foreign_keys = ON;
--   * Money columns use NUMERIC affinity. Every money value in this dataset is a
--     whole euro amount, so sums are exact. A CHECK on typeof() blocks text values.
--   * All columns are NOT NULL by design: a zero cost is stored as 0, never as NULL.
--   * Derived values are GENERATED columns, so they cannot drift from their inputs.
-- =====================================================================

PRAGMA foreign_keys = ON;

-- ---------------------------------------------------------------------
-- Reference tables
-- ---------------------------------------------------------------------

-- Grain: one row per season. Primary key: Season.
CREATE TABLE Team_Info (
    Season                      TEXT    NOT NULL PRIMARY KEY,
    League_Category             TEXT    NOT NULL,
    Season_Start_Month          TEXT    NOT NULL,
    Season_End_Month            TEXT    NOT NULL,
    Season_Months               INTEGER NOT NULL CHECK (typeof(Season_Months) = 'integer') CHECK (Season_Months > 0),
    Teams_in_League             INTEGER NOT NULL CHECK (typeof(Teams_in_League) = 'integer') CHECK (Teams_in_League > 0),
    Opponents                   INTEGER NOT NULL CHECK (typeof(Opponents) = 'integer') CHECK (Opponents >= 0),
    League_Matches              INTEGER NOT NULL CHECK (typeof(League_Matches) = 'integer') CHECK (League_Matches >= 0),
    Home_Matches                INTEGER NOT NULL CHECK (typeof(Home_Matches) = 'integer') CHECK (Home_Matches >= 0),
    Away_Matches                INTEGER NOT NULL CHECK (typeof(Away_Matches) = 'integer') CHECK (Away_Matches >= 0),
    Cup_Matches                 INTEGER NOT NULL CHECK (typeof(Cup_Matches) = 'integer') CHECK (Cup_Matches >= 0),
    Trainings_per_Week          INTEGER NOT NULL CHECK (typeof(Trainings_per_Week) = 'integer') CHECK (Trainings_per_Week >= 0),
    Training_Hours_per_Session  NUMERIC NOT NULL CHECK (typeof(Training_Hours_per_Session) IN ('integer', 'real')) CHECK (Training_Hours_per_Session >= 0),
    Training_Hours_per_Week     NUMERIC GENERATED ALWAYS AS (Trainings_per_Week * Training_Hours_per_Session) STORED,
    Home_Attendance_Min         INTEGER NOT NULL CHECK (typeof(Home_Attendance_Min) = 'integer') CHECK (Home_Attendance_Min >= 0),
    Home_Attendance_Max         INTEGER NOT NULL CHECK (typeof(Home_Attendance_Max) = 'integer') CHECK (Home_Attendance_Max >= 0),
    Stadium_Provider            TEXT    NOT NULL,
    Floodlights_Available       TEXT    NOT NULL CHECK (Floodlights_Available IN ('Yes', 'No')),
    CHECK (League_Matches = Home_Matches + Away_Matches),
    CHECK (Opponents = Teams_in_League - 1),
    CHECK (Home_Attendance_Min <= Home_Attendance_Max)
);

-- Grain: one row per numeric parameter used in cost calculations. Primary key: Parameter_ID.
CREATE TABLE Parameters (
    Parameter_ID TEXT    NOT NULL PRIMARY KEY,
    Parameter    TEXT    NOT NULL UNIQUE,
    Value        NUMERIC NOT NULL CHECK (typeof(Value) IN ('integer', 'real')) CHECK (Value >= 0),
    Unit         TEXT    NOT NULL
);

-- Dimension: one row per revenue source. Primary key: Revenue_Source.
CREATE TABLE Dim_Revenue_Source (
    Revenue_Source TEXT NOT NULL PRIMARY KEY
);

-- Dimension: one row per expense category. Primary key: Expense_Category.
CREATE TABLE Dim_Expense_Category (
    Expense_Category TEXT NOT NULL PRIMARY KEY
);

-- ---------------------------------------------------------------------
-- Fact and detail tables
-- ---------------------------------------------------------------------

-- Grain: one row per revenue line. Primary key: Revenue_ID.
CREATE TABLE Revenue (
    Revenue_ID     TEXT    NOT NULL PRIMARY KEY,
    Season         TEXT    NOT NULL REFERENCES Team_Info (Season),
    Date_Period    TEXT    NOT NULL,
    Revenue_Source TEXT    NOT NULL REFERENCES Dim_Revenue_Source (Revenue_Source),
    Description    TEXT    NOT NULL,
    Amount_EUR     NUMERIC NOT NULL CHECK (typeof(Amount_EUR) IN ('integer', 'real')) CHECK (Amount_EUR >= 0)
);

-- Grain: one row per expense line. Primary key: Expense_ID.
-- Total_Cost_EUR is generated: ROUND(Quantity * Unit_Cost_EUR, 2).
CREATE TABLE Expenses (
    Expense_ID       TEXT    NOT NULL PRIMARY KEY,
    Season           TEXT    NOT NULL REFERENCES Team_Info (Season),
    Date_Period      TEXT    NOT NULL,
    Expense_Category TEXT    NOT NULL REFERENCES Dim_Expense_Category (Expense_Category),
    Expense_Type     TEXT    NOT NULL,
    Description      TEXT    NOT NULL,
    Quantity         NUMERIC NOT NULL CHECK (typeof(Quantity) IN ('integer', 'real')) CHECK (Quantity >= 0),
    Unit_Cost_EUR    NUMERIC NOT NULL CHECK (typeof(Unit_Cost_EUR) IN ('integer', 'real')) CHECK (Unit_Cost_EUR >= 0),
    Total_Cost_EUR   NUMERIC GENERATED ALWAYS AS (ROUND(Quantity * Unit_Cost_EUR, 2)) STORED
);

-- Grain: one row per coaching staff position. Primary key: Staff_ID.
CREATE TABLE Staff (
    Staff_ID              TEXT    NOT NULL PRIMARY KEY,
    Role                  TEXT    NOT NULL UNIQUE,
    Monthly_Salary_EUR    NUMERIC NOT NULL CHECK (typeof(Monthly_Salary_EUR) IN ('integer', 'real')) CHECK (Monthly_Salary_EUR >= 0),
    Months                INTEGER NOT NULL CHECK (typeof(Months) = 'integer') CHECK (Months >= 0),
    Total_Season_Cost_EUR NUMERIC GENERATED ALWAYS AS (ROUND(Monthly_Salary_EUR * Months, 2)) STORED,
    Headcount             INTEGER NOT NULL CHECK (typeof(Headcount) = 'integer') CHECK (Headcount >= 0),
    Notes                 TEXT    NOT NULL
);

-- Grain: one row per paid player. Primary key: Player_ID.
CREATE TABLE Players (
    Player_ID             TEXT    NOT NULL PRIMARY KEY,
    Player                TEXT    NOT NULL UNIQUE,
    Monthly_Salary_EUR    NUMERIC NOT NULL CHECK (typeof(Monthly_Salary_EUR) IN ('integer', 'real')) CHECK (Monthly_Salary_EUR >= 0),
    Months                INTEGER NOT NULL CHECK (typeof(Months) = 'integer') CHECK (Months >= 0),
    Total_Season_Cost_EUR NUMERIC GENERATED ALWAYS AS (ROUND(Monthly_Salary_EUR * Months, 2)) STORED
);

-- Grain: one row per equipment or medical supply item. Primary key: Equipment_ID.
CREATE TABLE Equipment (
    Equipment_ID   TEXT    NOT NULL PRIMARY KEY,
    Equipment      TEXT    NOT NULL UNIQUE,
    Quantity       INTEGER NOT NULL CHECK (typeof(Quantity) = 'integer') CHECK (Quantity >= 0),
    Unit_Cost_EUR  NUMERIC NOT NULL CHECK (typeof(Unit_Cost_EUR) IN ('integer', 'real')) CHECK (Unit_Cost_EUR >= 0),
    Total_Cost_EUR NUMERIC GENERATED ALWAYS AS (ROUND(Quantity * Unit_Cost_EUR, 2)) STORED,
    Item_Group     TEXT    NOT NULL CHECK (Item_Group IN ('Playing Equipment', 'Medical Supplies')),
    Quantity_Unit  TEXT    NOT NULL
);

-- Grain: one row per league match (home and away). Primary key: Match_ID.
CREATE TABLE Match_Costs (
    Match_ID             TEXT    NOT NULL PRIMARY KEY,
    Home_Away            TEXT    NOT NULL CHECK (Home_Away IN ('Home', 'Away')),
    Referees_Count       INTEGER NOT NULL CHECK (typeof(Referees_Count) = 'integer') CHECK (Referees_Count >= 0),
    Referee_Cost_EUR     NUMERIC NOT NULL CHECK (typeof(Referee_Cost_EUR) IN ('integer', 'real')) CHECK (Referee_Cost_EUR >= 0),
    Doctor_Cost_EUR      NUMERIC NOT NULL CHECK (typeof(Doctor_Cost_EUR) IN ('integer', 'real')) CHECK (Doctor_Cost_EUR >= 0),
    Other_Match_Cost_EUR NUMERIC NOT NULL CHECK (typeof(Other_Match_Cost_EUR) IN ('integer', 'real')) CHECK (Other_Match_Cost_EUR >= 0),
    Total_Match_Cost_EUR NUMERIC GENERATED ALWAYS AS (Referee_Cost_EUR + Doctor_Cost_EUR + Other_Match_Cost_EUR) STORED
);

-- Grain: one row per away match (one-to-one with Match_Costs rows where Home_Away = 'Away').
-- Primary key and foreign key: Match_ID. A trigger below blocks rows for home matches.
CREATE TABLE Travel (
    Match_ID                     TEXT    NOT NULL PRIMARY KEY REFERENCES Match_Costs (Match_ID),
    Destination_ID               TEXT    NOT NULL UNIQUE,
    One_Way_Distance_KM          NUMERIC NOT NULL CHECK (typeof(One_Way_Distance_KM) IN ('integer', 'real')) CHECK (One_Way_Distance_KM >= 0),
    Round_Trip_Distance_KM       NUMERIC GENERATED ALWAYS AS (One_Way_Distance_KM * 2) STORED,
    Number_of_Cars               INTEGER NOT NULL CHECK (typeof(Number_of_Cars) = 'integer') CHECK (Number_of_Cars >= 0),
    Vehicle_KM                   NUMERIC GENERATED ALWAYS AS (Round_Trip_Distance_KM * Number_of_Cars) STORED,
    Fuel_Consumption_L_per_100KM NUMERIC NOT NULL CHECK (typeof(Fuel_Consumption_L_per_100KM) IN ('integer', 'real')) CHECK (Fuel_Consumption_L_per_100KM >= 0),
    Fuel_Price_EUR_per_L         NUMERIC NOT NULL CHECK (typeof(Fuel_Price_EUR_per_L) IN ('integer', 'real')) CHECK (Fuel_Price_EUR_per_L >= 0),
    Fuel_Cost_EUR                NUMERIC GENERATED ALWAYS AS (ROUND(Vehicle_KM * Fuel_Consumption_L_per_100KM / 100.0 * Fuel_Price_EUR_per_L, 2)) STORED
);

-- Grain: one row per stadium cost category. Primary key: Cost_ID.
CREATE TABLE Stadium (
    Cost_ID          TEXT    NOT NULL PRIMARY KEY,
    Category         TEXT    NOT NULL UNIQUE,
    Monthly_Cost_EUR NUMERIC NOT NULL CHECK (typeof(Monthly_Cost_EUR) IN ('integer', 'real')) CHECK (Monthly_Cost_EUR >= 0),
    Months           INTEGER NOT NULL CHECK (typeof(Months) = 'integer') CHECK (Months >= 0),
    Total_Cost_EUR   NUMERIC GENERATED ALWAYS AS (ROUND(Monthly_Cost_EUR * Months, 2)) STORED
);

-- Grain: one row per in-kind or community support item. Primary key: Support_ID.
-- Business rule: in-kind support has no monetary cost to the club, so the value must be 0.
CREATE TABLE In_Kind_Community (
    Support_ID                TEXT    NOT NULL PRIMARY KEY,
    Support_Type              TEXT    NOT NULL,
    Description               TEXT    NOT NULL,
    Provider                  TEXT    NOT NULL,
    Monetary_Cost_to_Club_EUR NUMERIC NOT NULL CHECK (typeof(Monetary_Cost_to_Club_EUR) IN ('integer', 'real')) CHECK (Monetary_Cost_to_Club_EUR = 0)
);

-- Grain: one row per documented column. Primary key: (Table_Name, Column_Name).
CREATE TABLE Data_Dictionary (
    Table_Name   TEXT    NOT NULL,
    Column_Name  TEXT    NOT NULL,
    Data_Type    TEXT    NOT NULL,
    Key_Type     TEXT    NOT NULL,
    Is_Generated INTEGER NOT NULL CHECK (Is_Generated IN (0, 1)),
    Description  TEXT    NOT NULL,
    PRIMARY KEY (Table_Name, Column_Name)
);

-- ---------------------------------------------------------------------
-- Indexes on foreign key columns (SQLite does not create them automatically)
-- ---------------------------------------------------------------------
CREATE INDEX idx_Revenue_Season           ON Revenue  (Season);
CREATE INDEX idx_Revenue_Revenue_Source   ON Revenue  (Revenue_Source);
CREATE INDEX idx_Expenses_Season          ON Expenses (Season);
CREATE INDEX idx_Expenses_Expense_Category ON Expenses (Expense_Category);

-- ---------------------------------------------------------------------
-- Triggers: a travel row is only valid for an away match
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_Travel_Insert_Away_Only
BEFORE INSERT ON Travel
WHEN (SELECT Home_Away FROM Match_Costs WHERE Match_ID = NEW.Match_ID) IS NOT 'Away'
BEGIN
    SELECT RAISE(ABORT, 'Travel rows are only allowed for away matches');
END;

CREATE TRIGGER trg_Travel_Update_Away_Only
BEFORE UPDATE OF Match_ID ON Travel
WHEN (SELECT Home_Away FROM Match_Costs WHERE Match_ID = NEW.Match_ID) IS NOT 'Away'
BEGIN
    SELECT RAISE(ABORT, 'Travel rows are only allowed for away matches');
END;

-- A match that has a Travel row must stay an away match.
CREATE TRIGGER trg_Match_Costs_Update_Home_Away
BEFORE UPDATE OF Home_Away ON Match_Costs
WHEN NEW.Home_Away <> 'Away' AND EXISTS (SELECT 1 FROM Travel WHERE Match_ID = NEW.Match_ID)
BEGIN
    SELECT RAISE(ABORT, 'A match with a Travel row must stay an away match');
END;
