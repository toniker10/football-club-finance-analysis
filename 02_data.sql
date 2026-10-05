-- =====================================================================
-- 02_data.sql
-- Data load for the Amateur Football Club - Season Finance Database
-- Values are exactly the club-provided values from Football_Club_Finance_Dataset.xlsx.
-- Generated columns (totals, distances, fuel cost) are NOT loaded; SQLite computes them.
-- Run after 01_schema.sql. The load is one transaction: it either fully succeeds or not at all.
-- =====================================================================

PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;

-- Team_Info (rows: 1)
INSERT INTO Team_Info (Season, League_Category, Season_Start_Month, Season_End_Month, Season_Months, Teams_in_League, Opponents, League_Matches, Home_Matches, Away_Matches, Cup_Matches, Trainings_per_Week, Training_Hours_per_Session, Home_Attendance_Min, Home_Attendance_Max, Stadium_Provider, Floodlights_Available) VALUES
    ('Season_1', 'B Local League', 'August', 'May', 10, 8, 7, 14, 7, 7, 0, 3, 2, 200, 300, 'Village', 'Yes');

-- Parameters (rows: 8)
INSERT INTO Parameters (Parameter_ID, Parameter, Value, Unit) VALUES
    ('PR01', 'Referee_Fee_per_Referee', 40, 'EUR'),
    ('PR02', 'Referees_per_Home_Match', 3, 'count'),
    ('PR03', 'Doctor_Fee_per_Home_Match', 20, 'EUR'),
    ('PR04', 'Number_of_Cars_per_Away_Match', 4, 'count'),
    ('PR05', 'Fuel_Consumption_L_per_100KM', 7.5, 'L/100km'),
    ('PR06', 'Fuel_Price_EUR_per_L', 2, 'EUR/L'),
    ('PR07', 'Travellers_per_Away_Match', 18, 'persons'),
    ('PR08', 'Persons_per_Car', 5, 'persons');

-- Match_Costs (rows: 14)
INSERT INTO Match_Costs (Match_ID, Home_Away, Referees_Count, Referee_Cost_EUR, Doctor_Cost_EUR, Other_Match_Cost_EUR) VALUES
    ('H01', 'Home', 3, 120, 20, 0),
    ('H02', 'Home', 3, 120, 20, 0),
    ('H03', 'Home', 3, 120, 20, 0),
    ('H04', 'Home', 3, 120, 20, 0),
    ('H05', 'Home', 3, 120, 20, 0),
    ('H06', 'Home', 3, 120, 20, 0),
    ('H07', 'Home', 3, 120, 20, 0),
    ('A01', 'Away', 0, 0, 0, 0),
    ('A02', 'Away', 0, 0, 0, 0),
    ('A03', 'Away', 0, 0, 0, 0),
    ('A04', 'Away', 0, 0, 0, 0),
    ('A05', 'Away', 0, 0, 0, 0),
    ('A06', 'Away', 0, 0, 0, 0),
    ('A07', 'Away', 0, 0, 0, 0);

-- Dim_Revenue_Source (rows: 5)
INSERT INTO Dim_Revenue_Source (Revenue_Source) VALUES
    ('Village Funding'),
    ('Fundraising Dinners'),
    ('Sponsorships'),
    ('Ticket Sales'),
    ('Other Revenue');

-- Dim_Expense_Category (rows: 17)
INSERT INTO Dim_Expense_Category (Expense_Category) VALUES
    ('Coaching Staff'),
    ('Player Salaries'),
    ('Electricity'),
    ('Water'),
    ('Other Stadium Costs'),
    ('Referees'),
    ('Match Doctor'),
    ('Equipment & Medical Supplies'),
    ('Travel'),
    ('Accountant'),
    ('Lawyer'),
    ('Phone & Internet'),
    ('Website, Social Media, Advertising & Printing'),
    ('Insurance'),
    ('Registrations & Player Cards'),
    ('Transfers'),
    ('Other Operating Expenses');

