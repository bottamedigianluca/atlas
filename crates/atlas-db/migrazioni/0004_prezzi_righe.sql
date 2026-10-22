-- Prezzi della maschera F3 (ultimo prezzo al cliente, ultimo a chiunque, massimo del giorno)
-- letti sugli indici, senza scorrere i documenti: data e cliente della testata ripetuti nelle
-- righe. Le scrive `ddt::inserisci_righe` con la riga; il trigger le riallinea se la testata
-- cambia data o cliente.

ALTER TABLE ddt_righe ADD COLUMN data TEXT;
ALTER TABLE ddt_righe ADD COLUMN cliente TEXT COLLATE NOCASE;
UPDATE ddt_righe SET (data, cliente) = (SELECT d.data, d.cliente FROM ddt d WHERE d.id = ddt_righe.ddt);

DROP INDEX ddt_righe_articolo;
CREATE INDEX ddt_righe_articolo_data ON ddt_righe (articolo, data);
CREATE INDEX ddt_righe_articolo_cliente_data ON ddt_righe (articolo, cliente, data);

CREATE TRIGGER ddt_righe_testata AFTER UPDATE OF data, cliente ON ddt
WHEN NEW.data IS NOT OLD.data OR NEW.cliente IS NOT OLD.cliente
BEGIN
    UPDATE ddt_righe SET data = NEW.data, cliente = NEW.cliente WHERE ddt = NEW.id;
END;
