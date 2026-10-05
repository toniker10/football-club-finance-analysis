"""Rebuilds football_club_finance.db from 01..03 SQL files and runs all checks (stdlib only)."""
import sqlite3, os, sys
here = os.path.dirname(os.path.abspath(__file__))
db_path = os.path.join(here, "football_club_finance.db")
if os.path.exists(db_path): os.remove(db_path)
conn = sqlite3.connect(db_path, isolation_level=None)
conn.execute("PRAGMA foreign_keys = ON")
for f in ("01_schema.sql", "02_data.sql", "03_views.sql"):
    conn.executescript(open(os.path.join(here, f), encoding="utf-8").read())
    print("loaded", f)
failures = 0
rows = conn.execute("SELECT Check_ID, Check_Description, Calculated_Value, Control_Value, Status FROM vw_control_checks ORDER BY Check_ID").fetchall()
bad = [r for r in rows if r[4] != "OK"]
print(f"control checks: {len(rows)} total, {len(rows) - len(bad)} OK, {len(bad)} not OK")
for r in bad: print("  NOT OK:", r); failures += 1
fk = conn.execute("PRAGMA foreign_key_check").fetchall()
print("foreign_key_check rows:", len(fk)); failures += len(fk)
ic = conn.execute("PRAGMA integrity_check").fetchone()[0]
print("integrity_check:", ic); failures += (ic != "ok")

# constraint tests: every statement below must be rejected
tests = [
 ("unknown season", sqlite3.IntegrityError, "INSERT INTO Revenue (Revenue_ID, Season, Date_Period, Revenue_Source, Description, Amount_EUR) VALUES (?,?,?,?,?,?)", ("T1","Season_X","Aug-May","Village Funding","t",1)),
 ("unknown revenue source", sqlite3.IntegrityError, "INSERT INTO Revenue (Revenue_ID, Season, Date_Period, Revenue_Source, Description, Amount_EUR) VALUES (?,?,?,?,?,?)", ("T2","Season_1","Aug-May","Lottery","t",1)),
 ("negative amount", sqlite3.IntegrityError, "INSERT INTO Revenue (Revenue_ID, Season, Date_Period, Revenue_Source, Description, Amount_EUR) VALUES (?,?,?,?,?,?)", ("T3","Season_1","Aug-May","Village Funding","t",-5)),
 ("text amount", sqlite3.IntegrityError, "INSERT INTO Revenue (Revenue_ID, Season, Date_Period, Revenue_Source, Description, Amount_EUR) VALUES (?,?,?,?,?,?)", ("T4","Season_1","Aug-May","Village Funding","t","abc")),
 ("duplicate primary key", sqlite3.IntegrityError, "INSERT INTO Revenue (Revenue_ID, Season, Date_Period, Revenue_Source, Description, Amount_EUR) VALUES (?,?,?,?,?,?)", ("R001","Season_1","Aug-May","Village Funding","t",1)),
 ("NULL in required column", sqlite3.IntegrityError, "INSERT INTO Revenue (Revenue_ID, Season, Date_Period, Revenue_Source, Description, Amount_EUR) VALUES (?,?,?,?,?,?)", ("T5","Season_1","Aug-May","Village Funding",None,1)),
 ("invalid Home_Away value", sqlite3.IntegrityError, "INSERT INTO Match_Costs (Match_ID, Home_Away, Referees_Count, Referee_Cost_EUR, Doctor_Cost_EUR, Other_Match_Cost_EUR) VALUES (?,?,?,?,?,?)", ("X01","Neutral",0,0,0,0)),
 ("travel row for a home match", sqlite3.IntegrityError, "INSERT INTO Travel (Match_ID, Destination_ID, One_Way_Distance_KM, Number_of_Cars, Fuel_Consumption_L_per_100KM, Fuel_Price_EUR_per_L) VALUES (?,?,?,?,?,?)", ("H01","D99",10,4,7.5,2)),
 ("non-zero in-kind cost", sqlite3.IntegrityError, "INSERT INTO In_Kind_Community (Support_ID, Support_Type, Description, Provider, Monetary_Cost_to_Club_EUR) VALUES (?,?,?,?,?)", ("IK99","t","t","t",5)),
 ("flip an away match with travel to home", sqlite3.IntegrityError, "UPDATE Match_Costs SET Home_Away = ? WHERE Match_ID = ?", ("Home","A01")),
 ("delete a referenced season", sqlite3.IntegrityError, "DELETE FROM Team_Info WHERE Season = ?", ("Season_1",)),
 ("write to a generated column", sqlite3.OperationalError, "INSERT INTO Players (Player_ID, Player, Monthly_Salary_EUR, Months, Total_Season_Cost_EUR) VALUES (?,?,?,?,?)", ("P99","Player 99",1,1,1)),
]
passed = 0
for name, exc, sql, params in tests:
    conn.execute("SAVEPOINT t")
    try:
        conn.execute(sql, params); print(f"  FAIL (accepted): {name}"); failures += 1
    except exc: passed += 1
    except Exception as e: print(f"  FAIL ({type(e).__name__}): {name}: {e}"); failures += 1
    finally:
        conn.execute("ROLLBACK TO t"); conn.execute("RELEASE t")
print(f"constraint tests: {passed}/{len(tests)} correctly rejected")
# mutation tests: a change in ONE source table must be caught by a check (proves the checks work)
muts = [
 ("Staff months changed", "UPDATE Staff SET Months = 9 WHERE Staff_ID = 'S01'"),
 ("Stadium monthly cost changed", "UPDATE Stadium SET Monthly_Cost_EUR = 260 WHERE Cost_ID = 'ST01'"),
 ("Equipment unit cost changed", "UPDATE Equipment SET Unit_Cost_EUR = 25 WHERE Equipment_ID = 'EQ01'"),
 ("Travel distance changed", "UPDATE Travel SET One_Way_Distance_KM = 11 WHERE Match_ID = 'A01'"),
 ("Referee cost changed", "UPDATE Match_Costs SET Referee_Cost_EUR = 130 WHERE Match_ID = 'H01'"),
 ("Cars parameter changed", "UPDATE Parameters SET Value = 5 WHERE Parameter_ID = 'PR04'"),
]
mpassed = 0
for name, sql in muts:
    conn.execute("SAVEPOINT m")
    conn.execute(sql)
    n = conn.execute("SELECT COUNT(*) FROM vw_control_checks WHERE Status <> 'OK'").fetchone()[0]
    if n > 0: mpassed += 1
    else: print(f"  FAIL (not detected): {name}"); failures += 1
    conn.execute("ROLLBACK TO m"); conn.execute("RELEASE m")
print(f"mutation tests: {mpassed}/{len(muts)} detected by control checks")
after = conn.execute("SELECT COUNT(*) FROM vw_control_checks WHERE Status <> 'OK'").fetchone()[0]
print("control checks not OK after tests (must be 0):", after); failures += after
conn.close()
print("RESULT:", "ALL PASSED" if failures == 0 else f"{failures} PROBLEM(S)")
sys.exit(1 if failures else 0)
