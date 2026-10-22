import pymssql

conn = pymssql.connect(server='PCARCA-2023', user='bihortus_reader', password='BiHortus2025!', database='ADB_BOTTAMEDI')
cur = conn.cursor(as_dict=True)

# Find all triggers on DOTes
cur.execute("""
SELECT name, is_disabled, is_instead_of_trigger
FROM sys.triggers
WHERE parent_id = OBJECT_ID('DOTes')
""")
print("=== TRIGGERS ON DOTes ===")
for r in cur.fetchall():
    print(r)

# Find check constraints on DOTes
cur.execute("""
SELECT name, definition
FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID('DOTes')
""")
print("\n=== CHECK CONSTRAINTS ON DOTes ===")
for r in cur.fetchall():
    print(r)

conn.close()
