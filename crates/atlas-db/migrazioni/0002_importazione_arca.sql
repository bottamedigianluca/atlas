-- Importazione continua dei documenti di Arca.

-- `DOTes.Id_DoTes` del documento in Arca. Lo registra l'importazione per i documenti nati in Arca
-- e la replica (trigger `outbox_replicato`) per quelli nati in ATLAS; senza valore il documento
-- non è ancora in Arca.
ALTER TABLE ddt ADD COLUMN arca_id_testata INTEGER;

UPDATE ddt SET arca_id_testata = (
    SELECT o.arca_id_testata FROM outbox_eventi o
    WHERE o.documento_tipo = 'BO' AND o.documento_id = ddt.id AND o.replicato_il IS NOT NULL
    ORDER BY o.id DESC LIMIT 1
);
CREATE UNIQUE INDEX ddt_arca_id_testata ON ddt (arca_id_testata);

-- Nello stesso statement che segna l'evento replicato: il documento e il suo evento non possono
-- dire cose diverse su dove si trova il documento in Arca.
CREATE TRIGGER outbox_replicato AFTER UPDATE OF replicato_il ON outbox_eventi
WHEN NEW.documento_tipo = 'BO' AND OLD.replicato_il IS NULL AND NEW.replicato_il IS NOT NULL
BEGIN
    UPDATE ddt SET arca_id_testata = NEW.arca_id_testata WHERE id = NEW.documento_id;
END;

-- Punto raggiunto dall'importazione per tipo documento: `DOTes.Ts` (rowversion, come intero)
-- dell'ultimo documento importato. `database` lega il file ATLAS a un database di Arca: gli
-- `Id_DoTes` del clone e della produzione indicano documenti diversi.
CREATE TABLE importazione_arca (
    tipo_documento TEXT PRIMARY KEY,
    database       TEXT NOT NULL,
    ultimo_ts      INTEGER NOT NULL,
    aggiornato_il  TEXT NOT NULL
) STRICT, WITHOUT ROWID;

-- Documenti di Arca che ATLAS non sa ancora rappresentare (righe senza articolo, spese, documenti
-- non esecutivi). Escono da qui quando, modificati in Arca, diventano importabili o vengono
-- cancellati. Un documento già in ATLAS che diventa non rappresentabile resta com'era, ed è qui.
CREATE TABLE importazione_esclusi (
    arca_id_testata INTEGER PRIMARY KEY,
    tipo_documento  TEXT NOT NULL,
    esercizio       INTEGER NOT NULL,
    numero          INTEGER NOT NULL,
    motivo          TEXT NOT NULL,
    rilevato_il     TEXT NOT NULL
) STRICT;