-- Revenue (rows: 6)
INSERT INTO Revenue (Revenue_ID, Season, Date_Period, Revenue_Source, Description, Amount_EUR) VALUES
    ('R001', 'Season_1', 'Aug-May', 'Village Funding', 'Village funding for the season', 20000),
    ('R002', 'Season_1', 'Aug-May', 'Fundraising Dinners', 'Fundraising dinner 1, net income including raffle', 10000),
    ('R003', 'Season_1', 'Aug-May', 'Fundraising Dinners', 'Fundraising dinner 2, net income including raffle', 10000),
    ('R004', 'Season_1', 'Aug-May', 'Sponsorships', 'Business sponsorships for the season', 2000),
    ('R005', 'Season_1', 'Aug-May', 'Ticket Sales', 'Ticket sales at home matches (no tickets are sold)', 0),
    ('R006', 'Season_1', 'Aug-May', 'Other Revenue', 'Other revenue', 0);

-- Expenses (rows: 34)
INSERT INTO Expenses (Expense_ID, Season, Date_Period, Expense_Category, Expense_Type, Description, Quantity, Unit_Cost_EUR) VALUES
    ('E001', 'Season_1', 'Aug-May', 'Coaching Staff', 'Salary', 'Head Coach: monthly salary x months', 10, 900),
    ('E002', 'Season_1', 'Aug-May', 'Coaching Staff', 'Salary', 'Goalkeeper Coach (part-time): monthly salary x months', 10, 400),
    ('E003', 'Season_1', 'Aug-May', 'Coaching Staff', 'Salary', 'Assistant Coach: monthly salary x months', 0, 0),
    ('E004', 'Season_1', 'Aug-May', 'Player Salaries', 'Salary', 'Player 1: monthly salary x months', 10, 400),
    ('E005', 'Season_1', 'Aug-May', 'Player Salaries', 'Salary', 'Player 2: monthly salary x months', 10, 600),
    ('E006', 'Season_1', 'Aug-May', 'Player Salaries', 'Salary', 'Player 3: monthly salary x months', 10, 200),
    ('E007', 'Season_1', 'Aug-May', 'Electricity', 'Utilities', 'Stadium electricity: monthly cost x months', 10, 250),
    ('E008', 'Season_1', 'Aug-May', 'Water', 'Utilities', 'Stadium water: monthly cost x months', 10, 100),
    ('E009', 'Season_1', 'Aug-May', 'Other Stadium Costs', 'Stadium Rent', 'Stadium rent: monthly cost x months', 10, 0),
    ('E010', 'Season_1', 'Aug-May', 'Other Stadium Costs', 'Cleaning', 'Stadium cleaning (voluntary): monthly cost x months', 10, 0),
    ('E011', 'Season_1', 'Aug-May', 'Other Stadium Costs', 'Field Maintenance', 'Field maintenance (team member): monthly cost x months', 10, 0),
    ('E012', 'Season_1', 'Aug-May', 'Other Stadium Costs', 'Other Stadium Costs', 'Other stadium costs: monthly cost x months', 10, 0),
    ('E013', 'Season_1', 'Aug-May', 'Referees', 'Match Fee', 'Referee fees at home matches: referee appearances x fee', 21, 40),
    ('E014', 'Season_1', 'Aug-May', 'Match Doctor', 'Match Fee', 'Match doctor at home matches: matches x fee', 7, 20),
    ('E015', 'Season_1', 'Aug-May', 'Equipment & Medical Supplies', 'Playing Equipment', 'Balls (Batch 1): quantity x unit cost', 10, 20),
    ('E016', 'Season_1', 'Aug-May', 'Equipment & Medical Supplies', 'Playing Equipment', 'Balls (Batch 2): quantity x unit cost', 15, 15),
    ('E017', 'Season_1', 'Aug-May', 'Equipment & Medical Supplies', 'Playing Equipment', 'Jerseys: quantity x unit cost', 22, 30),
    ('E018', 'Season_1', 'Aug-May', 'Equipment & Medical Supplies', 'Playing Equipment', 'Shorts: quantity x unit cost', 22, 20),
    ('E019', 'Season_1', 'Aug-May', 'Equipment & Medical Supplies', 'Playing Equipment', 'Socks: quantity x unit cost', 50, 5),
    ('E020', 'Season_1', 'Aug-May', 'Equipment & Medical Supplies', 'Playing Equipment', 'Tracksuits: quantity x unit cost', 22, 50),
    ('E021', 'Season_1', 'Aug-May', 'Equipment & Medical Supplies', 'Playing Equipment', 'Goal Nets: quantity x unit cost', 6, 50),
    ('E022', 'Season_1', 'Aug-May', 'Equipment & Medical Supplies', 'Playing Equipment', 'Cones (provided free by village businesses): quantity x unit cost', 0, 0),
    ('E023', 'Season_1', 'Aug-May', 'Equipment & Medical Supplies', 'Medical Supplies', 'Medical Supplies (monthly): quantity x unit cost', 10, 100),
    ('E024', 'Season_1', 'Aug-May', 'Travel', 'Fuel', 'Away match fuel: litres x price per litre', 339, 2),
    ('E025', 'Season_1', 'Aug-May', 'Travel', 'Tolls', 'Tolls', 0, 0),
    ('E026', 'Season_1', 'Aug-May', 'Travel', 'Other Vehicle Costs', 'Other vehicle costs', 0, 0),
    ('E027', 'Season_1', 'Aug-May', 'Accountant', 'Professional Fees', 'Accountant: monthly fee x months', 10, 100),
    ('E028', 'Season_1', 'Aug-May', 'Lawyer', 'Professional Fees', 'Lawyer: monthly fee x months', 10, 50),
    ('E029', 'Season_1', 'Aug-May', 'Phone & Internet', 'Communications', 'Phone and internet', 0, 0),
    ('E030', 'Season_1', 'Aug-May', 'Website, Social Media, Advertising & Printing', 'Marketing', 'Website, social media, advertising and printing', 0, 0),
    ('E031', 'Season_1', 'Aug-May', 'Insurance', 'Insurance', 'Insurance', 0, 0),
    ('E032', 'Season_1', 'Aug-May', 'Registrations & Player Cards', 'Registrations', 'Registrations and player cards, paid by the players themselves', 0, 0),
    ('E033', 'Season_1', 'Aug-May', 'Transfers', 'Transfer Fees', 'Transfers', 0, 0),
    ('E034', 'Season_1', 'Aug-May', 'Other Operating Expenses', 'Other', 'Other operating expenses', 0, 0);

