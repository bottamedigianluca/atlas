-- Schema iniziale: anagrafiche importate da Arca, DDT di vendita, outbox di replica.
--
-- Convenzioni
-- - Tabelle STRICT: SQLite rifiuta i valori del tipo sbagliato invece di convertirli.
-- - Codici `COLLATE NOCASE`: Arca usa Latin1_General_CI_AS e confronta i codici senza
--   distinguere maiuscole e minuscole (17 articoli hanno UM `kg` contro `KG` dell'anagrafica).
--   Codici e identificativi sono registrati senza spazi finali (Arca riempie i `char` e anche
--   `AR.Cd_AR`); gli altri testi come in Arca, perché alcuni (IBAN, descrizioni) finiscono
--   tali e quali nei documenti.
-- - Importi, quantità e prezzi in TEXT decimale esatto (`rust_decimal`), mai REAL.
-- - Date `AAAA-MM-GG`, istanti `AAAA-MM-GG HH:MM:SS` in ora locale, come in Arca.
-- - Booleani INTEGER 0/1.

CREATE TABLE aliquote (
    codice      TEXT PRIMARY KEY COLLATE NOCASE,
    descrizione TEXT NOT NULL,
    percentuale TEXT NOT NULL,
    natura      TEXT
) STRICT, WITHOUT ROWID;

CREATE TABLE pagamenti (
    codice      TEXT PRIMARY KEY COLLATE NOCASE,
    descrizione TEXT NOT NULL,
    conto_banca TEXT
) STRICT, WITHOUT ROWID;

CREATE TABLE unita_misura (
    codice      TEXT PRIMARY KEY COLLATE NOCASE,
    descrizione TEXT NOT NULL
) STRICT, WITHOUT ROWID;

CREATE TABLE magazzini (
    codice      TEXT PRIMARY KEY COLLATE NOCASE,
    descrizione TEXT NOT NULL
) STRICT, WITHOUT ROWID;

CREATE TABLE agenti (
    codice      TEXT PRIMARY KEY COLLATE NOCASE,
    descrizione TEXT NOT NULL
) STRICT, WITHOUT ROWID;

-- `tipo` come `LS.TipoLS`: 1 listino di prezzi, 0 listino calcolato da Arca (ultima vendita,
-- ultimo acquisto).
CREATE TABLE listini (
    codice      TEXT PRIMARY KEY COLLATE NOCASE,
    descrizione TEXT NOT NULL,
    ivato       INTEGER NOT NULL CHECK (ivato IN (0, 1)),
    tipo        INTEGER NOT NULL
) STRICT, WITHOUT ROWID;

-- `id` è `LSRevisione.Id_LSRevisione` di Arca.
CREATE TABLE listini_revisioni (
    id            INTEGER PRIMARY KEY,
    listino       TEXT NOT NULL COLLATE NOCASE REFERENCES listini (codice),
    descrizione   TEXT NOT NULL,
    valido_dal    TEXT,
    pubblicata_il TEXT
) STRICT;

CREATE TABLE articoli (
    codice            TEXT PRIMARY KEY COLLATE NOCASE,
    descrizione       TEXT NOT NULL,
    descrizione_breve TEXT,
    unita_misura      TEXT NOT NULL COLLATE NOCASE REFERENCES unita_misura (codice),
    -- Senza aliquota o conto valgono i predefiniti delle righe (`predefiniti_righe`).
    aliquota_vendita  TEXT COLLATE NOCASE REFERENCES aliquote (codice),
    conto_ricavo      TEXT,
    obsoleto          INTEGER NOT NULL CHECK (obsoleto IN (0, 1))
) STRICT, WITHOUT ROWID;

-- `fattore` converte verso l'unità principale (`ARARMisura.UMFatt`).
CREATE TABLE articoli_unita (
    articolo     TEXT NOT NULL COLLATE NOCASE REFERENCES articoli (codice),
    unita_misura TEXT NOT NULL COLLATE NOCASE REFERENCES unita_misura (codice),
    fattore      TEXT NOT NULL,
    predefinita  INTEGER NOT NULL CHECK (predefinita IN (0, 1)),
    ordine       INTEGER NOT NULL,
    PRIMARY KEY (articolo, unita_misura)
) STRICT, WITHOUT ROWID;

-- `id` è `LSArticolo.Id_LSArticolo`, registrato nelle righe dei documenti (`DORig.Id_LSArticolo`).
CREATE TABLE listini_prezzi (
    id        INTEGER PRIMARY KEY,
    revisione INTEGER NOT NULL REFERENCES listini_revisioni (id),
    articolo  TEXT NOT NULL COLLATE NOCASE REFERENCES articoli (codice),
    prezzo    TEXT NOT NULL,
    sconto    TEXT,
    UNIQUE (revisione, articolo)
) STRICT;
CREATE INDEX listini_prezzi_articolo ON listini_prezzi (articolo);

CREATE TABLE clienti_fornitori (
    codice               TEXT PRIMARY KEY COLLATE NOCASE,
    ragione_sociale      TEXT NOT NULL,
    indirizzo            TEXT,
    cap                  TEXT,
    localita             TEXT,
    provincia            TEXT,
    nazione              TEXT,
    partita_iva          TEXT,
    codice_fiscale       TEXT,
    -- Codice destinatario SdI (`CF.CodiceFPR`) e codice ufficio della PA (`CF.CodiceIPA`).
    codice_destinatario  TEXT,
    codice_ipa           TEXT,
    cliente              INTEGER NOT NULL CHECK (cliente IN (0, 1)),
    fornitore            INTEGER NOT NULL CHECK (fornitore IN (0, 1)),
    pagamento            TEXT COLLATE NOCASE REFERENCES pagamenti (codice),
    listino              TEXT COLLATE NOCASE REFERENCES listini (codice),
    iban                 TEXT,
    bic                  TEXT,
    conto_banca          TEXT,
    conto_merce          TEXT,
    agente               TEXT COLLATE NOCASE REFERENCES agenti (codice),
    scissione_pagamenti  INTEGER NOT NULL CHECK (scissione_pagamenti IN (0, 1)),
    ente_pubblico        INTEGER NOT NULL CHECK (ente_pubblico IN (0, 1)),
    aliquota             TEXT COLLATE NOCASE REFERENCES aliquote (codice),
    cliente_fatturazione TEXT COLLATE NOCASE REFERENCES clienti_fornitori (codice) DEFERRABLE INITIALLY DEFERRED,
    fido                 TEXT,
    note                 TEXT,
    obsoleto             INTEGER NOT NULL CHECK (obsoleto IN (0, 1))
) STRICT, WITHOUT ROWID;

CREATE TABLE destinazioni (
    cliente     TEXT NOT NULL COLLATE NOCASE REFERENCES clienti_fornitori (codice),
    codice      TEXT NOT NULL COLLATE NOCASE,
    descrizione TEXT NOT NULL,
    indirizzo   TEXT,
    cap         TEXT,
    localita    TEXT,
    provincia   TEXT,
    nazione     TEXT,
    agente      TEXT COLLATE NOCASE REFERENCES agenti (codice),
    aliquota    TEXT COLLATE NOCASE REFERENCES aliquote (codice),
    predefinita INTEGER NOT NULL CHECK (predefinita IN (0, 1)),
    obsoleto    INTEGER NOT NULL CHECK (obsoleto IN (0, 1)),
    PRIMARY KEY (cliente, codice)
) STRICT, WITHOUT ROWID;

-- Conto e aliquota delle righe quando l'articolo non li indica (`Impostazione`
-- `DEFAULT_RIGHE_DOC`, colonne di vendita). Sui 101.094 righe BO 2025-2026: aliquota
-- dell'articolo o questa in 101.090 (le 4 restanti modificate a mano o prima di un cambio di
-- aliquota dell'articolo), conto sempre questo.
CREATE TABLE predefiniti_righe (
    id           INTEGER PRIMARY KEY CHECK (id = 1),
    conto_ricavo TEXT NOT NULL,
    aliquota     TEXT NOT NULL COLLATE NOCASE REFERENCES aliquote (codice)
) STRICT;

