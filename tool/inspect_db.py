import sqlite3, sys

db = r'C:\temp\flutter_projects\speleo_loc\test_data\db\binaries\speleo_loc_export_20260423.sqlite'
con = sqlite3.connect(db)
cur = con.cursor()

# Schema
cur.execute("SELECT name, sql FROM sqlite_master WHERE type='table' ORDER BY name")
tables = cur.fetchall()
print("=== SCHEMA ===")
for name, sql in tables:
    print(f"\n-- {name}")
    print(sql)

print("\n=== ROW COUNTS ===")
for name, _ in tables:
    cur.execute(f'SELECT COUNT(*) FROM "{name}"')
    print(f"  {name}: {cur.fetchone()[0]}")

print("\n=== SAMPLE DATA (up to 5 rows each) ===")
for name, _ in tables:
    cur.execute(f'SELECT * FROM "{name}" LIMIT 5')
    rows = cur.fetchall()
    cols = [d[0] for d in cur.description]
    if rows:
        print(f"\n-- {name} columns: {cols}")
        for r in rows:
            print(f"  {r}")

con.close()
