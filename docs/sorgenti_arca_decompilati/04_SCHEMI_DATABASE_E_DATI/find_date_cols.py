import pymssql

conn = pymssql.connect(server='PCARCA-2023', user='bihortus_reader', password='BiHortus2025!', database='ADB_BOTTAMEDI')
cur = conn.cursor(as_dict=True)

cur.execute("SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='DOTes' AND COLUMN_NAME LIKE '%Data%'")
cols = cur.fetchall()
for c in cols:
    print(f"DOTes col: {c['COLUMN_NAME']} ({c['DATA_TYPE']})")

conn.close()
