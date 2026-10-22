import pymssql

conn = pymssql.connect(server='PCARCA-2023', user='bihortus_reader', password='BiHortus2025!', database='ADB_BOTTAMEDI')
cur = conn.cursor(as_dict=True)

print("=== FTE_WorkFlow ===")
cur.execute("SELECT FTE_status, CicloAttivoPassivo, Note, DaInviare, InviatoHUB, InviatoSDI, Errore, Reinviabile, ModificabilePdf FROM FTE_WorkFlow ORDER BY Riga")
for r in cur.fetchall():
    print(r)

print("\n=== FTE_Mapping ===")
cur.execute("SELECT * FROM FTE_Mapping")
for r in cur.fetchall():
    print(r)

conn.close()
