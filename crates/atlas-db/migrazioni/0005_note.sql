-- Post-it della Home: righe di promemoria condivise fra le postazioni, da barrare quando sono
-- fatte. Solo di ATLAS (non vanno in Arca).

CREATE TABLE note (
    id             INTEGER PRIMARY KEY,
    testo          TEXT NOT NULL CHECK (length(testo) BETWEEN 1 AND 500),
    fatta          INTEGER NOT NULL DEFAULT 0 CHECK (fatta IN (0, 1)),
    autore         TEXT NOT NULL,
    creata_il      TEXT NOT NULL,
    aggiornata_il  TEXT NOT NULL
) STRICT;
