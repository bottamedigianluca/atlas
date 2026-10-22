-- Post-it della Home: note condivise fra le postazioni, solo di ATLAS (non vanno in Arca).
-- La posizione è in frazioni della bacheca (0-1), così resta uguale su schermi diversi.

CREATE TABLE note (
    id             INTEGER PRIMARY KEY,
    testo          TEXT NOT NULL,
    colore         TEXT NOT NULL CHECK (colore IN ('giallo', 'rosa', 'verde', 'azzurro', 'arancio')),
    x              REAL NOT NULL CHECK (x BETWEEN 0 AND 1),
    y              REAL NOT NULL CHECK (y BETWEEN 0 AND 1),
    autore         TEXT NOT NULL,
    creata_il      TEXT NOT NULL,
    aggiornata_il  TEXT NOT NULL
) STRICT;