-- DDT di vendita. Le colonne di ingresso sono quelle di `atlas_core::ddt::Ddt`; i totali sono
-- calcolati da `atlas-core` al salvataggio e servono a elenchi e ricerche.
-- Nessuna cancellazione logica: un DDT cancellato esce dalla tabella e il suo numero torna libero.
CREATE TABLE ddt (
    id                  INTEGER PRIMARY KEY,
    esercizio           INTEGER NOT NULL,
    numero              INTEGER NOT NULL CHECK (numero BETWEEN 1 AND 999999),
    data                TEXT NOT NULL,
    cliente             TEXT NOT NULL COLLATE NOCASE REFERENCES clienti_fornitori (codice),
    destinazione        TEXT COLLATE NOCASE,
    sede                TEXT,
    pagamento           TEXT COLLATE NOCASE REFERENCES pagamenti (codice),
    listino_cliente     TEXT COLLATE NOCASE REFERENCES listini (codice),
    iban                TEXT,
    bic                 TEXT,
    conto_banca         TEXT,
    agente              TEXT COLLATE NOCASE REFERENCES agenti (codice),
    inizio_trasporto    TEXT,
    scissione_pagamenti INTEGER NOT NULL CHECK (scissione_pagamenti IN (0, 1)),
    operatore           TEXT NOT NULL,
    registrato_il       TEXT NOT NULL,
    totale_imponibile   TEXT NOT NULL,
    totale_imposta      TEXT NOT NULL,
    totale_documento    TEXT NOT NULL,
    UNIQUE (esercizio, numero),
    FOREIGN KEY (cliente, destinazione) REFERENCES destinazioni (cliente, codice)
) STRICT;
CREATE INDEX ddt_data ON ddt (data);
CREATE INDEX ddt_cliente_data ON ddt (cliente, data);