-- Staff (rows: 3)
INSERT INTO Staff (Staff_ID, Role, Monthly_Salary_EUR, Months, Headcount, Notes) VALUES
    ('S01', 'Head Coach', 900, 10, 1, 'Paid Head Coach'),
    ('S02', 'Goalkeeper Coach', 400, 10, 1, 'Part-time'),
    ('S03', 'Assistant Coach', 0, 0, 0, 'Position not filled, no cost');

-- Players (rows: 3)
INSERT INTO Players (Player_ID, Player, Monthly_Salary_EUR, Months) VALUES
    ('P01', 'Player 1', 400, 10),
    ('P02', 'Player 2', 600, 10),
    ('P03', 'Player 3', 200, 10);

-- Equipment (rows: 9)
INSERT INTO Equipment (Equipment_ID, Equipment, Quantity, Unit_Cost_EUR, Item_Group, Quantity_Unit) VALUES
    ('EQ01', 'Balls (Batch 1)', 10, 20, 'Playing Equipment', 'pieces'),
    ('EQ02', 'Balls (Batch 2)', 15, 15, 'Playing Equipment', 'pieces'),
    ('EQ03', 'Jerseys', 22, 30, 'Playing Equipment', 'pieces'),
    ('EQ04', 'Shorts', 22, 20, 'Playing Equipment', 'pieces'),
    ('EQ05', 'Socks', 50, 5, 'Playing Equipment', 'pairs'),
    ('EQ06', 'Tracksuits', 22, 50, 'Playing Equipment', 'pieces'),
    ('EQ07', 'Goal Nets', 6, 50, 'Playing Equipment', 'pairs'),
    ('EQ08', 'Cones (provided free by village businesses)', 0, 0, 'Playing Equipment', 'pieces'),
    ('EQ09', 'Medical Supplies (monthly)', 10, 100, 'Medical Supplies', 'months');

-- Stadium (rows: 6)
INSERT INTO Stadium (Cost_ID, Category, Monthly_Cost_EUR, Months) VALUES
    ('ST01', 'Electricity', 250, 10),
    ('ST02', 'Water', 100, 10),
    ('ST03', 'Stadium Rent', 0, 10),
    ('ST04', 'Cleaning (volunteers)', 0, 10),
    ('ST05', 'Field Maintenance (team member)', 0, 10),
    ('ST06', 'Other Stadium Costs', 0, 10);

-- In_Kind_Community (rows: 4)
INSERT INTO In_Kind_Community (Support_ID, Support_Type, Description, Provider, Monetary_Cost_to_Club_EUR) VALUES
    ('IK01', 'Equipment', 'Cones provided free of charge', 'Village businesses', 0),
    ('IK02', 'Consumables', 'Drinking water for players provided free of charge', 'Village', 0),
    ('IK03', 'Services', 'Stadium cleaning done on a voluntary basis', 'Volunteers', 0),
    ('IK04', 'Services', 'Field maintenance done by a person of the team', 'Team member', 0);

