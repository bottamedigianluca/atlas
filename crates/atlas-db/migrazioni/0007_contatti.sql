-- Contatti dei clienti (`CFContatto` di Arca: telefono, email, PEC… del cliente e delle sue
-- destinazioni) e gli altri campi delle destinazioni (`CFDest`), con i nomi delle colonne di Arca
-- in un oggetto JSON: l'importazione li legge tutti, senza un elenco scritto a mano.

ALTER TABLE destinazioni ADD COLUMN extra TEXT NOT NULL DEFAULT '{}' CHECK (json_valid(extra));

CREATE TABLE contatti (
    -- `CFContatto.Id_CFContatto`; i contatti nati in ATLAS e non ancora in Arca sono negativi.
    id          INTEGER PRIMARY KEY,
    cliente     TEXT NOT NULL COLLATE NOCASE REFERENCES clienti_fornitori (codice),
    destinazione TEXT COLLATE NOCASE,
    dati        TEXT NOT NULL CHECK (json_valid(dati))
) STRICT;

CREATE INDEX contatti_cliente ON contatti (cliente);

-- Clienti nuovi creati in ATLAS: la replica li scrive in `CF` e `CFContatto` (tipo 'CF'
-- nell'outbox, `documento_id` = il numero del codice cliente, `arca_id_testata` = `CF.Id_CF`).
-- SQLite non cambia un CHECK: la tabella si ricrea con gli stessi dati.
CREATE TABLE outbox_eventi_nuova (
    id                    INTEGER PRIMARY KEY,
    documento_tipo        TEXT NOT NULL CHECK (documento_tipo IN ('BO', 'CF')),
    documento_id          INTEGER NOT NULL,
    operazione            TEXT NOT NULL CHECK (operazione IN ('crea', 'modifica', 'cancella')),
    payload               TEXT NOT NULL CHECK (json_valid(payload)),
    creato_il             TEXT NOT NULL,
    tentativi             INTEGER NOT NULL DEFAULT 0,
    prossimo_tentativo_il TEXT,
    ultimo_errore         TEXT,
    replicato_il          TEXT,
    -- `DOTes.Id_DoTes` (o `CF.Id_CF`) assegnato da Arca alla replica.
    arca_id_testata       INTEGER,
    CHECK ((replicato_il IS NULL) = (arca_id_testata IS NULL))
) STRICT;
INSERT INTO outbox_eventi_nuova SELECT * FROM outbox_eventi;
DROP TABLE outbox_eventi;
ALTER TABLE outbox_eventi_nuova RENAME TO outbox_eventi;
CREATE INDEX outbox_da_replicare ON outbox_eventi (id) WHERE replicato_il IS NULL;
CREATE INDEX outbox_documento ON outbox_eventi (documento_tipo, documento_id);
CREATE TRIGGER outbox_replicato AFTER UPDATE OF replicato_il ON outbox_eventi
WHEN NEW.documento_tipo = 'BO' AND OLD.replicato_il IS NULL AND NEW.replicato_il IS NOT NULL
BEGIN
    UPDATE ddt SET arca_id_testata = NEW.arca_id_testata WHERE id = NEW.documento_id;
END;