-- `quantita` e `totale` sono calcolati al salvataggio (`RigaDdt::quantita`, `RigaMerce::totale`).
CREATE TABLE ddt_righe (
    ddt                 INTEGER NOT NULL REFERENCES ddt (id) ON DELETE CASCADE,
    riga                INTEGER NOT NULL,
    articolo            TEXT NOT NULL COLLATE NOCASE REFERENCES articoli (codice),
    descrizione         TEXT NOT NULL,
    unita_misura        TEXT NOT NULL COLLATE NOCASE REFERENCES unita_misura (codice),
    fattore_um1         TEXT NOT NULL,
    conto_ricavo        TEXT NOT NULL,
    aliquota            TEXT NOT NULL COLLATE NOCASE REFERENCES aliquote (codice),
    -- Senza chiave esterna: la riga di listino può cambiare dopo l'emissione.
    id_listino_articolo INTEGER,
    colli               TEXT NOT NULL,
    lordo               TEXT NOT NULL,
    tara_per_collo      TEXT NOT NULL,
    quantita_forzata    TEXT,
    quantita            TEXT NOT NULL,
    prezzo_unitario     TEXT NOT NULL,
    sconto_riga         TEXT NOT NULL,
    sconto_addizionale  TEXT NOT NULL,
    magazzino           TEXT COLLATE NOCASE REFERENCES magazzini (codice),
    totale              TEXT NOT NULL,
    PRIMARY KEY (ddt, riga)
) STRICT, WITHOUT ROWID;
CREATE INDEX ddt_righe_articolo ON ddt_righe (articolo);

-- Transactional outbox: ogni scrittura di un documento accoda, nella stessa transazione,
-- l'evento da replicare in Arca. `id` dà l'ordine di replica. `payload` è il documento
-- completo (JSON di `Ddt`) al momento dell'evento, così la replica non dipende da modifiche
-- successive. Nessuna chiave esterna verso il documento: l'evento di una cancellazione
-- sopravvive al documento.
CREATE TABLE outbox_eventi (
    id                    INTEGER PRIMARY KEY,
    documento_tipo        TEXT NOT NULL CHECK (documento_tipo IN ('BO')),
    documento_id          INTEGER NOT NULL,
    operazione            TEXT NOT NULL CHECK (operazione IN ('crea', 'modifica', 'cancella')),
    payload               TEXT NOT NULL CHECK (json_valid(payload)),
    creato_il             TEXT NOT NULL,
    tentativi             INTEGER NOT NULL DEFAULT 0,
    prossimo_tentativo_il TEXT,
    ultimo_errore         TEXT,
    replicato_il          TEXT,
    -- `DOTes.Id_DoTes` assegnato da Arca alla replica.
    arca_id_testata       INTEGER,
    CHECK ((replicato_il IS NULL) = (arca_id_testata IS NULL))
) STRICT;
CREATE INDEX outbox_da_replicare ON outbox_eventi (id) WHERE replicato_il IS NULL;
CREATE INDEX outbox_documento ON outbox_eventi (documento_tipo, documento_id);