-- Travel (rows: 7)
INSERT INTO Travel (Match_ID, Destination_ID, One_Way_Distance_KM, Number_of_Cars, Fuel_Consumption_L_per_100KM, Fuel_Price_EUR_per_L) VALUES
    ('A01', 'D01', 10, 4, 7.5, 2),
    ('A02', 'D02', 50, 4, 7.5, 2),
    ('A03', 'D03', 80, 4, 7.5, 2),
    ('A04', 'D04', 90, 4, 7.5, 2),
    ('A05', 'D05', 95, 4, 7.5, 2),
    ('A06', 'D06', 110, 4, 7.5, 2),
    ('A07', 'D07', 130, 4, 7.5, 2);

-- Data_Dictionary (rows: 90)
INSERT INTO Data_Dictionary (Table_Name, Column_Name, Data_Type, Key_Type, Is_Generated, Description) VALUES
    ('Data_Dictionary', 'Table_Name', 'TEXT', 'PK', 0, 'Documented table (part of primary key).'),
    ('Data_Dictionary', 'Column_Name', 'TEXT', 'PK', 0, 'Documented column (part of primary key).'),
    ('Data_Dictionary', 'Data_Type', 'TEXT', 'none', 0, 'Declared SQLite type.'),
    ('Data_Dictionary', 'Key_Type', 'TEXT', 'none', 0, 'PK, FK, PK+FK or none.'),
    ('Data_Dictionary', 'Is_Generated', 'INTEGER', 'none', 0, '1 if the column is a generated column, otherwise 0.'),
    ('Data_Dictionary', 'Description', 'TEXT', 'none', 0, 'Meaning of the column.'),
    ('Dim_Expense_Category', 'Expense_Category', 'TEXT', 'PK', 0, 'Expense category name (primary key).'),
    ('Dim_Revenue_Source', 'Revenue_Source', 'TEXT', 'PK', 0, 'Revenue source name (primary key).'),
    ('Equipment', 'Equipment_ID', 'TEXT', 'PK', 0, 'Unique item identifier (primary key).'),
    ('Equipment', 'Equipment', 'TEXT', 'none', 0, 'Item name (unique).'),
    ('Equipment', 'Quantity', 'INTEGER', 'none', 0, 'Quantity bought by the club (0 means nothing was bought).'),
    ('Equipment', 'Unit_Cost_EUR', 'NUMERIC', 'none', 0, 'Cost per unit in EUR.'),
    ('Equipment', 'Total_Cost_EUR', 'NUMERIC', 'none', 1, 'Generated: ROUND(Quantity * Unit_Cost_EUR, 2).'),
    ('Equipment', 'Item_Group', 'TEXT', 'none', 0, 'Playing Equipment or Medical Supplies.'),
    ('Equipment', 'Quantity_Unit', 'TEXT', 'none', 0, 'Unit of Quantity (pieces, pairs or months).'),
    ('Expenses', 'Expense_ID', 'TEXT', 'PK', 0, 'Unique expense line identifier (primary key).'),
    ('Expenses', 'Season', 'TEXT', 'FK', 0, 'Season label; references Team_Info.Season.'),
    ('Expenses', 'Date_Period', 'TEXT', 'none', 0, 'Period label of the record (Aug-May means the whole season).'),
    ('Expenses', 'Expense_Category', 'TEXT', 'FK', 0, 'Expense category; references Dim_Expense_Category.'),
    ('Expenses', 'Expense_Type', 'TEXT', 'none', 0, 'Sub-type of the expense.'),
    ('Expenses', 'Description', 'TEXT', 'none', 0, 'Line description that also states what Quantity and Unit_Cost_EUR mean.'),
    ('Expenses', 'Quantity', 'NUMERIC', 'none', 0, 'Quantity of the line (months, pieces, litres or appearances, as stated in Description).'),
    ('Expenses', 'Unit_Cost_EUR', 'NUMERIC', 'none', 0, 'Cost per unit in EUR.'),
    ('Expenses', 'Total_Cost_EUR', 'NUMERIC', 'none', 1, 'Generated: ROUND(Quantity * Unit_Cost_EUR, 2).'),
    ('In_Kind_Community', 'Support_ID', 'TEXT', 'PK', 0, 'Unique support identifier (primary key).'),
    ('In_Kind_Community', 'Support_Type', 'TEXT', 'none', 0, 'Type of support.'),
    ('In_Kind_Community', 'Description', 'TEXT', 'none', 0, 'Description of the support.'),
    ('In_Kind_Community', 'Provider', 'TEXT', 'none', 0, 'Who provides the support.'),
    ('In_Kind_Community', 'Monetary_Cost_to_Club_EUR', 'NUMERIC', 'none', 0, 'Cost to the club in EUR. Always 0 for in-kind support.'),
    ('Match_Costs', 'Match_ID', 'TEXT', 'PK', 0, 'Match identifier (primary key). H01-H07 are home matches, A01-A07 are away matches.'),
    ('Match_Costs', 'Home_Away', 'TEXT', 'none', 0, 'Home or Away.'),
    ('Match_Costs', 'Referees_Count', 'INTEGER', 'none', 0, 'Number of referees paid by the club for the match.'),
    ('Match_Costs', 'Referee_Cost_EUR', 'NUMERIC', 'none', 0, 'Referee cost paid by the club in EUR.'),
    ('Match_Costs', 'Doctor_Cost_EUR', 'NUMERIC', 'none', 0, 'Match doctor cost paid by the club in EUR.'),
    ('Match_Costs', 'Other_Match_Cost_EUR', 'NUMERIC', 'none', 0, 'Other match costs paid by the club in EUR.'),
    ('Match_Costs', 'Total_Match_Cost_EUR', 'NUMERIC', 'none', 1, 'Generated: Referee_Cost_EUR + Doctor_Cost_EUR + Other_Match_Cost_EUR.'),
    ('Parameters', 'Parameter_ID', 'TEXT', 'PK', 0, 'Unique parameter identifier (primary key).'),
    ('Parameters', 'Parameter', 'TEXT', 'none', 0, 'Parameter name (unique).'),
    ('Parameters', 'Value', 'NUMERIC', 'none', 0, 'Numeric value of the parameter.'),
    ('Parameters', 'Unit', 'TEXT', 'none', 0, 'Unit of the value.'),
    ('Players', 'Player_ID', 'TEXT', 'PK', 0, 'Unique paid player identifier (primary key).'),
    ('Players', 'Player', 'TEXT', 'none', 0, 'Player label (unique).'),
    ('Players', 'Monthly_Salary_EUR', 'NUMERIC', 'none', 0, 'Monthly salary in EUR.'),
    ('Players', 'Months', 'INTEGER', 'none', 0, 'Number of paid months.'),
    ('Players', 'Total_Season_Cost_EUR', 'NUMERIC', 'none', 1, 'Generated: ROUND(Monthly_Salary_EUR * Months, 2).'),
    ('Revenue', 'Revenue_ID', 'TEXT', 'PK', 0, 'Unique revenue line identifier (primary key).'),
    ('Revenue', 'Season', 'TEXT', 'FK', 0, 'Season label; references Team_Info.Season.'),
    ('Revenue', 'Date_Period', 'TEXT', 'none', 0, 'Period label of the record (Aug-May means the whole season).'),
    ('Revenue', 'Revenue_Source', 'TEXT', 'FK', 0, 'Revenue source; references Dim_Revenue_Source.'),
    ('Revenue', 'Description', 'TEXT', 'none', 0, 'Revenue line description.'),
    ('Revenue', 'Amount_EUR', 'NUMERIC', 'none', 0, 'Revenue amount in EUR. A value of 0 is a real zero revenue.'),
    ('Stadium', 'Cost_ID', 'TEXT', 'PK', 0, 'Unique cost identifier (primary key).'),
    ('Stadium', 'Category', 'TEXT', 'none', 0, 'Stadium cost category (unique).'),
    ('Stadium', 'Monthly_Cost_EUR', 'NUMERIC', 'none', 0, 'Monthly cost in EUR.'),
    ('Stadium', 'Months', 'INTEGER', 'none', 0, 'Number of months.'),
    ('Stadium', 'Total_Cost_EUR', 'NUMERIC', 'none', 1, 'Generated: ROUND(Monthly_Cost_EUR * Months, 2).'),
    ('Staff', 'Staff_ID', 'TEXT', 'PK', 0, 'Unique staff position identifier (primary key).'),
    ('Staff', 'Role', 'TEXT', 'none', 0, 'Coaching staff role (unique).'),
    ('Staff', 'Monthly_Salary_EUR', 'NUMERIC', 'none', 0, 'Monthly salary in EUR.'),
    ('Staff', 'Months', 'INTEGER', 'none', 0, 'Number of paid months.'),
    ('Staff', 'Total_Season_Cost_EUR', 'NUMERIC', 'none', 1, 'Generated: ROUND(Monthly_Salary_EUR * Months, 2).'),
    ('Staff', 'Headcount', 'INTEGER', 'none', 0, 'Number of people in the position (0 means the position is not filled).'),
    ('Staff', 'Notes', 'TEXT', 'none', 0, 'Short note about the position.'),
    ('Team_Info', 'Season', 'TEXT', 'PK', 0, 'Season label (primary key).'),
    ('Team_Info', 'League_Category', 'TEXT', 'none', 0, 'League division name as provided by the club.'),
    ('Team_Info', 'Season_Start_Month', 'TEXT', 'none', 0, 'First month of the season.'),
    ('Team_Info', 'Season_End_Month', 'TEXT', 'none', 0, 'Last month of the season.'),
    ('Team_Info', 'Season_Months', 'INTEGER', 'none', 0, 'Season length in months.'),
    ('Team_Info', 'Teams_in_League', 'INTEGER', 'none', 0, 'Number of teams in the league.'),
    ('Team_Info', 'Opponents', 'INTEGER', 'none', 0, 'Number of opponent teams.'),
    ('Team_Info', 'League_Matches', 'INTEGER', 'none', 0, 'Total league matches in the season.'),
    ('Team_Info', 'Home_Matches', 'INTEGER', 'none', 0, 'Number of home league matches.'),
    ('Team_Info', 'Away_Matches', 'INTEGER', 'none', 0, 'Number of away league matches.'),
    ('Team_Info', 'Cup_Matches', 'INTEGER', 'none', 0, 'Number of cup matches.'),
    ('Team_Info', 'Trainings_per_Week', 'INTEGER', 'none', 0, 'Training sessions per week.'),
    ('Team_Info', 'Training_Hours_per_Session', 'NUMERIC', 'none', 0, 'Hours per training session.'),
    ('Team_Info', 'Training_Hours_per_Week', 'NUMERIC', 'none', 1, 'Generated: Trainings_per_Week * Training_Hours_per_Session.'),
    ('Team_Info', 'Home_Attendance_Min', 'INTEGER', 'none', 0, 'Approximate lower bound of spectators per home match.'),
    ('Team_Info', 'Home_Attendance_Max', 'INTEGER', 'none', 0, 'Approximate upper bound of spectators per home match.'),
    ('Team_Info', 'Stadium_Provider', 'TEXT', 'none', 0, 'Who provides the stadium to the club.'),
    ('Team_Info', 'Floodlights_Available', 'TEXT', 'none', 0, 'Whether floodlights exist (Yes or No).'),
    ('Travel', 'Match_ID', 'TEXT', 'PK+FK', 0, 'Away match (primary key); references Match_Costs.Match_ID.'),
    ('Travel', 'Destination_ID', 'TEXT', 'none', 0, 'Away destination identifier (unique).'),
    ('Travel', 'One_Way_Distance_KM', 'NUMERIC', 'none', 0, 'One-way distance in km.'),
    ('Travel', 'Round_Trip_Distance_KM', 'NUMERIC', 'none', 1, 'Generated: One_Way_Distance_KM * 2.'),
    ('Travel', 'Number_of_Cars', 'INTEGER', 'none', 0, 'Cars used for the away match.'),
    ('Travel', 'Vehicle_KM', 'NUMERIC', 'none', 1, 'Generated: Round_Trip_Distance_KM * Number_of_Cars.'),
    ('Travel', 'Fuel_Consumption_L_per_100KM', 'NUMERIC', 'none', 0, 'Fuel consumption in litres per 100 km.'),
    ('Travel', 'Fuel_Price_EUR_per_L', 'NUMERIC', 'none', 0, 'Fuel price in EUR per litre.'),
    ('Travel', 'Fuel_Cost_EUR', 'NUMERIC', 'none', 1, 'Generated: ROUND(Vehicle_KM * Fuel_Consumption_L_per_100KM / 100 * Fuel_Price_EUR_per_L, 2).');

COMMIT;
