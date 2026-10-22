import sys
import os
import json
import datetime
from decimal import Decimal

sys.path.insert(0, r'C:\Users\Bottamedi\CRM WHATSAPP BOTTAMEDI\backend')
from integrations.arca_evolution import ArcaEvolutionConnector

out_dir = r'C:\Users\Bottamedi\.gemini\antigravity\scratch\progettox8'
os.makedirs(os.path.join(out_dir, 'data'), exist_ok=True)
os.makedirs(os.path.join(out_dir, 'schema'), exist_ok=True)
os.makedirs(os.path.join(out_dir, 'samples'), exist_ok=True)

def json_default(obj):
    if isinstance(obj, (datetime.date, datetime.datetime)):
        return obj.isoformat()
    elif isinstance(obj, bytes):
        return obj.hex()
    elif isinstance(obj, Decimal):
        return float(obj)
    return str(obj)

arca = ArcaEvolutionConnector()

with arca.get_connection() as conn:
    c = conn.cursor(as_dict=True)
    
    # 1. Tipi Documento in DOTes
    print("1. Estrazione Tipi Documento in DOTes...")
    c.execute("""
        SELECT Cd_Do, COUNT(*) as TotDocumenti, MIN(DataDoc) as DaData, MAX(DataDoc) as AData
        FROM DOTes
        GROUP BY Cd_Do
        ORDER BY COUNT(*) DESC
    """)
    doc_types = c.fetchall()
    with open(os.path.join(out_dir, 'data', 'tipi_documento.json'), 'w', encoding='utf-8') as f:
        json.dump(doc_types, f, indent=2, default=json_default)
    print(f"   Trovati {len(doc_types)} tipi documento.")

    # 2. Schema colonne tabelle cardine
    tables = ['DOTes', 'DORig', 'CF', 'AR', 'DOTes_FTEInfo', 'Aliquota', 'PG', 'LS', 'LSRig']
    schema_info = {}
    for tbl in tables:
        print(f"2. Estrazione schema {tbl}...")
        c.execute(f"""
            SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE, COLUMN_DEFAULT
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_NAME = '{tbl}'
            ORDER BY ORDINAL_POSITION
        """)
        schema_info[tbl] = c.fetchall()
    with open(os.path.join(out_dir, 'schema', 'schema_arca_core.json'), 'w', encoding='utf-8') as f:
        json.dump(schema_info, f, indent=2, default=json_default)

    # 3. Triggers su DOTes e DORig
    print("3. Estrazione Triggers su DOTes e DORig...")
    c.execute("""
        SELECT 
            t.name AS TriggerName,
            OBJECT_NAME(t.parent_id) AS TableName,
            OBJECT_DEFINITION(t.object_id) AS TriggerDefinition
        FROM sys.triggers t
        WHERE t.parent_id IN (OBJECT_ID('DOTes'), OBJECT_ID('DORig'))
    """)
    triggers = c.fetchall()
    with open(os.path.join(out_dir, 'schema', 'triggers_arca.json'), 'w', encoding='utf-8') as f:
        json.dump(triggers, f, indent=2, default=json_default)
    print(f"   Trovati {len(triggers)} triggers.")

    # 4. Aliquote IVA
    print("4. Estrazione Aliquote IVA...")
    c.execute("SELECT * FROM Aliquota")
    aliquote = c.fetchall()
    with open(os.path.join(out_dir, 'data', 'aliquote_iva.json'), 'w', encoding='utf-8') as f:
        json.dump(aliquote, f, indent=2, default=json_default)

    # 5. Condizioni di Pagamento (PG)
    print("5. Estrazione Condizioni Pagamento (PG)...")
    c.execute("SELECT * FROM PG")
    pgs = c.fetchall()
    with open(os.path.join(out_dir, 'data', 'condizioni_pagamento.json'), 'w', encoding='utf-8') as f:
        json.dump(pgs, f, indent=2, default=json_default)

    # 6. Esempio Fattura Differita (FT) con DDT collegati
    print("6. Estrazione Esempio Fattura Differita (FT) con DDT collegati...")
    c.execute("""
        SELECT TOP 1 * FROM DOTes WHERE Cd_Do = 'FT' ORDER BY DataDoc DESC, NumeroDoc DESC
    """)
    sample_ft = c.fetchone()
    if sample_ft:
        id_ft = sample_ft.get('Id_DoTes') or sample_ft.get('Id_DOTes')
        c.execute(f"SELECT * FROM DORig WHERE Id_DoTes = {id_ft} ORDER BY Riga")
        sample_lines = c.fetchall()
        sample_doc = {
            'testata': sample_ft,
            'righe': sample_lines
        }
        with open(os.path.join(out_dir, 'samples', 'sample_fattura_ft.json'), 'w', encoding='utf-8') as f:
            json.dump(sample_doc, f, indent=2, default=json_default)

    # 7. Esempio Bolla (BO) recente
    print("7. Estrazione Esempio Bolla (BO)...")
    c.execute("""
        SELECT TOP 1 * FROM DOTes WHERE Cd_Do = 'BO' ORDER BY DataDoc DESC, NumeroDoc DESC
    """)
    sample_bo = c.fetchone()
    if sample_bo:
        id_bo = sample_bo.get('Id_DoTes') or sample_bo.get('Id_DOTes')
        c.execute(f"SELECT * FROM DORig WHERE Id_DoTes = {id_bo} ORDER BY Riga")
        bo_lines = c.fetchall()
        sample_bo_doc = {
            'testata': sample_bo,
            'righe': bo_lines
        }
        with open(os.path.join(out_dir, 'samples', 'sample_bolla_bo.json'), 'w', encoding='utf-8') as f:
            json.dump(sample_bo_doc, f, indent=2, default=json_default)

    # 8. Esempio file XML Fattura Elettronica Emessa (Cessione Attiva)
    print("8. Estrazione tracciato XML Fattura Elettronica Emessa...")
    c.execute("""
        SELECT TOP 1 d.FileName, d.Content 
        FROM DmsDocumentFTEInfo fi
        JOIN DmsDocument d ON d.Id_DmsDocument = fi.Id_DmsDocument
        WHERE fi.Tipo = 'CA' AND d.FileExt = 'xml'
        ORDER BY fi.DataFattura DESC
    """)
    xml_row = c.fetchone()
    if xml_row:
        with open(os.path.join(out_dir, 'samples', xml_row['FileName']), 'wb') as f:
            f.write(bytes(xml_row['Content']))
        print(f"   Salvato XML di esempio: {xml_row['FileName']}")

print("\nEstrazione completata con successo in progettox8!")
