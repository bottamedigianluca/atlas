-- Numerazione unica con Arca.
--
-- Il numero di un nuovo documento dipende da tutti i documenti del suo sezionale (`CN`), anche
-- quelli che ATLAS non sa rappresentare e di tipi che non gestisce (i `BF` sul sezionale dei
-- BO): l'importazione li legge per sezionale e li tiene qui con numero e data, che con la
-- numerazione alla data delle fatture conta.
--
-- Le righe di prima non hanno né sezionale né data: si buttano e l'importazione riparte
-- dall'inizio, che rilegge tutto (i documenti già importati restano invariati) e le riscrive.
DROP TABLE importazione_esclusi;
CREATE TABLE importazione_esclusi (
    arca_id_testata INTEGER PRIMARY KEY,
    tipo_documento  TEXT NOT NULL,
    -- `DOTes.Cd_CN`.
    sezionale       TEXT NOT NULL,
    esercizio       INTEGER NOT NULL,
    numero          INTEGER NOT NULL,
    data            TEXT NOT NULL,
    motivo          TEXT NOT NULL,
    rilevato_il     TEXT NOT NULL
) STRICT;
CREATE INDEX importazione_esclusi_numero ON importazione_esclusi (sezionale, esercizio, numero);

UPDATE importazione_arca SET ultimo_ts = 0;
