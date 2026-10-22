-- Anagrafiche complete per le maschere Clienti e Articoli: i campi di Arca che la scheda mostra e
-- che la scrittura in Arca dovrà riportare, in un oggetto JSON con i nomi delle colonne di Arca
-- (`CF.Cd_CFZona`, `AR.Cd_Aliquota_A`…). I campi che ATLAS usa nei calcoli restano colonne vere.

ALTER TABLE clienti_fornitori ADD COLUMN extra TEXT NOT NULL DEFAULT '{}' CHECK (json_valid(extra));
ALTER TABLE articoli ADD COLUMN extra TEXT NOT NULL DEFAULT '{}' CHECK (json_valid(extra));
